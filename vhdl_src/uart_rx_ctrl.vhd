----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2024 05:07:15 PM
-- Design Name: 
-- Module Name: UART_RX_VER_A - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity UART_RX_CTRL is
    Port ( UART_RX : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           DATA : out  STD_LOGIC_VECTOR (7 downto 0);
           READ_DATA : out  STD_LOGIC := '0'
			  );
end UART_RX_CTRL;

architecture Behavioral of UART_RX_CTRL is

type RX_STATE_TYPE is (READY, DELAY, GET_BIT, READ_BIT, STOP_BIT, CLEAN_UP);

--constant BIT_TMR_MAX : std_logic_vector(13 downto 0) := "10100010110000"; --10416 = (round(100MHz / 9600)) - 1
--constant BIT_TMR_MAX : std_logic_vector(10 downto 0) := "11011001000"; --1736 = (round(100MHz / 57600))
constant BIT_TMR_MAX : std_logic_vector(6 downto 0) := "1100100"; --100 = (round(100MHz / 1000000))
--constant BIT_TMR_MAX : std_logic_vector(6 downto 0) := "1111101"; --125 = (round(100MHz / 800000))
--constant DELAY_COUNTER_MAX : std_logic_vector(12 downto 0) := "1010001011000";  -- 5208 = ((BIT_TMR_MAX/2) )aiming for half of start bit
--constant DELAY_COUNTER_MAX : std_logic_vector(9 downto 0) := "1101100100";  -- 868 = ((BIT_TMR_MAX/2) )aiming for half of start bit
constant DELAY_COUNTER_MAX : std_logic_vector(5 downto 0) := "110010";  -- 50 = ((BIT_TMR_MAX/2) )aiming for half of start bit
--constant DELAY_COUNTER_MAX : std_logic_vector(5 downto 0) := "111111";  -- 63 = ((BIT_TMR_MAX/2) )aiming for half of start bit
constant BIT_INDEX_MAX : natural := 8;

--flag to indicate to move from the delay RXState to the next state
signal DELAY_DONE : std_logic := '0';
signal DELAY_COUNTER : std_logic_vector(5 downto 0) := (others => '0');

--flad to indicate that it is time to read the next bit
signal GET_BIT_DONE : std_logic := '0';
signal GET_BIT_COUNTER : std_logic_vector(6 downto 0) := (others => '0');

signal RX_STATE : RX_STATE_TYPE	:= READY;

signal BIT_INDEX : natural := 0;

signal RX_DATA : std_logic_vector(7 downto 0) := (others => '0');
signal RX_BIT : std_logic := '0';

signal r_RX_Data_R : std_logic := '1';
signal r_RX_Data   : std_logic := '1';
begin


p_SAMPLE : process (CLK)
begin
if rising_edge(CLK) then
  r_RX_Data_R <= UART_RX;
  r_RX_Data   <= r_RX_Data_R;
end if;
end process p_SAMPLE;
--receiving state machine
rx_state_process : process (CLK)
begin
	if(rising_edge(CLK)) then
		case RX_STATE is	--waiting for data state
			when READY =>
				if(r_RX_Data = '0') then --start bit has come
					RX_STATE <= DELAY;
					BIT_INDEX <= 0;
				end if;
				
			when DELAY => 	--delaying for the half of start bit
				if(DELAY_DONE = '1') then
					RX_STATE <= GET_BIT;
				else
					RX_STATE <= Delay;
				end if;

			when GET_BIT =>	--wait for the next bit to be in place
				if(GET_BIT_DONE = '1') then
					RX_STATE <= READ_BIT;
				else
					RX_STATE <= GET_BIT;
					READ_DATA <= '0'; --data is not valid anymore
				end if;

			when READ_BIT =>	--read bit
				if(BIT_INDEX = BIT_INDEX_MAX) then
					RX_STATE <= STOP_BIT; --Changed from READY to STOP bit
					--READ_DATA <= '1';	--data is valid so read!
				else
					BIT_INDEX <= BIT_INDEX +1;
					RX_STATE <= GET_BIT;
				end if;
				
            when STOP_BIT =>
                RX_STATE <= CLEAN_UP;
                READ_DATA <= '1'; --data is valid so read!
                
            when CLEAN_UP =>
                RX_STATE <=READY;
                READ_DATA <='0';
                
            when others =>
                RX_STATE <=READY;
                    
			end case;
	end if;
end process;

--read the bit for BIT_INDEX
READ_BIT_PROCESS : process (CLK)
begin
	if(rising_edge(CLK)) then
		if(RX_STATE = READ_BIT and BIT_INDEX < BIT_INDEX_MAX) then
			RX_DATA(BIT_INDEX) <= r_RX_Data;
		end if;
	end if;
end process;

--timer for the DELAY_DONE signal
DELAY_DONE_PROCESS : process (CLK)
begin
	if(rising_edge(CLK)) then
		if(RX_STATE = DELAY) then
		  if (DELAY_COUNTER = DELAY_COUNTER_MAX) then
		      if(r_RX_Data='0') then
		          DELAY_DONE <='1';
              end if;
		  else
		      DELAY_COUNTER <= DELAY_COUNTER + 1;
				DELAY_DONE <= '0';
		  end if;
		else
			DELAY_DONE <= '0';
			DELAY_COUNTER <= (OTHERS => '0');
		end if;
	end if;
end process;

--timer for the GET_BIT_DONE signal
GET_BIT_DELAY_PROCESS : process(CLK)
begin
	if(rising_edge(CLK)) then
		if(RX_STATE = GET_BIT) then
			if(GET_BIT_COUNTER = BIT_TMR_MAX) then
				GET_BIT_DONE <= '1';
			else
				GET_BIT_COUNTER <= GET_BIT_COUNTER + 1;
				GET_BIT_DONE <= '0';
			end if;
		else
			GET_BIT_DONE <= '0';
			GET_BIT_COUNTER <= (OTHERS => '0');
		end if;
	end if;	
end process;

DATA <= RX_DATA;

end Behavioral;


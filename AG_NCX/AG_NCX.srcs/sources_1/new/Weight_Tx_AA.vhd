----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/13/2025 08:15:34 PM
-- Design Name: 
-- Module Name: Weight_Tx_AA - Behavioral
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
-- UART transmitter
-- transmit W_AA represented by 8-bits through UART communication
-- packets are sent depending on the TRIGER signal

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
ENTITY Weight_Tx_AA IS
	PORT (
		CLK : IN STD_LOGIC;
		TRIGER : IN STD_LOGIC;
		UART_TXD : OUT STD_LOGIC;
		SEND_READY_TX:OUT STD_LOGIC;
		UART_TXD_W : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END Weight_Tx_AA;
ARCHITECTURE Behavioral OF Weight_Tx_AA IS

--	COMPONENT uart_txd_ctrl
--		PORT (
--			clk : IN STD_LOGIC;
--			send_start : IN STD_LOGIC;
--			send_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
--			uart_txd : OUT STD_LOGIC;
--			send_ready : OUT STD_LOGIC
--		);
--	END COMPONENT;
    COMPONENT UART_TX_CTRL
		PORT (
			clk : IN STD_LOGIC;
			send_start : IN STD_LOGIC;
			send_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			uart_txd : OUT STD_LOGIC;
			send_ready : OUT STD_LOGIC
		);
	END COMPONENT;
	TYPE STATE_TYPE IS (STANDBY, SEND_MEASURING0, SEND_MEASURING1, SEND_MEASURING2, SEND_MEASURING3, SEND_MEASURING4, SEND_MEASURING5, END0, END1);
	SIGNAL STATE : STATE_TYPE := STANDBY;
	SIGNAL counter0 : NATURAL := 0;
	SIGNAL counter1 : NATURAL := 0;
	SIGNAL send_start : STD_LOGIC := '0';
	SIGNAL send_ready : STD_LOGIC := '0';
	SIGNAL send_data : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL w_copied : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL send_counter_max : NATURAL := 1;
    SIGNAL data_num_max : NATURAL := 1;

BEGIN
    SEND_READY_TX<=send_ready;
--	uart_txd_ctrl_0 : uart_txd_ctrl
--	PORT MAP(
--		CLK => CLK, 
--		send_start => send_start, 
--		send_data => send_data, 
--		uart_txd => uart_txd, 
--		send_ready => send_ready
--	);
	uart_txd_ctrl_0 : UART_TX_CTRL
	PORT MAP(
		CLK => CLK, 
		send_start => send_start, 
		send_data => send_data, 
		uart_txd => uart_txd, 
		send_ready => send_ready
	);
	processor : PROCESS (CLK)
	BEGIN
		IF (rising_edge(CLK)) THEN
			CASE STATE IS
				WHEN STANDBY => 
					SEND_START <= '0';
					IF (TRIGER = '1') THEN
						STATE <= END0;
						w_copied <= UART_TXD_W;
						counter0 <= 0;
					END IF;

				WHEN END0 => 
					IF (counter0 < send_counter_max) THEN
						send_start <= '0';
						counter0 <= counter0 + 1;
					ELSIF (counter0 = send_counter_max) THEN
						IF (send_ready = '1') THEN
							send_data <= UART_TXD_W; --"00001010";
							send_start <= '1';
							counter0 <= 0;
							STATE <= STANDBY;
						END IF;
					END IF;
				WHEN OTHERS => 
					STATE <= STANDBY;
			END CASE;
		END IF;
	END PROCESS;
END Behavioral;



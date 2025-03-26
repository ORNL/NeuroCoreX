----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/25/2024 02:51:24 PM
-- Design Name: 
-- Module Name: main_tb - Behavioral
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
USE ieee.numeric_std.ALL;
--USE ieee.math_real.ALL;  -- Required for randomization
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main_tb is
--  Port ( );
end main_tb;

architecture Behavioral of main_tb is

component main 
    PORT(
            CLK : IN STD_LOGIC;
--            CLK_LIF : IN STD_LOGIC;
            UART_RXD : IN STD_LOGIC;  -- UART receiver pin
            UART_TXD : OUT STD_LOGIC  -- UART transmitter pin
    );
end component;
CONSTANT N0 : NATURAL := 20;
CONSTANT N1 : NATURAL := 40;
CONSTANT matrix_size : NATURAL := N0*N0;
constant matrix_size_FF : NATURAL := N0*N1;
SIGNAL clk, clk_uart, clk_lif : STD_LOGIC;-- :='0';
constant clock_period : time :=10ns;--10ns;--83.3334ns;--100KHz
constant clock_period_LIF : time :=10us;--200ns;--1000ns;--0.01us;--100KHz
constant clock_period_uart : time :=1.00us;--1.25us
SIGNAL Spike_In : STD_LOGIC := '0';
SIGNAL uart_rxd:  STD_LOGIC := '0';
SIGNAL uart_txd: STD_LOGIC := '0';
SIGNAL flag_NI_ST: STD_LOGIC := '0';
SIGNAL flag_FF: STD_LOGIC := '1';
SIGNAL flag_AA: STD_LOGIC := '0';
SIGNAL BYTE_TIME_DIFF : std_logic_vector(7 downto 0) := "00000111"; -- 0x05
SIGNAL BYTE_WEIGHT_FF : std_logic_vector(7 downto 0) := "00000001"; -- 0x05
SIGNAL BYTE_WEIGHT_AA : std_logic_vector(7 downto 0) := "00000001"; -- 0x05
SIGNAL BYTE_NEURON_ADDR_BYTE_0 : std_logic_vector(7 downto 0) := "00000001"; -- 0x10
SIGNAL BYTE_NEURON_ADDR_BYTE_1 : std_logic_vector(7 downto 0) := "00000000"; -- 0x00
type UART_STATES is (W_FF, W_AA,NIST);
signal UART_STATE : UART_STATES := W_FF;
signal BYTE_SETUP : std_logic_vector(7 downto 0) := "00000000"; -- 00100000 for NI_ST, 0x10 for AA, 0x00 for FF

begin

    MAIN_0: main PORT MAP(
            clk => CLK, 
    --		clk_LIF => CLK_LIF,
            UART_RXD => uart_rxd,
            UART_TXD => uart_txd
                );
                
    clock_process :process
    begin
        clk <='1';
        wait for clock_period/2;
        clk <='0';
        wait for clock_period/2;
    end process;
    
    --clock_process_lif :process
    --begin
    --    clk_lif <='1';
    --    wait for clock_period_lif/2;
    --    clk_lif <='0';
    --    wait for clock_period_lif/2;
    --end process;
    
    clock_process_uart :process
    begin
        clk_uart <='1';
        wait for clock_period_uart/2;
        clk_uart <='0';
        wait for clock_period_uart/2;
    end process;
    
--    Update_UART_State: process(clk)
--    begin
--        if (rising_edge(CLK)) then
--            case uart_state is     
--                when W_FF =>
                
--                when W_AA=>
--                when NIST=>
--                when others =>
--                    null;
--            end case;
--        end if;
    
--    end process;
    


    STIM_UART_RX : process
        
        constant BYTE_0x10 : std_logic_vector(7 downto 0) := "00000000"; -- 00010000 for NI_ST
        variable i : integer := 0;
    begin
        for i in 1 to 1000 loop
            --1. Set up the SORTER to recieve NI_ST or W_FF or W_AA
            uart_rxd <= '0';  -- Start bit
            wait for clock_period_uart;
        
            for bit_idx in 0 to 7 loop
                uart_rxd <= BYTE_SETUP(bit_idx); -- Send data bits (LSB first)
                wait for clock_period_uart;
            end loop;
        
            uart_rxd <= '1'; -- Stop bit 1
            wait for clock_period_uart;
            uart_rxd <= '1'; -- Stop bit 2 (if used)
            wait for clock_period_uart;
            
            -- 2. Send Time difference->Neuron address 0x21 for 100 times
            if flag_NI_ST='1' then
                for i in 1 to (N0-1) loop
                    --2(a) Time difference
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_TIME_DIFF(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                    --2(b) Neuron address BYTE_0
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_NEURON_ADDR_BYTE_0(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                    --2(b) Neuron address BYTE_1
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_NEURON_ADDR_BYTE_1(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                end loop;
            
                -- Send 0x10 indefinitely (or for another set count)
                while true loop
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_0x10(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                end loop;
                
            elsif flag_FF='1' then
                for i in 1 to matrix_size_FF+1 loop
                    --2(a) Time difference
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_WEIGHT_FF(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                end loop;
                flag_FF<='0';
                flag_AA<='1';
                BYTE_SETUP<="00010000";
            elsif flag_AA='1' then
                for i in 1 to matrix_size+1 loop
                    --2(a) Time difference
                    uart_rxd <= '0';  -- Start bit
                    wait for clock_period_uart;
            
                    for bit_idx in 0 to 7 loop
                        uart_rxd <= BYTE_WEIGHT_AA(bit_idx); -- Send data bits (LSB first)
                        wait for clock_period_uart;
                    end loop;
            
                    uart_rxd <= '1'; -- Stop bit 1
                    wait for clock_period_uart;
                    uart_rxd <= '1'; -- Stop bit 2 (if used)
                    wait for clock_period_uart;
                end loop;
                flag_AA<='0';
                flag_NI_ST<='1';
                BYTE_SETUP<="00100000";
          
            end if;
        end loop;
    
    end process;


    -- Process to update the byte value periodically
    BYTE_UPDATE_PROCESS : process
    --    variable seed1, seed2 : positive := 1; -- Random seed values
    --    variable rand_val : real;
    --    variable new_byte : integer;
    begin
        wait for 11 * clock_period_uart;  -- Update interval
        while true loop
            wait for 33 * clock_period_uart;  -- Update interval
    
            -- Uncomment one of the following methods to update the byte dynamically:
    
            -- Method 1: Incrementing the byte value
            if flag_NI_ST='1' then
                BYTE_NEURON_ADDR_BYTE_0 <= std_logic_vector(unsigned(BYTE_NEURON_ADDR_BYTE_0) + 1);
            else 
                BYTE_NEURON_ADDR_BYTE_0 <= std_logic_vector(unsigned(BYTE_NEURON_ADDR_BYTE_0));
            end if;
    
            -- Method 2: Randomizing the byte value
    --        uniform(seed1, seed2, rand_val);
    --        new_byte := integer(rand_val * 256.0); -- Scale to 8-bit range (0-255)
    --        uart_byte <= std_logic_vector(to_unsigned(new_byte, 8));
        end loop;
    end process;
    
    BYTE_UPDATE_PROCESS_FF : process
    --    variable seed1, seed2 : positive := 1; -- Random seed values
    --    variable rand_val : real;
    --    variable new_byte : integer;
    begin
--        if flag_FF='1'then
            wait for 11 * clock_period_uart;  -- Update interval
            while true loop
                wait for 11 * clock_period_uart;  -- Update interval
        
                -- Uncomment one of the following methods to update the byte dynamically:
        
                -- Method 1: Incrementing the byte value
                if flag_FF='1' then
                    BYTE_WEIGHT_FF <= std_logic_vector(unsigned(BYTE_WEIGHT_FF)+ 1);
                else
                    BYTE_WEIGHT_FF <= std_logic_vector(unsigned(BYTE_WEIGHT_FF));
                end if;
        
                -- Method 2: Randomizing the byte value
        --        uniform(seed1, seed2, rand_val);
        --        new_byte := integer(rand_val * 256.0); -- Scale to 8-bit range (0-255)
        --        uart_byte <= std_logic_vector(to_unsigned(new_byte, 8));
            end loop;
--        end if;
    end process;
    
    BYTE_UPDATE_PROCESS_AA : process
    --    variable seed1, seed2 : positive := 1; -- Random seed values
    --    variable rand_val : real;
    --    variable new_byte : integer;
    begin
--        if flag_AA='1'then
            wait for 11 * clock_period_uart;  -- Update interval
            while true loop
                wait for 11 * clock_period_uart;  -- Update interval
        
                -- Uncomment one of the following methods to update the byte dynamically:
        
                -- Method 1: Incrementing the byte value
                if flag_AA = '1' then
                    if unsigned(BYTE_WEIGHT_AA) >= 127 then
                        BYTE_WEIGHT_AA <= std_logic_vector(to_unsigned(1, BYTE_WEIGHT_AA'length));
                    else
                        BYTE_WEIGHT_AA <= std_logic_vector(unsigned(BYTE_WEIGHT_AA));-- + 1);
                    end if;
                else
                    BYTE_WEIGHT_AA <= std_logic_vector(unsigned(BYTE_WEIGHT_AA));
                end if;
        
                -- Method 2: Randomizing the byte value
        --        uniform(seed1, seed2, rand_val);
        --        new_byte := integer(rand_val * 256.0); -- Scale to 8-bit range (0-255)
        --        uart_byte <= std_logic_vector(to_unsigned(new_byte, 8));
            end loop;
--        end if;
    end process;
--STIM_UART_RX :process
--begin
--    uart_rxd <= '0'; --START BIT
--    wait for clock_period_uart;
--    uart_rxd <= '1';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
--    uart_rxd <= '1';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
--    uart_rxd <= '0';
--    wait for clock_period_uart;
    
    
--    uart_rxd <= '1';--STOP BIT 1
--    wait for clock_period_uart;
--    uart_rxd <= '1';--STOP BIT 2
--end process;


end Behavioral;
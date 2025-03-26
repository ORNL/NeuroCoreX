LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY triger_generator IS
	PORT (
		CLK : IN STD_LOGIC;
		TRIGER : OUT STD_LOGIC;
--		TRIGER_UART_FIFO:OUT STD_LOGIC;
		ACTIVATE_TRIGER : IN STD_LOGIC
	);
END triger_generator;

ARCHITECTURE Behavioral OF triger_generator IS

	CONSTANT counter_max : NATURAL := 20;--10000; --0.1ms
	SIGNAL counter : std_logic_vector(16 DOWNTO 0) := (OTHERS => '0');

BEGIN
    PROCESS (CLK)
	BEGIN
	   IF ACTIVATE_TRIGER ='1' THEN
            IF (rising_edge(CLK)) THEN
                counter <= counter + 1;
                IF counter = counter_max-1 THEN
                    triger <= '1';
                    counter <= (OTHERS => '0');
--                ELSIF counter = counter_max-5 THEN
--                    TRIGER_UART_FIFO<='1';
                            
                ELSE
                    triger <= '0';
--                    TRIGER_UART_FIFO<='0';
                END IF;
            END IF;
        END IF;
	END PROCESS;

END Behavioral;
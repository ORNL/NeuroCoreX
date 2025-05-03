LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY triger_generator_uart IS
	PORT (
		CLK : IN STD_LOGIC;
		TRIGER : OUT STD_LOGIC;
		ACTIVATE_TRIGER : IN STD_LOGIC
	);
END triger_generator_uart;

ARCHITECTURE Behavioral OF triger_generator_uart IS

	CONSTANT counter_max : NATURAL := 10005;--10000; --0.1ms
	SIGNAL counter : std_logic_vector(16 DOWNTO 0) := (OTHERS => '0');
	SIGNAL sync_reg1, sync_reg2, prev_sync_reg2 : std_logic := '0';

BEGIN
    PROCESS (CLK)
	BEGIN
	   IF (rising_edge(CLK)) THEN
           sync_reg1<=ACTIVATE_TRIGER;
           sync_reg2 <= sync_reg1;
       END IF;
    END PROCESS; 
    
    PROCESS (CLK)
	BEGIN
	   IF (rising_edge(CLK)) THEN
           prev_sync_reg2 <= sync_reg2;
           IF (sync_reg2 = '0' AND prev_sync_reg2 = '1') THEN--falling edge of trigger
                TRIGER <= '1';  -- Generate a pulse for one 100MHz clock cycle
            ELSE
                TRIGER <= '0';
            END IF;
       END IF;
    END PROCESS; 


--    PROCESS (CLK)
--	BEGIN
--	   IF (rising_edge(CLK)) THEN
--           IF ACTIVATE_TRIGER ='1' THEN
--                IF (rising_edge(CLK)) THEN
--                    counter <= counter + 1;
--                    IF counter = counter_max-1 THEN
--                        triger <= '1';
--                        counter <= (OTHERS => '0');         
--                    ELSE
--                        triger <= '0';
--                    END IF;
--                END IF;
--            END IF;
--        END IF;
--	END PROCESS;

END Behavioral;
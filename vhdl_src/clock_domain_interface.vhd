LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
--USE ieee.numeric_std.ALL;

ENTITY clock_domain_interface IS
    PORT (
        clk_100MHz       : IN  std_logic;  -- Fast clock (100 MHz)
        clk_100kHz       : IN  std_logic;  -- Slow clock (100 kHz)
        Activate_fifo_in : IN  std_logic;  -- Pulse in 100 MHz domain
        Activate_fifo_out: OUT std_logic   -- Stretched pulse in 100 kHz domain
    );
END clock_domain_interface;

ARCHITECTURE Behavioral OF clock_domain_interface IS
    -- Synchronization registers
    SIGNAL sync_reg1 : std_logic := '0';
--    SIGNAL , sync_reg2 : std_logic := '0';
    -- Edge detection in 100 kHz domain
--    SIGNAL prev_sync_reg2 : std_logic := '0';
    SIGNAL flag_latched: STD_LOGIC:='0';
    
    -- Output signal
    SIGNAL pulse_stretched : std_logic := '0';
--    SIGNAL Counter_latched : STD_LOGIC_VECTOR(13 downto 0):=(others=>'0');
--    CONSTANT Counter_latched_Max : STD_LOGIC_VECTOR(13 downto 0):="10011100010000";

BEGIN
    -- **Step 1: Synchronize Activate_fifo_in to the 100kHz clock domain**
    PROCESS (clk_100MHz)
    BEGIN
        IF rising_edge(clk_100MHz) THEN
            IF Activate_fifo_in='1' and flag_latched='0' then
                sync_reg1 <= Activate_fifo_in;  -- First stage of synchronization
--            sync_reg2 <= sync_reg1;         -- Second stage of synchronization
                flag_latched<='1';
            ELSIF pulse_stretched = '1' THEN
                flag_latched<='0';
                sync_reg1<='0';
            ELSE
                NULL;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS (clk_100KHz)
    BEGIN
        IF rising_edge(clk_100KHz) THEN
            IF sync_reg1='1' THEN
                pulse_stretched <= '1';  -- Generate a pulse for one 100kHz clock cycle
            ELSE
                pulse_stretched <= '0';
            END IF;
--            flag_latched<='1';
        END IF;
    END PROCESS;        
    
--    PROCESS (clk_100MHz)
--    BEGIN
--        IF rising_edge(clk_100MHz) THEN
--            IF Activate_fifo_in='1' THEN
--                IF Counter_latched<Counter_latched_max and flag_latched='0' then
--                    sync_reg1 <= Activate_fifo_in;  -- First stage of synchronization
--                    sync_reg2 <= sync_reg1;         -- Second stage of synchronization
--                    flag_latched<='1';
--                ELSIF Counter_latched=Counter_latched_max THEN
--                    sync_reg1<= '0';
--                    sync_reg2<= '0';
--                    flag_latched<='0';
--                ELSE
--                    sync_reg1<= '1';
--                    sync_reg2<= '1';
--                    Counter_latched<=Counter_latched+1;
--                END IF;
--            END IF;
--        END IF;
--    END PROCESS;

--    -- **Step 2: Detect rising edge of synchronized signal and generate pulse**
--    PROCESS (clk_100kHz)
--    BEGIN
--        IF rising_edge(clk_100kHz) THEN
--            prev_sync_reg2 <= sync_reg2;  -- Store previous state
            
--            -- Rising edge detection
--            IF (sync_reg2 = '1' AND prev_sync_reg2 = '0') THEN
--                pulse_stretched <= '1';  -- Generate a pulse for one 100kHz clock cycle
--            ELSE
--                pulse_stretched <= '0';
--            END IF;
--        END IF;
--    END PROCESS;

    -- Assign output signal
    Activate_fifo_out <= pulse_stretched;

END Behavioral;

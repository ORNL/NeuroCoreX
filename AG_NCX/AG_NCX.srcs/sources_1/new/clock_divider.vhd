library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Clock_Divider is
    Port (
        clk_in  : in  std_logic;  -- 100 MHz input clock
        rst     : in  std_logic;  -- Reset signal
        clk_out : out std_logic   -- 100 kHz output clock
    );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
    component IBUFG
    port(
       I : in std_logic;
       O : out std_logic
        );
    end component;
    signal counter : integer := 0;
    signal clk_div, clk_buf : std_logic := '0';
begin
    process (clk_in, rst)
    begin
        if rst = '1' then
            counter <= 0;
            clk_div <= '0';
        elsif rising_edge(clk_in) then
            if counter = 499 then
                clk_div <= not clk_div;  -- Toggle the clock output
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
        -- Instantiate BUFG to use clk_div as a real clock
    BUFG_inst : IBUFG
    port map (
        O => clk_buf,  -- Global clock output
        I => clk_div   -- Input clock signal
    );

    clk_out <= clk_buf;  -- Assign the buffered clock to output

--    clk_out <= clk_div;  -- Assign divided clock to output

end Behavioral;

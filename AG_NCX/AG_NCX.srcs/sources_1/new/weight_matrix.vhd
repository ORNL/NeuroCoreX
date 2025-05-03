library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity weight_ram is
    Port (
    clk        : in  std_logic;
    we         : in  std_logic;
    write_addr : in  unsigned(15 downto 0); -- enough bits for 16K words
    data_in    : in  signed(7 downto 0);
    read_addr  : in  unsigned(15 downto 0);
    data_out   : out signed(7 downto 0);
    read_addr_STDP : in  unsigned(15 downto 0);
    data_out_STDP : out signed(7 downto 0)
    );
end weight_ram;

architecture Behavioral of weight_ram is
    CONSTANT N1 : NATURAL := 95; --19;
    CONSTANT N0 : NATURAL := 0;
    type weight_array is array (0 to (N1+1)*(N1+1)-1) of signed(7 downto 0);
--    signal ram : weight_array:= (others => (others => '0'));

        constant init_weights : weight_array := (
    1   => to_signed(6, 8),  -- example value for word 0
--    101   => to_signed(3, 8),  -- example value for word 1
--    201   => to_signed(4, 8),  -- example value for word 2
--    301   => to_signed(5, 8),  -- example value for word 0
--    401   => to_signed(6, 8),  -- example value for word 1
--    501   => to_signed(7, 8),  -- example value for word 2
--    9801   => to_signed(8, 8),
--    9901   => to_signed(9, 8),
    -- ... continue for other specific addresses as needed
    others => to_signed(6, 8)
    );
    signal ram : weight_array := init_weights;
    attribute ram_style : string;
    attribute ram_style of ram : signal is "block";

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
         ram(to_integer(write_addr)) <= data_in;
--         ram(to_integer(write_addr)) <= ram(to_integer(write_addr)) + data_in;
      end if;
      data_out <= ram(to_integer(read_addr));
      data_out_STDP <= ram(to_integer(read_addr_STDP));
    end if;
  end process;

end Behavioral;

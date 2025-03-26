----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Ashish Gautam
-- 
-- Create Date: 11/18/2024 03:58:34 PM
-- Design Name: 
-- Module Name: UART_NETWORK_LINK - Behavioral
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
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_RX_SORTER_Input is
    Port ( CLK : in STD_LOGIC;
           DATA_IN : in STD_LOGIC_VECTOR (7 downto 0);
           READ_EN : in STD_LOGIC;
           ACTIVATE_FIFO : in STD_LOGIC;
           DATA_OUT_WEIGHT_FF : out STD_LOGIC_VECTOR (7 downto 0);--Weights for FF connections
           DATA_OUT_WEIGHT_AA: out STD_LOGIC_VECTOR (7 downto 0);--Weights for FF connections
           DATA_OUT_SPIKE_ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
           FLAG_OVERFLOW: out STD_LOGIC;
           FLAG_UNDERFLOW: out STD_LOGIC;
           WRITE_EN_FF_W : out STD_LOGIC;
           WRITE_EN_AA_W : out STD_LOGIC;
           WRITE_EN_INPUT : out STD_LOGIC;
           ACTIVATE_TRIGER : out STD_LOGIC
           );
end UART_RX_SORTER_Input;

architecture Behavioral of UART_RX_SORTER_Input is

component fifo_generator_0
port(
    clk         : in std_logic;
    wr_en       : in std_logic;
    din         : in std_logic_vector(23 downto 0);
    full        : out std_logic;
    almost_full : out std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(23 downto 0);
    empty       : out std_logic;
    almost_empty: out std_logic;
    srst        : in std_logic
    
);
end component;
--type SORTER_STATE is (STATIC, JTAG, DYNAMIC, PATTERN);
type sorter_state_pattern is (BIT_ADDRESS_BYTE2, BIT_TIME_DIFF,BIT_ADDRESS_BYTE1);
signal patternState : sorter_state_pattern := BIT_TIME_DIFF;
signal sorter_state : std_logic_vector (3 downto 0):= "0000";
--signal adrs_buf : std_logic_vector (3 downto 0);
--signal data_buf : std_logic_vector (7 downto 0);
signal adrs_flag : std_logic := '1';
--signal data_flag : std_logic := '0';
signal en_FF_W, en_AA_W, en_Input : std_logic :='0';
--signal DATA_OUT_SPIKE : std_logic_vector (7 downto 0):=(others=>'0');
signal update_time_flag : std_logic :='0';
signal in_byte_order : integer:=0;
signal Spike_Time : std_logic_vector (7 downto 0):=(others=>'0');
signal Neuron_address : std_logic_vector (15 downto 0):=(others=>'0');
--type SPIKE_TIME_ARRAY_TYPE is array (integer range <>) of std_logic_vector(7 downto 0);
--type SYNAPSE_ADDRESS_ARRAY_TYPE is array (integer range <>) of std_logic_vector(7 downto 0);
--signal Spike_time_array : SPIKE_TIME_ARRAY_TYPE (0 to 600):= (others=>(others=>'0'));
--signal Synapse_address_array : SYNAPSE_ADDRESS_ARRAY_TYPE (0 to 600):= (others=>(others=>'0'));
--constant index_load_limit : integer:=600;
--signal index_load : integer:=0;
--signal index_load_max : integer:=3;
signal start_PATTERN, WRITE_EN_PATTERN : std_logic :='0';
signal Counter_clk :std_logic_vector (31 downto 0):=(others=>'0');
signal Counter_clk_prev:std_logic_vector (31 downto 0):="00000000000000000000000000000001";
--signal DATA_OUT_SPIKE_DECODER : std_logic_vector (7 downto 0):=(others=>'0');
--signal DATA_OUT_PATTERN_DECODER : std_logic_vector (7 downto 0):=(others=>'0');
signal en_Pattern_flag,Pattern_done_flag  : std_logic :='0';
--signal Counter_clk_MAX : std_logic_vector(31 downto 0):="00000001010101110101001010100000";--(others=>'1');--"00000001010101110101001010100000";  "00000000000000000000010000100000"
signal NI_ST : std_logic_vector(23 downto 0):=(others=>'0');
signal Din_FIFO, Dout_FIFO : std_logic_vector (23 downto 0):=(others=>'0');
signal NI :  std_logic_vector (15 downto 0):=(others=>'0');
signal FIFO_wr_en, FIFO_rd_en, FIFO_full, FIFO_almost_full, FIFO_empty, FIFO_almost_empty :  std_logic :='0';
signal FIFO_reset : std_logic :='0' ;
--signal en_clr_int,cntr_flag : std_logic :='1' ;
--signal en_CLR_Pulse,en_Syn_resistor,en_port_Syn_resistor : std_logic:='0';
--signal Counter_clock_us : unsigned(15 downto 0); 
--signal Counter_clk_int, Counter_clk_prev_int: integer range 0 to 22500000:=0;
signal Dout_FIFO_int: integer range 0 to 256:=0;
--signal Counter_clk_high : std_logic_vector (9 downto 0):=(others=>'0');
--signal Counter_clk_high_Max : std_logic_vector (9 downto 0):="1111101000";
signal N0 : integer := 20;
signal N1 : integer := 40;
signal counter_FF_max_count : std_logic_vector (15 downto 0):="0010011100010001";--for 10,000 values
signal counter_FF_count : std_logic_vector (15 downto 0):=(others=>'0');
signal counter_AA_max_count : std_logic_vector (15 downto 0):="0010011100010001";
signal counter_AA_count : std_logic_vector (15 downto 0):=(others=>'0');

signal Counter_trigger: std_logic_vector (23 downto 0):=(others=>'0');--"000000000000000000000001";
signal Counter_trigger_prev: std_logic_vector (23 downto 0):=(others=>'0');
signal flag_read_fifo : std_logic:='0';

begin
--test<=start_PATTERN;
--en_clr<=en_clr_int;
--en_clr<= cntr_flag;
--SYN_RES_EN <=en_port_Syn_resistor;
counter_FF_max_count <= std_logic_vector(to_unsigned((N0*N1), 16));
counter_AA_max_count <= std_logic_vector(to_unsigned((N0*N0), 16));
sorter_process : process(CLK)
begin
    if (rising_edge(CLK)) then
        if (READ_EN='1') then
            if(adrs_flag='1') then
--                adrs_buf<=DATA_IN(3 downto 0);
                sorter_state<=DATA_IN(7 downto 4);
                adrs_flag<='0';
--                data_flag<='0';
--                if(DATA_IN(7 downto 4)="0100") then
--                    en_clr_int<='0';
--                end if;
--                if(DATA_IN(7 downto 4)="0110") then
--                    en_port_Syn_resistor<='1';
--                else
--                    en_port_Syn_resistor<='0';
--                end if;
            else
                case sorter_state is     
                    when "0000" =>
                        if counter_FF_count<counter_FF_max_count then
                            DATA_OUT_WEIGHT_FF <=DATA_IN;
                            counter_FF_count<=counter_FF_count+1;
                            en_FF_W<='1';--signal for storing weight at the next level
                        else
                            DATA_OUT_WEIGHT_FF <=(others=>'0');
                            en_FF_W<='0';
                            adrs_flag<='1';
                        end if;
                    when "0001" =>
                        if counter_AA_count<counter_AA_max_count then
                            DATA_OUT_WEIGHT_AA <=DATA_IN;
                            counter_AA_count<=counter_AA_count+1;
                            en_AA_W<='1';--signal for storing weight at the next level
                        else
                            DATA_OUT_WEIGHT_AA <=(others=>'0');
                            adrs_flag<='1';
                            en_AA_W<='0';
                        end if;
                    when "0010" =>
                        
                        --en_clr_int<='1';
                        
                        case patternState is
                            when BIT_TIME_DIFF =>
                                Spike_Time(7 downto 0)<=DATA_IN;--Current time difference in in 8 bits
                                patternState<=BIT_ADDRESS_BYTE1;
                                update_time_flag <='0';
                            when BIT_ADDRESS_BYTE1 =>
                                Neuron_address(7 downto 0)<=DATA_IN;
                                patternState<=BIT_ADDRESS_BYTE2;
                                update_time_flag <='0';
                            when BIT_ADDRESS_BYTE2 =>
                                Neuron_address(15 downto 8)<=DATA_IN;
                                NI_ST(23 downto 16)<=Spike_Time;
                                NI_ST(7 downto 0)<=Neuron_address(7 downto 0);
                                NI_ST(15 downto 8)<=DATA_IN; -- Syn address.
                                patternState<=BIT_TIME_DIFF;
                                update_time_flag <='1';
                            when others =>
                                null;
                            end case;
                    when others =>
                        adrs_flag<='1';
                        --null;
                end case;
            end if;
        elsif(Pattern_done_flag='1') then
            adrs_flag<='1';
            --patternState<=BIT_OUT;
        else
            en_FF_W <='0';
            en_AA_W <='0';
            --en_Input <='0';
--            en_JTAG <='0';
--            en_JTAG_Read<='0';
--            en_Dynamic_SPIKE<='0';
            update_time_flag <='0';
--            en_CLR_Pulse<='0';
--            en_Syn_Resistor <='0';
        end if;
    end if;
end process;

process_flag_update: process(clk)
begin
    if(rising_edge(CLK)) then
        if(FIFO_full='1') then
            flag_overflow<='1';
        elsif(start_PATTERN='1' and FIFO_empty='1') then
            flag_underflow<='1';
        else
            flag_overflow<='0';
            flag_underflow<='0';
        end if;
    end if;
end process;

--process_update_array: process(clk)
--begin
--    if(rising_edge(CLK)) then
--        if(update_time_flag='1' and en_Input='1'and FIFO_full/='1') then
--            NI<=Dout_FIFO(15 downto 0);
--            FIFO_rd_en <='1';
--            Din_FIFO<=NI_ST;
--            FIFO_wr_en <='1';
--        elsif(update_time_flag='1' and FIFO_full/='1') then--starts from here (Ash-1)
--            Din_FIFO<=NI_ST;
--            FIFO_wr_en <='1';
--            FIFO_rd_en <='0';
--        elsif(en_Input='1') then
--            NI<=Dout_FIFO(15 downto 0);
--            FIFO_rd_en <='1';
--            FIFO_wr_en <='0';
--        else
--            FIFO_rd_en <='0';
--            FIFO_wr_en <='0';
--        end if;
--    end if;
--end process;

process_update_array: process(clk)
begin
    if(rising_edge(CLK)) then
        if(update_time_flag='1' and flag_read_fifo='1'and FIFO_full/='1') then
            NI<=Dout_FIFO(15 downto 0);
            FIFO_rd_en <='1';
            Din_FIFO<=NI_ST;
            FIFO_wr_en <='1';
        elsif(update_time_flag='1' and FIFO_full/='1') then--starts from here (Ash-1)
            Din_FIFO<=NI_ST;
            FIFO_wr_en <='1';
            FIFO_rd_en <='0';
        elsif(flag_read_fifo='1') then
            NI<=Dout_FIFO(15 downto 0);
            FIFO_rd_en <='1';
            FIFO_wr_en <='0';
        else
            FIFO_rd_en <='0';
            FIFO_wr_en <='0';
        end if;
    end if;
end process;

process_check_pattern_write: process(clk)
begin
    if(rising_edge(CLK)) then
        if(Pattern_done_flag='1') then
            start_PATTERN<='0';
        elsif(FIFO_almost_empty/='1') then
            start_PATTERN<='1'; --(Ash-2)
        end if;
    end if;
end process;

--process_trigger_pattern: process(clk)--VERIFY IF THIS IS NEEDED.
--begin
--    if(rising_edge(CLK)) then
--        if(start_PATTERN='1' and Counter_clk_int-Counter_clk_prev_int>=Dout_FIFO_int and en_Pattern_flag='1' and FIFO_empty/='1' and FIFO_rd_en/='1' and Counter_clk<Counter_clk_MAX) then--Spike_time_array(0)/=0
--            en_Input<='1';--(Ash-3)
--            Counter_clk_prev<=Counter_clk;
--            en_Pattern_flag<='0';--I used this probably to make en_Pattern zero for it to goto 1 again.
--        elsif(Counter_clk=Counter_clk_MAX) then
--            Counter_clk_prev<="00000000000000000000000000000001";
--            en_Input<='0';
--            en_Pattern_flag<='1';
--        else
--            en_Input<='0';
--            en_Pattern_flag<='1';
--        end if;
--    end if;
--end process;


--process_internal_clock: process(clk)--VERIFY IF NEEDED
--begin
--    if(rising_edge(clk)) then
--        if(Counter_clk=Counter_clk_MAX) then
--            Counter_clk<=(others=>'0');
--            Pattern_done_flag<='1';
--        elsif(Counter_clk_high=Counter_clk_high_MAX and start_pattern='1') then
--            Counter_clk<=Counter_clk+1;
--            Counter_clk_high<="0000000001";
--        elsif(start_pattern='1') then
--            Counter_clk_high<=Counter_clk_high+1;
--        elsif(start_PATTERN='0') then
--            Pattern_done_flag<='0';
--        end if;
--    end if;
--end process;


--Counter_clk_int<=to_integer(unsigned(Counter_clk));
--Counter_clk_prev_int<=to_integer(unsigned(Counter_clk_prev));
Dout_FIFO_int<=to_integer(unsigned(Dout_FIFO(23 downto 16)));

process_trigger: process(clk) 
begin
    if (rising_edge(CLK)) then
--        if (en_JTAG='1') then
--            WRITE_EN_JTAG <= '1';
--        elsif (en_dynamic='1') then
--            WRITE_EN_DYNAMIC_P <= '1';
--            DATA_OUT_DYNAMIC<=DATA_OUT_SPIKE_DECODER;
        if (en_FF_W='1') then
            WRITE_EN_FF_W <= '1';
        elsif (en_AA_W='1') then
            WRITE_EN_AA_W <= '1';
        elsif(FIFO_rd_en='1') then
            WRITE_EN_INPUT <= '1';
            DATA_OUT_SPIKE_ADDRESS<=NI;
        else
--            WRITE_EN_JTAG <= '0';
            WRITE_EN_FF_W <= '0';
            WRITE_EN_AA_W<='0';
            WRITE_EN_INPUT <= '0';
--            WRITE_EN_DYNAMIC_SPIKE <= '0';
--            WRITE_EN_DYNAMIC_P <= '0';
--            WRITE_EN_JTAG_READ <= '0';
--            WRITE_EN_CLR <='0';
--            WRITE_EN_SYN_RES <= '0';
        end if;
    end if;
end process;

--process_verify_clock: process(clk)--VERIFY IF NEEDED
--begin
--    if(rising_edge(CLK)) then
--        if(Counter_clk=Counter_clk_MAX) then
--            cntr_flag<='1';
--        elsif(Counter_clk=0) then
--            cntr_flag<='1';
--        elsif(Counter_clk> 1) then
--            cntr_flag<='0';
--        else
--            cntr_flag<='1';
--        end if;
--    end if;
--end process;     

process_activate_triger_module: process(clk)
begin
    if(rising_edge(CLK)) then
        if(FIFO_almost_empty='0') then
            ACTIVATE_TRIGER<='1';
        end if;
    end if;
end process;
            
process_activate_fifo: process(clk)
begin
    if(rising_edge(CLK)) then
        if(ACTIVATE_FIFO='1') then
            Counter_trigger<=Counter_trigger+1;
        end if;
    end if;
end process;

process_time_keeper: process(clk)
begin
    if(rising_edge(clk)) then
        if Counter_trigger-Counter_trigger_prev>Dout_FIFO_int then
            flag_read_fifo<='1';
            Counter_trigger_prev<=Counter_trigger;
        else
            flag_read_fifo<='0';
        end if;
    end if;
end process;

Inst_FIFO_PC_FPGA: fifo_generator_0
    port map(
    clk         => CLK,
    wr_en       => FIFO_wr_en,
    din         => Din_FIFO,
    full        => FIFO_full,
    almost_full => FIFO_almost_full,
    rd_en       => FIFO_rd_en,
    dout        => Dout_FIFO,
    empty       => FIFO_empty,
    almost_empty=> FIFO_almost_empty,
    srst        => FIFO_reset
    );

--WRITE_EN_STATIC <= data_flag;
--WRITE_EN_DYNAMIC <= en_dynamic;
--WRITE_EN_JTAG <= en_JTAG;
end Behavioral;
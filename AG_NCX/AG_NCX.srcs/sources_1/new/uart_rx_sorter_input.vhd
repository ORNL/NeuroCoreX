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
           PORT_flag_READ_DONE : in STD_LOGIC;
           DATA_OUT_WEIGHT_FF : out STD_LOGIC_VECTOR (7 downto 0);--Weights for FF connections
           DATA_OUT_WEIGHT_AA: out STD_LOGIC_VECTOR (7 downto 0);--Weights for FF connections
           DATA_OUT_SPIKE_ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
           DATA_OUT_NEURON_PARAM : out STD_LOGIC_VECTOR (17 downto 0);
           DATA_OUT_NEURON_DEBUG : out STD_LOGIC_VECTOR (17 downto 0);
           DATA_OUT_STDP_FLAG: out STD_LOGIC_VECTOR (7 downto 0);
           FLAG_OVERFLOW: out STD_LOGIC;
           FLAG_UNDERFLOW: out STD_LOGIC;
           WRITE_EN_FF_W : out STD_LOGIC;
           WRITE_EN_AA_W : out STD_LOGIC;           
           READ_EN_AA_W : out STD_LOGIC;
           WRITE_EN_INPUT : out STD_LOGIC;
           WRITE_EN_PARAM : out STD_LOGIC;
           WRITE_EN_DEBUG : out STD_LOGIC;
           WRITE_EN_STDP_FLAG: out STD_LOGIC;
           ILA_TEST_PORT:out STD_LOGIC_VECTOR(3 downto 0);
           RESET_TRIGER: out STD_LOGIC;
           READ_WEIGHT_AA: out STD_LOGIC;
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

COMPONENT fifo_generator_2 IS
    PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
--            data_count : OUT SIGNED(13 DOWNTO 0)
    );
END COMPONENT;
--type SORTER_STATE is (STATIC, JTAG, DYNAMIC, PATTERN);
type sorter_state_pattern is (BIT_TIME_DIFF,BIT_ADDRESS_BYTE1, BIT_ADDRESS_BYTE2, BIT_WAIT_FIFO_EMPTY);
type sorter_state_pattern_Thr is (THR_VALUE_BYTE1, THR_VALUE_BYTE2, THR_VALUE_BYTE3);
type sorter_state_pattern_DEBUG is (DEBUG_VALUE_BYTE1, DEBUG_VALUE_BYTE2, DEBUG_VALUE_BYTE3);
signal patternState : sorter_state_pattern := BIT_TIME_DIFF;
signal sorter_state : std_logic_vector (3 downto 0):= "0000";
signal patternState_THR: sorter_state_pattern_Thr :=THR_VALUE_BYTE1;
signal patternState_DEBUG: sorter_state_pattern_DEBUG :=DEBUG_VALUE_BYTE1;
--signal Neuron_thr :  std_logic_vector (17 downto 0):= (others=>'0');
--signal adrs_buf : std_logic_vector (3 downto 0);
--signal data_buf : std_logic_vector (7 downto 0);
signal adrs_flag : std_logic := '1';
--signal data_flag : std_logic := '0';
signal en_FF_W, en_AA_W, en_AA_W_Read, en_PARAM, en_Input, en_DEBUG : std_logic :='0';
--signal DATA_OUT_SPIKE : std_logic_vector (7 downto 0):=(others=>'0');
signal update_time_flag, update_thr_flag : std_logic :='0';
--signal in_byte_order : integer:=0;
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
constant N0 : integer := 96;--20;(14+6)96
constant N1 : integer := 96;--20;(14+6)96
signal counter_FF_max_count : std_logic_vector (15 downto 0):="0010011100010001";--for 10,000 values
signal counter_FF_count : std_logic_vector (15 downto 0):=(others=>'0');
signal counter_AA_max_count : std_logic_vector (15 downto 0):="0010011100010001";
signal counter_AA_count : std_logic_vector (15 downto 0):=(others=>'0');

signal Counter_trigger: std_logic_vector (23 downto 0):=(others=>'0');--"000000000000000000000001";
signal Counter_trigger_prev: std_logic_vector (23 downto 0):=(others=>'0');
signal flag_read_fifo : std_logic:='0';
signal counter_Thr : std_logic_vector (10 downto 0):=(others=>'0');
signal ctr :std_logic_vector (23 downto 0):=(others=>'0');
signal emulation_ON : std_logic:='0';
signal emu : std_logic:='0';
signal trigger_RESET : std_logic:='0';
signal READ_W_AA : std_logic:='0';
signal Read_Tx, Tx_config :  std_logic_vector(3 downto 0):=(others=>'0');
signal NUM_DEBUG_PARAM : std_logic_vector(3 downto 0):="0010";
signal counter_Debug:std_logic_vector (3 downto 0):=(others=>'0');
signal flag_read_start: std_logic:= '1';
signal fifo_STDP_IN, fifo_STDP_OUT, STDP_OUT_Tx_vec: std_logic_vector(7 downto 0) := (others => '0');
signal fifo_wr_en_STDP, fifo_rd_en_STDP, fifo_STDP_full, fifo_STDP_empty, fifo_STDP_srst,fifo_wr_en_STDP_last: std_logic := '0';
constant CTR_STDP_FLAG_MAX: integer := ((2*(N1*N1) + 7) / 8);
signal CTR_STDP_FLAG: integer range 0 to N1*N1:=0;
constant CLOCKS_PER_TRIGGER : integer := 1600;  -- 11 us at 100 MHz
--    constant N1 : integer := 19;  -- for example
constant TRIGGER_COUNT_MAX : integer := CTR_STDP_FLAG_MAX;  -- 400 for N1=19        
signal trigger_counter : integer range 0 to CLOCKS_PER_TRIGGER := 0;
signal trigger_count   : integer range 0 to TRIGGER_COUNT_MAX := 0;
signal trigger_active  : std_logic := '0';
signal trigger_pulse, begin_trigger, W_EN_STDP_FLAG,W_EN_STDP_FLAG_INT    : std_logic := '0';

begin
--test<=start_PATTERN;
--en_clr<=en_clr_int;
--en_clr<= cntr_flag;
--SYN_RES_EN <=en_port_Syn_resistor;
--ILA_TEST_PORT<=sorter_state;
WRITE_EN_STDP_FLAG<=W_EN_STDP_FLAG;
READ_WEIGHT_AA<=READ_W_AA;
ILA_TEST_PORT(0)<=FIFO_empty;
ILA_TEST_PORT(1)<=FIFO_almost_empty;
ILA_TEST_PORT(2)<=update_time_flag;
ILA_TEST_PORT(3)<=FIFO_full;
RESET_TRIGER<=trigger_RESET;
counter_FF_max_count <= std_logic_vector(to_unsigned((N0*N1), 16));
counter_AA_max_count <= std_logic_vector(to_unsigned((N0*N0), 16));
sorter_process : process(CLK)
begin
    if (rising_edge(CLK)) then
        if (READ_EN='1' or PORT_flag_READ_DONE='1') then
            if(adrs_flag='1') then
                Read_Tx<=DATA_IN(3 downto 0);
                sorter_state<=DATA_IN(7 downto 4);
                adrs_flag<='0';
--                data_flag<='0';
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
                            counter_FF_count<=(others=>'0');
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
                            counter_AA_count<=(others=>'0');
                        end if;
                    when "0010" =>
                        case patternState_THR is
                            when THR_VALUE_BYTE1 =>
                                DATA_OUT_Neuron_PARAM(7 downto 0)<=DATA_IN;--Current time difference in in 8 bits
                                patternState_THR<=THR_VALUE_BYTE2;
                                en_Param <='0';
                            when THR_VALUE_BYTE2 =>
                                DATA_OUT_Neuron_PARAM(15 downto 8)<=DATA_IN;
                                patternState_THR<=THR_VALUE_BYTE3;
                                en_Param <='0';
                            when THR_VALUE_BYTE3 =>
                                DATA_OUT_Neuron_PARAM(17 downto 16)<=DATA_IN(1 downto 0);
--                                NI_ST(23 downto 16)<=Spike_Time;
--                                NI_ST(7 downto 0)<=Neuron_address(7 downto 0);
--                                NI_ST(15 downto 8)<=DATA_IN; -- Syn address.
                                patternState_THR<=THR_VALUE_BYTE1;
                                en_Param <='1';
                                counter_Thr<=counter_Thr+1;
                                
                                if counter_Thr>=(4*N0)-1 then
                                    counter_Thr<=(others=>'0');
                                    adrs_flag<='1';
                                end if;
                            when others =>
                                null;
                        end case;
                                            
                    when "0011" =>
                        
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
                                if DATA_IN="11111111" and Spike_Time="11111111" and Neuron_address(7 downto 0)="11111111" then
                                    update_time_flag <='0';
--                                    patternState<=BIT_WAIT_FIFO_EMPTY;
                                    patternState<=BIT_TIME_DIFF;
                                    adrs_flag<='1';
                                    trigger_RESET <= '1';
                                else
                                    patternState<=BIT_TIME_DIFF;
                                    update_time_flag <='1';
                                    trigger_RESET <= '0';
                                end if;
                            
                            when others =>
                                null;
                            end case;
                    when "0100" =>
                        case patternState_DEBUG is
                            when DEBUG_VALUE_BYTE1 =>
                                DATA_OUT_Neuron_DEBUG(7 downto 0)<=DATA_IN;--Current time difference in in 8 bits
                                patternState_DEBUG<=DEBUG_VALUE_BYTE2;
                                en_DEBUG <='0';
                            when DEBUG_VALUE_BYTE2 =>
                                DATA_OUT_Neuron_DEBUG(15 downto 8)<=DATA_IN;
                                patternState_DEBUG<=DEBUG_VALUE_BYTE3;
                                en_DEBUG <='0';
                            when DEBUG_VALUE_BYTE3 =>
                                DATA_OUT_Neuron_DEBUG(17 downto 16)<=DATA_IN(1 downto 0);
--                                NI_ST(23 downto 16)<=Spike_Time;
--                                NI_ST(7 downto 0)<=Neuron_address(7 downto 0);
--                                NI_ST(15 downto 8)<=DATA_IN; -- Syn address.
                                patternState_DEBUG<=DEBUG_VALUE_BYTE1;
                                en_DEBUG <='1';
                                counter_DEBUG<=counter_DEBUG+1;
                                
                                if counter_DEBUG>=NUM_DEBUG_PARAM-1 then
                                    counter_DEBUG<=(others=>'0');
                                    adrs_flag<='1';
                                end if;
                            when others =>
                                null;
                        end case;
--                  
                    when "0101" =>
--                        adrs_flag<='1';
                        if PORT_flag_READ_DONE='1' THEN
                            READ_W_AA <= '0';
                            flag_read_start<='1';
                            adrs_flag<='1';
                        elsif flag_read_start='1' then
                            READ_W_AA <= '1';
                            flag_read_start<='0';
                        elsif PORT_flag_READ_DONE='0' THEN
                            READ_W_AA <= '1';
                        ELSE
                            READ_W_AA <= '0';
                            flag_read_start<='1';
                        END IF;
                    when "0110" =>
                        if CTR_STDP_FLAG<CTR_STDP_FLAG_MAX then
                            fifo_wr_en_STDP<= '1';
                            fifo_STDP_IN<=DATA_IN;
                            CTR_STDP_FLAG<=CTR_STDP_FLAG+1;
                        else
                            CTR_STDP_FLAG<=0;
                            fifo_wr_en_STDP<= '0';
                            adrs_flag<='1';
                        end if;
                                
                    when others =>
                        adrs_flag<='1';
                        null;
                end case;
            end if;
--        elsif(Pattern_done_flag='1') then
--            adrs_flag<='1';
            --patternState<=BIT_OUT;
        else
            en_FF_W <='0';
            en_AA_W <='0';
            en_AA_W_Read <='0';
            en_Param <= '0';
            en_Debug <= '0';
            update_time_flag <='0';
            fifo_wr_en_STDP<= '0';

        end if;
    end if;
end process;

process_activate_triger_module: process(clk)
begin
    if(rising_edge(CLK)) then
        if(FIFO_empty='0') then
            ACTIVATE_TRIGER<='1';
            emulation_ON<='1';
        elsif (emulation_ON='1' and trigger_RESET='0') then
            ACTIVATE_TRIGER<='1';
        else
            ACTIVATE_TRIGER<='0';
            emulation_ON<='0';
        end if;
    end if;
end process;

--process_flag_update: process(clk)
--begin
--    if(rising_edge(CLK)) then
--        if(FIFO_full='1') then
--            flag_overflow<='1';
--        elsif(start_PATTERN='1' and FIFO_empty='1') then
--            flag_underflow<='1';
--        else
--            flag_overflow<='0';
--            flag_underflow<='0';
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
        elsif(update_time_flag='1' and FIFO_full/='1') then --starts from here (Ash-1)
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
        elsif (en_AA_W_Read='1') then
            READ_EN_AA_W <= '1';            
        elsif (en_Param='1') then
            WRITE_EN_PARAM <= '1';
        elsif (en_Debug='1') then
            WRITE_EN_DEBUG <= '1';      
        elsif(FIFO_rd_en='1') then
            WRITE_EN_INPUT <= '1';
            DATA_OUT_SPIKE_ADDRESS<=NI;
        else
--            WRITE_EN_JTAG <= '0';
            WRITE_EN_FF_W <= '0';
            WRITE_EN_AA_W<='0';
            WRITE_EN_INPUT <= '0';
            WRITE_EN_PARAM <= '0';
            READ_EN_AA_W <= '0';
            WRITE_EN_DEBUG <= '0';
--            WRITE_EN_DYNAMIC_SPIKE <= '0';
--            WRITE_EN_DYNAMIC_P <= '0';
--            WRITE_EN_JTAG_READ <= '0';
--            WRITE_EN_CLR <='0';
--            WRITE_EN_SYN_RES <= '0';
        end if;
    end if;
end process;
            
process_activate_fifo: process(clk)
begin
    if(rising_edge(CLK)) then
        if(ACTIVATE_FIFO='1' and FIFO_empty='0') then
            Counter_trigger<=Counter_trigger+1;
        elsif emulation_ON='0' and FIFO_empty='1' then
            Counter_trigger<= (others=>'0');
        end if;
    end if;
end process;

process_time_keeper: process(clk)
begin
    if(rising_edge(clk)) then
        if emulation_ON='0' and FIFO_empty='1' then
            Counter_trigger_prev<= (others=>'0');
            flag_read_fifo<='0';
        elsif Counter_trigger-Counter_trigger_prev>Dout_FIFO_int then
            flag_read_fifo<='1';
            Counter_trigger_prev<=Counter_trigger;
        else
            flag_read_fifo<='0';
        end if;
    end if;
end process;

process_STDP_flag_Tx: process(clk)
    begin
        if rising_edge(clk) then
            if sorter_state = "0110" or fifo_STDP_empty='0' then
                -- Detect rising edge of fifo_wr_en_Spike when ACT_TRIGGER is high
                if fifo_wr_en_STDP = '1' and fifo_wr_en_STDP_last = '0' then
                    begin_trigger <= '1';
                else
                    begin_trigger <= '0';
                end if;
        
                fifo_wr_en_STDP_last <= fifo_wr_en_STDP;
        
                -- Start the trigger only once, on first eligible rising edge
                if begin_trigger = '1' and trigger_active = '0' then
                    trigger_active <= '1';
                    trigger_count <= 0;
                    trigger_counter <= 0;
                end if;
        
                -- Regular trigger generation
                if trigger_active = '1' then
                    if trigger_counter = CLOCKS_PER_TRIGGER - 1 then
                        trigger_counter <= 0;
                        fifo_rd_en_STDP <= '1';
                        trigger_count <= trigger_count + 1;
        
                        if fifo_STDP_empty='1' or trigger_count=TRIGGER_COUNT_MAX-1 then
                            trigger_active <= '0';
                        end if;
                    else
                        trigger_counter <= trigger_counter + 1;
                        fifo_rd_en_STDP <= '0';
                    end if;
                else
                    trigger_pulse <= '0';
                    fifo_rd_en_STDP <= '0';
                end if;
            else
                fifo_rd_en_STDP <= '0';
                begin_trigger <= '0';
                
            end if;
        end if;
    end process;

process_read_STDP_fifo: process(clk)
    begin
        if rising_edge(clk) then
            if W_EN_STDP_FLAG_INT='1' then
                W_EN_STDP_FLAG<='1';
                W_EN_STDP_FLAG_INT<='0';
                DATA_OUT_STDP_FLAG<=fifo_STDP_OUT;
            elsif fifo_rd_en_STDP='1' then
                W_EN_STDP_FLAG_INT<='1';
            else
                W_EN_STDP_FLAG<='0';
                W_EN_STDP_FLAG_INT<='0';
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

fifo_Spike_Tx : fifo_generator_2
	PORT MAP(
		clk => CLK, 
		srst => fifo_STDP_srst, 
		din => fifo_STDP_IN, 
		wr_en => fifo_wr_en_STDP, 
		rd_en => fifo_rd_en_STDP, 
		dout => fifo_STDP_OUT, 
		full => fifo_STDP_full, 
		empty => fifo_STDP_empty 
--		data_count => fifo_Isyn_data_count_FF
	);
end Behavioral;

--WRITE_EN_STATIC <= data_flag;
--WRITE_EN_DYNAMIC <= en_dynamic;
--WRITE_EN_JTAG <= en_JTAG;
--process_update_array: process(clk)
--begin
--    if(rising_edge(CLK)) then
--        if(update_time_flag='1' and en_Input='1'and FIFO_full/='1') then
--            NI<=Dout_FIFO(15 downto 0);
--            FIFO_rd_en <='1';
--            Din_FIFO<=NI_ST;
--            FIFO_wr_en <='1';
--        elsif(update_time_flag='1' and FIFO_full/='1') then --starts from here (Ash-1)
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


--process_trigger_pattern: process(clk)--VERIFY IF THIS IS NEEDED.
--begin
--    if(rising_edge(CLK)) then
--        if(start_PATTERN='1' and Counter_clk_int-Counter_clk_prev_int>=Dout_FIFO_int and en_Pattern_flag='1' and FIFO_empty/='1' and FIFO_rd_en/='1' and Counter_clk<Counter_clk_MAX) then --Spike_time_array(0)/=0
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

--process_check_pattern_write: process(clk)
--begin
--    if(rising_edge(CLK)) then
--        if(Pattern_done_flag='1') then
--            start_PATTERN<='0';
--        elsif(FIFO_almost_empty/='1') then
--            start_PATTERN<='1'; --(Ash-2)
--        end if;
--    end if;
--end process;
------------------------------------------------------
-- Model: The NeuroCOreX Engine (CLIF + STDP) 

------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NEUROCORE_ENGINE is
PORT(
    clk : IN STD_LOGIC;
    clk100M: IN STD_LOGIC;
    en_Input: IN STD_LOGIC;
    NA_weight_loader: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    TRIGER :  IN STD_LOGIC;
    ACT_TRIGER : IN STD_LOGIC;
    PORT_Spike_in : IN STD_LOGIC;
    PORT_Neuron_Addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    PORT_Isyn_in : IN SIGNED(17 DOWNTO 0);
    PORT_Isyn_in_FF : IN SIGNED(17 DOWNTO 0);
    PORT_Iin : IN SIGNED(17 DOWNTO 0);
    PORT_vin : IN SIGNED(17 DOWNTO 0);
--    PORT_vthr_in : IN SIGNED(17 DOWNTO 0);
--    PORT_vtheta_in : IN SIGNED(17 DOWNTO 0);
--    PORT_tcount_in: IN SIGNED(17 DOWNTO 0);
    PORT_Weight_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    PORT_Weight_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    PORT_Param_in : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    PORT_STDP_Data_flag : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    En_Weight_AA: IN STD_LOGIC;
    En_READ_AA_W: IN STD_LOGIC;
    En_Weight_FF: IN STD_LOGIC;
    En_Param_Load: IN STD_LOGIC;
    En_STDP_Data_Flag: IN STD_LOGIC;
    En_READ_WEIGHT: IN STD_LOGIC;
    PORT_vout : OUT SIGNED(17 DOWNTO 0);
    PORT_ILA_DEBUG: OUT SIGNED (7 DOWNTO 0);
    PORT_WEIGHT_AA_TX: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    PORT_WRITE_WEIGHT_AA_Tx: OUT STD_LOGIC;
--    PORT_vthr_out : OUT SIGNED(17 DOWNTO 0);
--    PORT_vtheta_out : OUT SIGNED(17 DOWNTO 0);
--    PORT_tcount_out: OUT SIGNED(17 DOWNTO 0);
    PORT_Isyn_out : OUT SIGNED(17 DOWNTO 0);
    PORT_Isyn_out_FF : OUT SIGNED(17 DOWNTO 0);
    PORT_Spike_out : OUT STD_LOGIC;
    PORT_flag_READ_DONE : OUT STD_LOGIC
);
end NEUROCORE_ENGINE;

architecture Behavioral of NEUROCORE_ENGINE is
    component weight_ram is
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
    end component;
    
    component weight_ram_FF is
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
    end component;    
 
     component tpre_ram is
        Port (
        clk        : in  std_logic;
        we         : in  std_logic;
        write_addr : in  unsigned(15 downto 0); -- enough bits for 16K words
        data_in    : in  signed(7 downto 0);
        read_addr  : in  unsigned(15 downto 0);
        data_out   : out signed(7 downto 0)
        );
    end component;
  
     component apre_ram is
        Port (
        clk        : in  std_logic;
        we         : in  std_logic;
        write_addr : in  unsigned(15 downto 0); -- enough bits for 16K words
        data_in    : in  signed(1 downto 0);
        read_addr  : in  unsigned(15 downto 0);
        data_out   : out signed(1 downto 0)
        );
    end component;   
                       
     component stdp_enable_ram is
        Port (
        clk        : in  std_logic;
        we         : in  std_logic;
        write_addr : in  unsigned(15 downto 0); -- enough bits for 16K words
        data_in    : in  std_logic;
        read_addr  : in  unsigned(15 downto 0);
        data_out   : out std_logic
        );
    end component;
    SIGNAL flag_check : STD_LOGIC:='0';
    
    ---FOR MICROSEER, actual number of neurons=90, which was 14
    CONSTANT N2 : NATURAL := 95; --19;95 --Maximum number of input neurons (14+5)
    CONSTANT N1 : NATURAL := 95; --19;95 --Maximum number of Neurons in network
    CONSTANT N0 : NATURAL := 0;
    SIGNAL Sin, Sin_prev, Sin_1st, Sin_2nd : STD_LOGIC := '0'; --Intermediate signals for pipelining the input spikes
    SIGNAL Sin_latch: STD_LOGIC:='0';
    SIGNAL Sin_internal, Sin_internal_1st, Sin_internal_2nd : SIGNED(7 DOWNTO 0) := (OTHERS => '0');--Intermediate signals for pipelining the network spikes
    SIGNAL Iin : SIGNED(17 DOWNTO 0) := (OTHERS => '0');--Iin/Cmem
    SIGNAL Isyn_in, Isyn_in_FF : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Isyn_out, Isyn_out_FF : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL V_by_Tau_dt : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Isyn_by_Tau_dt,Isyn_FF_by_Tau_dt : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Syn_amp : SIGNED(20 DOWNTO 0) := "000000000000000000001";--The constant scaling factor for synapses in network
    SIGNAL Syn_amp_FF : SIGNED(20 DOWNTO 0) := "000000000000000001001";--"000000000000000001010". The constant scaling factor for input synapses to the network
    SIGNAL temp_result_vin : signed(35 downto 0):= (OTHERS => '0');
    SIGNAL temp_result_Isyn, temp_result_Isyn_FF : signed(35 downto 0):= (OTHERS => '0');
    SIGNAL current_neuron_index : SIGNED(15 downto 0) := (OTHERS => '0');
        
    SIGNAL vin : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vin_2nd : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vout : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vreset : SIGNED(17 DOWNTO 0) := (OTHERS => '0'); 
    
--    CONSTANT fixed_point_constant_vin : signed(17 downto 0) := to_signed(152, 18);  -- 0.1 in Q7.10 format, 00066
    SIGNAL fixed_point_constant_vin : signed(17 downto 0) := to_signed(152, 18);  -- 0.1 in Q7.10 format, 00066
    CONSTANT fixed_point_constant_Isyn : signed(17 downto 0) := to_signed(1024, 18);  -- 1 in Q7.10 format
    SIGNAL w_comb, w_comb_FF : SIGNED(14 downto 0):= (OTHERS => '0');--weight for current calculation, needs more bits to account for sum of 100 weights
    SIGNAL mul_result, mul_result_FF : SIGNED(35 downto 0):= (OTHERS => '0'); -- Signal to hold multiplication result
    SIGNAL mul_result_2, mul_result_2_FF : SIGNED(17 downto 0):= (OTHERS => '0'); -- Signal to hold multiplication result
                
    SIGNAL Vout_int : INTEGER:=0;
    SIGNAL Vin_int, tpre_read_addr_int, lat_read_addr_int : INTEGER:=0;
    SIGNAL Vin_2nd_int : INTEGER:=0;
    SIGNAL V_by_Tau_dt_int : INTEGER:=0;
    SIGNAL Isyn_in_int : INTEGER:=0;
    SIGNAL Isyn_out_int : INTEGER:=0;
    SIGNAL Isyn_by_Tau_dt_int : INTEGER:=0;
    SIGNAL current_neuron_index_int :INTEGER:=0;    
    SIGNAL NA, NA_loader : INTEGER:=0;
 
    TYPE spikes_lateral is array (0 to N1) of SIGNED(7 downto 0);--gautam
    SIGNAL spikes_L, spikes_L_prev : spikes_lateral := (others => (others => '0'));
    signal ram : spikes_lateral:= (others => (others => '0'));
    TYPE Neuron_parameters is array (0 to N1) of SIGNED(17 downto 0);
    SIGNAL vthr_in : Neuron_parameters :=  (others =>"000000001000000000");--(others =>"000000001000000001");
    SIGNAL T_ref_ctr: Neuron_parameters :=  (others =>"000000000000000000");--(others =>"000000001000000001");
    SIGNAL Tref_max: Neuron_parameters :=  (others =>"000000000000000100");--(others =>"000000001000000001");
    SIGNAL tau_mem: Neuron_parameters :=  (others =>"000000000000000000");
    SIGNAL stdp_params: Neuron_parameters :=  (others =>"000000000000000000");
--    SIGNAL Tref_max : SIGNED(17 downto 0):="000000000000000010";
    SIGNAL thr_index : INTEGER range 0 to N1 := 0;
    SIGNAL param_phase : INTEGER range 0 to 3 := 0; -- 0: vthr, 1: tref, 2: taumem
    TYPE weight_matrix is array (0 to N1) of SIGNED(14 downto 0);--weight
    SIGNAL weight, weight_FF : weight_matrix := (others => (others => '0'));
    SIGNAL weight_prev, weight_FF_prev : weight_matrix := (others => (others => '0'));

--RECTANGULAR STDP learning parameters
    TYPE STDP_STATE is array (0 to N1) of STD_LOGIC;
    SIGNAL apost, apost_dummy : STDP_STATE := (others => '0');
    SIGNAL apost_read_data_FF: STD_LOGIC:= '0';
    SIGNAL tpost, tpost_dummy : spikes_lateral := (others => (others => '1'));
    SIGNAL delta_w_pos, delta_w_neg : SIGNED(7 DOWNTO 0) := "00000001";
    TYPE STDP_UPDATED is array (0 to N1+1) of STD_LOGIC;
    SIGNAL updated_weights, updated_weights_FF : STDP_UPDATED := (others => '0');--To remember which weights need to be updated in AA matrix, updated_weights_FF unused yet.
--FF_accumulation: To read weights from BRAM for calculation    
    signal port_spike_out_prev, Spike_out, port_spike_in_prev: std_logic := '0';
    SIGNAL row_index, row_index_FF, row_index_read_AA, row_index_tpre : INTEGER RANGE 0 TO N1+1 := 0;  -- Row selector
    SIGNAL col_index, col_index_FF, col_index_read_AA, col_index_tpre  : INTEGER RANGE 0 TO N1+1 := 0;  -- Column selector
    signal acc_index          : integer range 0 to N1+1 := 0;    
    signal accumulation_done  : std_logic := '1';
    signal bram_addr, weight_FF_write_addr : unsigned(15 downto 0); -- adjust width as needed, read address of FF_weight matrix 
    signal bram_data, weight_FF_data_in  : signed(7 downto 0);  -- data output from BRAM, the read data  
    signal weight_FF_we : std_logic :='0';      
-- AA_accumulation: To read weights from BRAM for calculation    
    signal lat_acc_index          : integer range 0 to N1+1 := 0;
    signal lat_accumulation_done  : std_logic := '1';
    signal lat_bram_addr, weight_AA_write_addr, lat_bram_addr_read_W : unsigned(15 downto 0):=(others=>'0');  -- adjust width to cover (N1+1)*(N1+1) words
    signal lat_bram_data, weight_AA_data_in  : signed(7 downto 0);       -- data from BRAM
    signal weight_AA_data_out : std_logic_vector(7 downto 0):=(others=>'0');
    signal weight_AA_we : std_logic :='0';
--    signal bram_data_prev : signed(7 downto 0);  -- Pipeline register for previous BRAM data
    signal clk_delayed : std_logic :='0';
    signal multiple_spike_counter, multiple_spike_counter_FF : std_logic_vector(10 downto 0):=(others=>'0');
    signal multiple_spike_counter_max, multiple_spike_counter_max_FF : std_logic_vector(10 downto 0):= "01111101000";
    signal flag_multiple_spike_counter, flag_trig_counter, flag_multiple_spike_counter_FF, flag_trig_counter_FF : std_logic :='0';
    signal multiple_no_spike_counter, multiple_no_spike_counter_FF : std_logic_vector(10 downto 0):=(others=>'0');
    signal multiple_no_spike_counter_max, multiple_no_spike_counter_max_FF : std_logic_vector(10 downto 0):= "01111101000";
    signal flag_multiple_no_spike_counter, flag_trig_no_spike_counter, flag_missed_tpre_increment, flag_multiple_no_spike_counter_FF, flag_trig_no_spike_counter_FF, flag_missed_tpre_increment_FF : std_logic :='0';
--    signal flag_missed_tpre_increment_trigger : std_logic :='1';
    
    --STDP with BRAM--
    signal lat_update_index        : integer range N0 to N1+1 := N0;
    signal lat_update_done         : std_logic := '1';
    signal lat_read_addr, FF_read_addr : unsigned(15 downto 0); -- Adjust based on memory depth
    signal lat_read_data,lat_read_data_prev, FF_read_data : signed(7 downto 0);
--    signal lat_write_addr          : unsigned(15 downto 0);
--    signal lat_write_data          : signed(7 downto 0);
--    signal lat_we                  : std_logic;
    signal lat_update_active       : std_logic := '0';
    signal toggle_write, toggle_write_next, toggle_write_FF : std_logic := '0';  -- Toggle between original and transposed writes
    
    signal tpre_read_addr, apre_read_addr, tpre_read_addr_FF, apre_read_addr_FF   : unsigned(15 downto 0);  -- Adjust based on memory depth
    signal tpre_write_addr, tpre_write_addr_FF  : unsigned(15 downto 0);
    signal tpre_read_data, tpre_read_data_FF   : signed(7 downto 0);
    signal tpre_write_data, tpre_write_data_FF   : signed(7 downto 0);
    signal apre_write_data, apre_read_data, apre_write_data_FF, apre_read_data_FF    : signed(1 downto 0);
    signal tpre_we, tpre_we_FF, apre_we_FF         : std_logic;
    signal tpre_rule, tpost_rule : signed(7 downto 0);
--    signal apre_we          : std_logic;
--    signal apre_write_data  : std_logic;
    signal tpre_update_index, tpre_update_index_FF, FF_update_index : integer range N0 to N1+1 := N0;
    signal update_active, update_active_FF, FF_update_active    : std_logic := '0';
    signal update_done, update_done_FF, FF_update_done      : std_logic := '1';
    signal en_tpre_update, en_tpre_update_FF    : std_logic := '0';
    signal en_tpre_update_prev, en_tpre_update_prev_FF   : std_logic := '0';
    signal start_flag : std_logic := '0';  -- Output signal that stays high after first trigger
    signal trigger_seen : std_logic := '0'; -- Internal flag to track first detection
    type loader_state is (init_weight, stdp_update, read_weight);
    signal loader_status : loader_state := init_weight;
    signal tpre_FF_max, tpost_FF_max, tpre_AA_max, tpost_AA_max : signed(7 downto 0):="01111111"; 
    signal skip_flag, skip_flag_once : std_logic :='0';
    signal counter_skip_flag : std_logic_vector(9 downto 0) := (others=>'0');
    signal stdp_enable_we_FF, stdp_enable_we_AA : std_logic :='0';
    signal stdp_enable_write_addr_FF, stdp_enable_write_addr_AA : unsigned(15 downto 0);
    signal stdp_enable_write_data_FF, stdp_enable_write_data_AA : std_logic;
    signal stdp_enable_read_addr_FF, stdp_enable_read_addr_AA : unsigned(15 downto 0);
    signal stdp_enable_read_data_FF, stdp_enable_read_data_AA : std_logic;
    SIGNAL All_Zeros : SIGNED(17 DOWNTO 0) := "000000000000000000";
    SIGNAL write_weight_AA_Tx: std_logic:='0';
    SIGNAL BYTE_WEIGHT_BEGIN: std_logic_vector(7 downto 0):="11101110";
    SIGNAL read_AA_begin, first_read, last_read:  std_logic:='0';
    SIGNAL flat_index_read : integer range 0 to 100000;
        
    -- Parameters
    constant CLOCKS_PER_TRIGGER : integer := 2100;  -- 11 us at 100 MHz
--    constant N1 : integer := 19;  -- for example
    constant TRIGGER_COUNT_MAX : integer := (N1 + 1) * (N1 + 1);  -- 400 for N1=19
    
    -- Signals
    signal trigger_counter : integer range 0 to CLOCKS_PER_TRIGGER := 0;
    signal trigger_count   : integer range 0 to TRIGGER_COUNT_MAX := 0;
    signal trigger_active  : std_logic := '0';
    signal trigger_pulse   : std_logic := '0';
    signal En_Read_weight_last : std_logic := '0';  -- for edge detection
    type read_state_type is (WAIT_TRIGGER, WAIT_ADRS, WAIT_DATA);
    signal read_state : read_state_type := WAIT_TRIGGER;
    signal ctr_wait_adrs : integer range 0 to 4 := 0;
    signal flag_READ_DONE   : std_logic := '0';
    -- Signals STDP FLAG
    signal bit_count       : integer range 0 to 7 := 0;
    signal byte_buffer     : std_logic_vector(7 downto 0) := (others => '0');
    signal write_index     : unsigned (15 downto 0) := (others => '0');
    signal loading         : std_logic := '0';


BEGIN
--    PORT_ILA_DEBUG <= current_neuron_index(7 downto 0);
--    PORT_ILA_DEBUG <= mul_result_2_FF(7 downto 0);
    PORT_ILA_DEBUG(0) <= Sin;
    PORT_ILA_DEBUG(1) <= Sin_prev;
    PORT_ILA_DEBUG(2) <= Sin_1st;
    PORT_ILA_DEBUG(3) <= Sin_2nd;
    PORT_ILA_DEBUG(7 downto 4)<=w_comb_FF(3 downto 0);
    PORT_WEIGHT_AA_TX<=weight_AA_data_out;
    PORT_WRITE_WEIGHT_AA_Tx<=write_weight_AA_Tx;
    PORT_flag_READ_DONE<=flag_READ_DONE;
    fixed_point_constant_vin<=tau_mem(8);
    Syn_amp_FF(7 downto 0)<=Tref_max(0)(7 downto 0);
    tpre_rule<=stdp_params(0)(7 downto 0);
    tpre_FF_max<=stdp_params(0)(7 downto 0);
    tpost_rule<=stdp_params(1)(7 downto 0);
    tpost_FF_max<=stdp_params(0)(15 downto 8);
    tpre_AA_max<=stdp_params(1)(7 downto 0);
    tpost_AA_max<=stdp_params(1)(15 downto 8);
    delta_w_pos<=stdp_params(2)(7 downto 0);
    delta_w_neg<=stdp_params(2)(15 downto 8);
    
    FF_weight_ram : weight_ram_FF
    PORT MAP (
        clk => clk100M,
        we  => weight_FF_we,
        write_addr => weight_FF_write_addr,
        data_in => weight_FF_data_in,
        read_addr => bram_addr,
        data_out => bram_data,
        read_addr_STDP => FF_read_addr,
        data_out_STDP => FF_read_data
        );
        
    AA_weight_ram : weight_ram
    PORT MAP (
        clk => clk100M,
        we  => weight_AA_we,
        write_addr => weight_AA_write_addr,
        data_in => weight_AA_data_in,
        read_addr => lat_bram_addr,
        data_out => lat_bram_data,
        read_addr_STDP => lat_read_addr,
        data_out_STDP => lat_read_data
        );
    tpre_ram_AA : tpre_ram
    PORT MAP (
        clk => clk100M,
        we  => tpre_we,
        write_addr => tpre_write_addr,
        data_in => tpre_write_data,
        read_addr => tpre_read_addr,
        data_out => tpre_read_data
        );       

    apre_ram_AA : apre_ram
    PORT MAP (
        clk => clk100M,
        we  => tpre_we,
        write_addr => tpre_write_addr,
        data_in => apre_write_data,
        read_addr => apre_read_addr,
        data_out => apre_read_data
        );
            
    tpre_ram_FF : tpre_ram
    PORT MAP (
        clk => clk100M,
        we  => tpre_we_FF,
        write_addr => tpre_write_addr_FF,
        data_in => tpre_write_data_FF,
        read_addr => tpre_read_addr_FF,
        data_out => tpre_read_data_FF
        );       

    apre_ram_FF : apre_ram
    PORT MAP (
        clk => clk100M,
        we  => apre_we_FF,
        write_addr => tpre_write_addr_FF,
        data_in => apre_write_data_FF,
        read_addr => apre_read_addr_FF,
        data_out => apre_read_data_FF
        );
    stdp_enable_ram_AA : stdp_enable_ram
    PORT MAP (
        clk => clk100M,
        we  => stdp_enable_we_AA,
        write_addr => stdp_enable_write_addr_AA,
        data_in => stdp_enable_write_data_AA,
        read_addr => stdp_enable_read_addr_AA,
        data_out => stdp_enable_read_data_AA
        );        

    stdp_enable_ram_FF : stdp_enable_ram
    PORT MAP (
        clk => clk100M,
        we  => stdp_enable_we_FF,
        write_addr => stdp_enable_write_addr_FF,
        data_in => stdp_enable_write_data_FF,
        read_addr => stdp_enable_read_addr_FF,
        data_out => stdp_enable_read_data_FF
        ); 


    process_stdp_flag_read: process(clk100M)
    begin
        if rising_edge(clk100M) then
            case loader_status is
                when init_weight =>
    
                    -- Capture new data
                    if En_STDP_Data_Flag = '1' then
                        byte_buffer <= PORT_STDP_Data_flag;
                        bit_count <= 0;
                        loading <= '1';
                    end if;
    
                    if loading = '1' then
                        -- First fill AA BRAM
                        if write_index < (N1+1)*(N1+1) then
                            stdp_enable_we_AA <= '1';
                            stdp_enable_write_data_AA <= byte_buffer(7 - bit_count); -- MSB first
                            stdp_enable_write_addr_AA <= write_index;
                            stdp_enable_we_FF <= '0'; -- Disable FF writing
                        -- Then fill FF BRAM
                        else
                            stdp_enable_we_AA <= '0'; -- Disable AA writing
                            stdp_enable_we_FF <= '1';
                            stdp_enable_write_data_FF <= byte_buffer(7 - bit_count);
                            stdp_enable_write_addr_FF <= write_index - (N1+1)*(N1+1); -- Address starts from 0 again for FF
                        end if;
    
                        write_index <= write_index + 1;
                        bit_count <= bit_count + 1;
    
                        if bit_count = 7 then
                            loading <= '0'; -- Finished current byte
                        end if;
                    else
                        -- Not loading, keep both write enables low
                        stdp_enable_we_AA <= '0';
                        stdp_enable_we_FF <= '0';
                    end if;
    
                when others =>
                    write_index <= (others => '0');
                    stdp_enable_we_AA <= '0';
                    stdp_enable_we_FF <= '0';
            end case;
        end if;
    end process;
    
           
    Core_run_start: process(clk)
    begin
        if rising_edge(clk) then
            if TRIGER = '1' and trigger_seen = '0' then
                start_flag <= '1';  -- Set flag when TRIGER goes high for the first time
                trigger_seen <= '1'; -- Remember that TRIGER has been seen
                loader_status<=stdp_update;
            elsif ACT_TRIGER='0' and trigger_seen = '1' then
                start_flag <= '0';
                loader_status<=init_weight;
                trigger_seen <= '0';
            elsif En_READ_WEIGHT='1' then
                loader_status<=read_weight;
            elsif En_READ_WEIGHT='0' and trigger_seen = '0' and ACT_TRIGER='0' then
                loader_status<=init_weight;      
            end if;
        end if;
    end process; 
------------------Reading the weights from BRAM with weights for feedforward network while SNN emulation-------------   
------------------When loader_status=read_weight, it is used to read the weights from BRAM back to PC--------------------------   
    accumulation_process : process(clk100M)
    begin
      if rising_edge(clk100M) then
      
        -- When en_input goes high, start a new accumulation cycle
        clk_delayed <= clk;
        case loader_status is
            when read_weight =>
                case read_state is
                    when WAIT_TRIGGER =>
                        write_weight_AA_Tx <= '0';
                        if trigger_pulse = '1' then
                            -- Compute and store index
    --                                next_flat_index := row_index_read_AA * (N1 + 1) + col_index_read_AA;
                            flat_index_read <= row_index_read_AA * (N1 + 1) + col_index_read_AA; -- latch index for next cycle
                            read_state <= WAIT_ADRS;
        
                            -- Update indices
                            if col_index_read_AA < N1 then
                                col_index_read_AA <= col_index_read_AA + 1;
                            else
                                col_index_read_AA <= 0;
                                if row_index_read_AA < N1 then
                                    row_index_read_AA <= row_index_read_AA + 1;
                                else
                                    row_index_read_AA <= 0;  -- wrap around
                                end if;
                            end if;
                        end if;
                    -- Phase 2: Apply index to BRAM, send data after read delay
                    when WAIT_ADRS =>
                        bram_addr <= to_unsigned(flat_index_read, bram_addr'length); -- now one cycle late
    --                            weight_AA_data_out <= std_logic_vector(lat_bram_data);  -- read BRAM output
    --                            write_weight_AA_Tx <= '1';  -- trigger UART Tx
                        ctr_wait_adrs<=ctr_wait_adrs+1;
                        if ctr_wait_adrs=1 then
                            read_state <= WAIT_DATA;
                            ctr_wait_adrs<=0;
                        else 
                            read_state<=WAIT_ADRS;
                        end if;
                    when WAIT_DATA =>
    --                            lat_bram_addr <= to_unsigned(flat_index_read, lat_bram_addr'length); -- now one cycle late
                        weight_AA_data_out <= std_logic_vector(bram_data);  -- read BRAM output
                        write_weight_AA_Tx <= '1';  -- trigger UART Tx
                        read_state <= WAIT_TRIGGER;
                    when others =>
                        null;
                end case;
                                              
            when stdp_update =>
                if en_input = '1' then --ashish verify  and ACT_TRIGER='1'
                  acc_index <= 0;
                  accumulation_done <= '0';
                  bram_addr <= to_unsigned(0 * (N1 + 1) + NA_loader, bram_addr'length); -- First address setup
                elsif accumulation_done = '0' then  -- Active accumulation phase
                
                  -- Accumulate previously read value (after BRAM read latency)
                  if acc_index > 0 then
                    weight_FF(acc_index - 1) <= weight_FF(acc_index - 1) + resize(bram_data, weight_FF(acc_index - 1)'length);
                  elsif acc_index=N1+1 then
                    weight_FF(N1) <= weight_FF(N1) + resize(bram_data, weight_FF(N1)'length);
                  end if;
            
                  -- Move to the next index or finish
                  if acc_index < N1 then
                    acc_index <= acc_index + 1;
                    bram_addr <= to_unsigned((acc_index + 1) * (N1 + 1) + NA_loader, bram_addr'length); -- Next address
                  elsif acc_index=N1 then
                    bram_addr <= to_unsigned((acc_index) * (N1 + 1) + NA_loader, bram_addr'length); -- Next address
                    acc_index <= acc_index + 1;
                  else
                    -- Last index case
                    acc_index <= 0; -- Reset index
                    accumulation_done <= '1';
                  end if;
            
                end if;
            
                -- Reset weights when processing the last neuron
                if current_neuron_index_int = N1 and (clk = '1' and clk_delayed = '0') then
                  weight_FF_prev<= weight_FF;
                  weight_FF <= (others => (others => '0'));
                elsif ACT_TRIGER='0' then --Ashish verify
                  weight_FF_prev<= (others => (others => '0'));
                  weight_FF <= (others => (others => '0'));      
                end if;
            when others =>
                null;
        end case;
        
          end if;
    end process;

    process(clk100M)
    begin
        if rising_edge(clk100M) then
    
            -- Edge detect En_Read_weight rising edge
            if En_Read_weight = '1' and En_Read_weight_last = '0' then
                trigger_active <= '1';
                trigger_count <= 0;
                trigger_counter <= 0;
--                flag_READ_DONE<='0';
            end if;
    
            En_Read_weight_last <= En_Read_weight;
    
            if trigger_active = '1' then
                if trigger_counter = CLOCKS_PER_TRIGGER - 1 then
                    trigger_counter <= 0;
                    trigger_pulse <= '1';
                    trigger_count <= trigger_count + 1;
    
                    if trigger_count = TRIGGER_COUNT_MAX - 1 then
                        trigger_active <= '0';
                        flag_READ_DONE<='1';
                    end if;
                else
                    trigger_counter <= trigger_counter + 1;
                    trigger_pulse <= '0';
                end if;
            else
                trigger_pulse <= '0';
                flag_READ_DONE<='0';
            end if;
    
        end if;
    end process;

------------------Reading the weights from BRAM with weights for all-to-all connected network while SNN emulation-------------   
------------------When loader_status=read_weight, it is used to read the weights from BRAM back to PC--------------------------
    lat_accumulation_process : process(clk100M)
--    variable flat_index_read : integer range 0 to 1023;
    begin
      if rising_edge(clk100M) then
            case loader_status is
--                when read_weight =>
--                    case read_state is
--                        when WAIT_TRIGGER =>
--                            write_weight_AA_Tx <= '0';
--                            if trigger_pulse = '1' then
--                                -- Compute and store index
----                                next_flat_index := row_index_read_AA * (N1 + 1) + col_index_read_AA;
--                                flat_index_read <= row_index_read_AA * (N1 + 1) + col_index_read_AA; -- latch index for next cycle
--                                read_state <= WAIT_ADRS;
            
--                                -- Update indices
--                                if col_index_read_AA < N1 then
--                                    col_index_read_AA <= col_index_read_AA + 1;
--                                else
--                                    col_index_read_AA <= 0;
--                                    if row_index_read_AA < N1 then
--                                        row_index_read_AA <= row_index_read_AA + 1;
--                                    else
--                                        row_index_read_AA <= 0;  -- wrap around
--                                    end if;
--                                end if;
--                            end if;
--                        -- Phase 2: Apply index to BRAM, send data after read delay
--                        when WAIT_ADRS =>
--                            lat_bram_addr <= to_unsigned(flat_index_read, lat_bram_addr'length); -- now one cycle late
----                            weight_AA_data_out <= std_logic_vector(lat_bram_data);  -- read BRAM output
----                            write_weight_AA_Tx <= '1';  -- trigger UART Tx
--                            ctr_wait_adrs<=ctr_wait_adrs+1;
--                            if ctr_wait_adrs=1 then
--                                read_state <= WAIT_DATA;
--                                ctr_wait_adrs<=0;
--                            else 
--                                read_state<=WAIT_ADRS;
--                            end if;
--                        when WAIT_DATA =>
----                            lat_bram_addr <= to_unsigned(flat_index_read, lat_bram_addr'length); -- now one cycle late
--                            weight_AA_data_out <= std_logic_vector(lat_bram_data);  -- read BRAM output
--                            write_weight_AA_Tx <= '1';  -- trigger UART Tx
--                            read_state <= WAIT_TRIGGER;
--                        when others =>
--                            null;
--                        end case;
                                          
                when stdp_update =>                 
                    port_spike_out_prev <= Spike_out;
                    
                    if multiple_spike_counter=multiple_spike_counter_max then
                        multiple_spike_counter<=(others=>'0');
                        flag_multiple_spike_counter<='1';        
                    elsif flag_trig_counter='1' or multiple_spike_counter>0 then
                        multiple_spike_counter<=multiple_spike_counter+1;
                        flag_multiple_spike_counter<='0';
                    else
                        flag_multiple_spike_counter<='0';
                    end if;
                    
                    -- Detect rising edge of Port_Spike_out
                    if (port_spike_out_prev = '0' and Spike_out = '1') or (flag_multiple_spike_counter='1' and Spike_out = '1')then
                      lat_acc_index         <= 0;
                      lat_accumulation_done <= '0';
                      flag_trig_counter <= '1';
                      lat_bram_addr <= to_unsigned(lat_acc_index * (N1+1) + current_neuron_index_int, lat_bram_addr'length);
                    elsif lat_accumulation_done = '0' then
                      -- Set BRAM read address for current index.
                      -- Flattened address: lat_acc_index * (N1+1) + current_neuron_index_int
            --          lat_bram_addr <= to_unsigned(lat_acc_index * (N1+1) + current_neuron_index_int, lat_bram_addr'length);
                      
                      -- Because the BRAM read is synchronous, the data available in lat_bram_data
                      -- corresponds to the address set in the previous cycle.
                      if lat_acc_index > 0 then
                        -- Accumulate the previously read value for index (lat_acc_index-1),
                        -- but only if that index is not equal to current_neuron_index.
                        if (lat_acc_index - 1) /= current_neuron_index and current_neuron_index>4 and current_neuron_index<N1 then
                          weight(lat_acc_index - 1) <= weight(lat_acc_index - 1) + resize(lat_bram_data, weight(lat_acc_index - 1)'length);
                        elsif (lat_acc_index - 1) /= current_neuron_index and current_neuron_index=N1+1 then
                          weight(N1) <= weight(N1) + resize(lat_bram_data, weight(N1)'length);
                        end if;
                      end if;
                      
                      if lat_acc_index < N1 then
                        lat_acc_index <= lat_acc_index + 1;
                        lat_bram_addr <= to_unsigned((lat_acc_index+1) * (N1+1) + current_neuron_index_int, lat_bram_addr'length);
                      elsif lat_acc_index=N1 then
                        lat_bram_addr <= to_unsigned((lat_acc_index) * (N1 + 1) + current_neuron_index_int, lat_bram_addr'length); -- Next address
                        lat_acc_index <= lat_acc_index + 1;
                        -- For the final index, accumulate and mark the process as done.
                      else
                        lat_acc_index         <= 0;
                        lat_accumulation_done <= '1';
                      end if;
                    else
                      flag_trig_counter <= '0';
                    end if;
                    
                    IF current_neuron_index_int =N1  and (clk = '1' and clk_delayed = '0') then
                        weight_prev<= weight;
                        weight<=(others => (others => '0'));
                    end if;
                when others =>
                    null;
              end case;
          end if;
        end process;
        
    Neuron_param_loader : PROCESS(CLK100M)
    BEGIN
        IF rising_edge(CLK100M) THEN
            IF (En_Param_load = '1') THEN
                CASE param_phase IS
                    WHEN 0 =>  -- Load vthr_in
                        vthr_in(thr_index) <= signed(PORT_Param_in);
                    WHEN 1 =>  -- Load tref
                        Tref_max(thr_index) <= signed(PORT_Param_in);
                    WHEN 2 =>  -- Load tau_mem
                        tau_mem(thr_index) <= signed(PORT_Param_in);
                    WHEN 3 =>
                        stdp_params(thr_index) <= signed(PORT_Param_in);
                END CASE;
    
                -- Advance thr_index or phase
                IF thr_index < N1 THEN
                    thr_index <= thr_index + 1;
                ELSE
                    thr_index <= 0;
                    IF param_phase < 3 THEN
                        param_phase <= param_phase + 1;
                    ELSE
                        param_phase <= 0;  -- Reset after all params loaded
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

----------------------------------All to All INITIAL WEIGHT LOADER and WEIGHT UPDATES CALCULATIONS WHILE STDP-------------------
    AA_weight_loader : PROCESS(CLK100M)
--        variable toggle_write : std_logic := '0';  -- Toggle between original and transposed writes
        variable flat_index : integer range 0 to 100000;
        
    BEGIN
        IF rising_edge(CLK100M) THEN
            case loader_status is   
                when init_weight =>
                    IF (En_Weight_AA = '1') THEN
                        -- Compute the flat address from row_index and col_index
                        flat_index := row_index * (N1 + 1) + col_index;
                        -- Drive the weight_ram write interface
                        weight_AA_we         <= '1';
                        weight_AA_write_addr <= to_unsigned(flat_index, weight_AA_write_addr'length);
                        weight_AA_data_in    <= signed(PORT_Weight_AA);
            
                        -- Update indices (row and column counters)
                        IF col_index < N1 THEN
                            col_index <= col_index + 1;  -- Move to the next column in the same row
                        ELSE
                            col_index <= 0;              -- Reset column index for new row
                            IF row_index < N1 THEN
                                row_index <= row_index + 1; -- Move to the next row
                            ELSE
                                row_index <= 0;          -- Reset row index if all rows are filled
                            END IF;
                        END IF;
                    ELSE
                        weight_AA_we <= '0';  -- Ensure write enable is low when not writing
                        weight_AA_write_addr <= to_unsigned(0, weight_AA_write_addr'length);
                    END IF;
                when stdp_update =>
                    -- Detect the start of an update cycle
                    if ((port_spike_out_prev = '0' and Spike_out = '1') or 
                        (flag_multiple_spike_counter='1' and Spike_out = '1')) and 
                        (lat_update_done = '1') then --This might be incorrect and i might need seperate flags here
                        lat_update_index  <= N0;  -- Start iteration
                        lat_update_done   <= '0';
                        lat_update_active <= '1';
                        toggle_write      <= '0';  -- Start with original address
--                        toggle_write_next <= '0';
                    elsif toggle_write ='1' and lat_update_active ='0' then                
                      lat_update_index <= N0;
                      lat_update_active    <= '1';
                      lat_update_done      <= '0';
                    end if;
                    if lat_update_active = '1' then
                        -- Compute Read Address Based on Toggle Logic
                        if toggle_write = '0' and lat_update_index < N1 then
--                            lat_read_addr <= to_unsigned((lat_update_index+1) * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                            lat_read_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index), lat_read_addr'length);
                            apre_read_addr <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
--                            if lat_update_index>N0 then
                            stdp_enable_read_addr_AA<=to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index), weight_AA_write_addr'length);--Ashish added stdp_enable_read_data_AA='1'
--                            else
--                                stdp_enable_read_addr_AA<= to_unsigned(0 * (N1+1) + 0, stdp_enable_read_addr_AA'length);
--                            end if;
                        elsif toggle_write = '1' and lat_update_index <= N1 then
--                            lat_read_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index), lat_read_addr'length);
                            lat_read_addr <= to_unsigned((lat_update_index+1) * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                            apre_read_addr <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index), lat_read_addr'length);
--                            if lat_update_index>N0 then
                            stdp_enable_read_addr_AA<= to_unsigned((lat_update_index+1) * (N1+1) + current_neuron_index_int, weight_AA_write_addr'length);--Ashish added stdp_enable_read_data_AA='1'
--                            else
--                                stdp_enable_read_addr_AA<= to_unsigned(0 * (N1+1) + 0, stdp_enable_read_addr_AA'length);
--                            end if;
                        else
                            lat_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apre_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            stdp_enable_read_addr_AA<= to_unsigned(0 * (N1+1) + 0, stdp_enable_read_addr_AA'length);--Ashish added stdp_enable_read_data_AA='1'
                        end if;
                        lat_read_data_prev<=lat_read_data;
            
                        -- BRAM Read Pipeline: Apply Update after One Cycle
                        if lat_update_index > N0 then
--                            if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then--current_neuron_index_int-1?
                            if apre_read_data = "01" and toggle_write = '0' and stdp_enable_read_data_AA='1'then -- Ashish added stdp_enable_read_data_AA='1'
                                -- Read data from BRAM and add or subtract delta_w
                                -- Compute Write Address Based on Toggle Logic
--                                if toggle_write = '0' then
                                if (lat_read_data + delta_w_pos) > to_signed(127, 8) then
                                    weight_AA_data_in <= to_signed(127, 8);
                                else
                                    weight_AA_data_in <= lat_read_data + delta_w_pos;
                                end if; 
                                updated_weights(lat_update_index)<='1';
                                weight_AA_we <= '1'; -- Enable write
--                                weight_AA_write_addr <= to_unsigned((lat_update_index - 1) * (N1+1) + current_neuron_index_int, weight_AA_write_addr'length);
                                weight_AA_write_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index - 2), weight_AA_write_addr'length);--Use this when using updated_weights condition
                            elsif toggle_write = '1' and lat_update_index>N0+1 and stdp_enable_read_data_AA='1' then -- --Ashish added stdp_enable_read_data_AA='1'
                                if apost_dummy(lat_update_index-2)='1' and (lat_update_index-2)/=current_neuron_index_int then --and updated_weights(lat_update_index)='1'
                                    if (lat_read_data - delta_w_neg) < to_signed(-1, 8) then
                                        weight_AA_data_in <= to_signed(-1, 8);
                                    else
                                        weight_AA_data_in <= lat_read_data - delta_w_neg;
                                    end if;
                                    weight_AA_we <= '1'; -- Enable write
--                                    weight_AA_write_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index - 2), weight_AA_write_addr'length);--Use this when using updated_weights condition
                                    weight_AA_write_addr <= to_unsigned((lat_update_index - 1) * (N1+1) + current_neuron_index_int, weight_AA_write_addr'length);                                    
                                else
                                    weight_AA_we <= '0';
                                end if;
                            else
                                weight_AA_we <= '0'; -- No write
                            end if;
            
                                
--                                toggle_write <= not toggle_write; -- Toggle between original and transposed writes
--                            else
--                                weight_AA_we <= '0'; -- No write
--                            end if;
                                                    -- Iterate through indices
                            -- Move to the next index
                            if lat_update_index <= N1 then
                                lat_update_index <= lat_update_index + 1;
                            elsif Spike_out='1' and toggle_write='0' then
                                toggle_write<='1';
            --                    flag_missed_tpre_increment_trigger<='0';
                                lat_update_active <= '0';
                                lat_update_done <= '1';
                            else
                                lat_update_active <= '0';
                                lat_update_done <= '1';
                                toggle_write<='0';
                                updated_weights<=(others=>'0');--Check gautam
            --                    flag_missed_tpre_increment_trigger<='0';
                            end if;                                                    
--                            if toggle_write = '1' or (toggle_write = '0' and apre(lat_update_index-1)(current_neuron_index_int) = '0') then
--                            if toggle_write = '1' or (toggle_write = '0' and apre_read_data = "00") then
--                                if lat_update_index < N1 then
--                                    lat_update_index <= lat_update_index + 1; -- Increment regardless of writing
--                                else
--                                    lat_update_active <= '0'; -- Stop updates
--                                    lat_update_done   <= '1';
--                                end if;
--                            elsif apre_read_data = "01" then
--                                lat_update_index <= lat_update_index - 1;
--                            end if;
                        elsif lat_update_index = N0 then
                            lat_update_index <= lat_update_index + 1;
                        end if;
            

                    else
                        weight_AA_we <= '0'; -- Default to no write
                    end if;                                    
                when others =>
                    null;
            end case;
        END IF;
    END PROCESS;
----------------------------------FEED FOREWARD INITIAL WEIGHT LOADER and WEIGHT UPDATES CALCULATIONS WHILE STDP-------------------
    FF_weight_loader : PROCESS(CLK100M)
        variable flat_index_FF : integer range 0 to 100000;
--        variable toggle_write_FF : std_logic := '0';
    BEGIN
        IF rising_edge(CLK100M) THEN
            case loader_status is     
                when init_weight =>
                    IF (En_Weight_FF = '1') THEN
                        -- Compute the flat address from row_index and col_index
                        flat_index_FF := row_index_FF * (N1 + 1) + col_index_FF;
                        -- Drive the weight_ram write interface
                        weight_FF_we         <= '1';
                        weight_FF_write_addr <= to_unsigned(flat_index_FF, weight_FF_write_addr'length);
                        weight_FF_data_in    <= signed(PORT_Weight_FF);
            
                        -- Update indices (row and column counters)
                        IF col_index_FF < N1 THEN
                            col_index_FF <= col_index_FF + 1;  -- Move to the next column in the same row
                        ELSE
                            col_index_FF <= 0;              -- Reset column index for new row
                            IF row_index_FF < N2 THEN
                                row_index_FF <= row_index_FF + 1; -- Move to the next row
                            ELSE
                                row_index_FF <= 0;          -- Reset row index if all rows are filled
                            END IF;
                        END IF;
                    ELSE
                        weight_FF_we <= '0';  -- Ensure write enable is low when not writing
                        weight_FF_write_addr <= to_unsigned(0, weight_FF_write_addr'length);
                    END IF;
                when stdp_update =>
--                    -- Detect the start of an update cycle. I removed  "or (flag_multiple_spike_counter='1' and Spike_out = '1'))" 
                    if ((port_spike_in_prev = '0' and Port_Spike_in = '1')and (FF_update_done = '1')) then
                        FF_update_index  <= N0;  -- Start iteration
                        FF_update_done   <= '0';
                        FF_update_active <= '1';
                        toggle_write_FF      <= '1';  -- Start with original address
                    end if;
--                    port_spike_in_prev <= Port_Spike_in;
                    -- Detect the start of an update cycle
                    
                    if ((port_spike_out_prev = '0' and Spike_out = '1') or 
                        (flag_multiple_spike_counter='1' and Spike_out = '1')) and 
                        (FF_update_done = '1') then --This might be incorrect and i might need seperate flags here
                        FF_update_index  <= N0;  -- Start iteration
                        FF_update_done   <= '0';
                        FF_update_active <= '1';
                        toggle_write_FF      <= '0';  -- Start with original address
--                        toggle_write_next <= '0';
--                    elsif toggle_write ='1' and FF_update_active ='0' then                
--                      lat_update_index <= N0;
--                      lat_update_active    <= '1';
--                      lat_update_done      <= '0';
                    end if;
                    if FF_update_active = '1' then
                        -- Compute Read Address Based on Toggle Logic
                        if toggle_write_FF = '0' and FF_update_index < N1 then
                            FF_read_addr <= to_unsigned((FF_update_index) * (N1+1) + current_neuron_index_int, FF_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(FF_update_index * (N1+1) + current_neuron_index_int, apre_read_addr'length);
                            apost_read_data_FF <= '0';
                            stdp_enable_read_addr_FF<=to_unsigned(FF_update_index * (N1+1) + current_neuron_index_int, stdp_enable_read_addr_FF'length); --Ashish added stdp_enable_read_data_FF='1'
                        elsif toggle_write_FF = '1' and FF_update_index <= N1 and FF_update_index > N0 then
                            FF_read_addr <= to_unsigned((NA) * (N1+1) + (FF_update_index), FF_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apost_read_data_FF <=apost_dummy(FF_update_index-1);
                            stdp_enable_read_addr_FF<=to_unsigned((NA) * (N1+1) + (FF_update_index), stdp_enable_read_addr_FF'length); --Ashish added stdp_enable_read_data_FF='1'
--                            apre_read_addr_FF <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index), lat_read_addr'length);
                        else
                            FF_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            stdp_enable_read_addr_FF<=to_unsigned(0 * (N1+1) + 0, stdp_enable_read_addr_FF'length); --Ashish added stdp_enable_read_data_FF='1'
                        end if;
--                        FF_read_data_prev<=FF_read_data;
            
                        -- BRAM Read Pipeline: Apply Update after One Cycle
                        if FF_update_index > N0 then
--                            if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then--current_neuron_index_int-1?
                            if apre_read_data_FF = "01" and toggle_write_FF = '0' and stdp_enable_read_data_FF='1' then --Ashish added stdp_enable_read_data_FF='1'
                                -- Read data from BRAM and add or subtract delta_w
                                -- Compute Write Address Based on Toggle Logic
                                if (FF_read_data + delta_w_pos) > to_signed(127, 8) then
                                    weight_FF_data_in <= to_signed(127, 8);
                                else
                                    weight_FF_data_in <= FF_read_data + delta_w_pos;
                                end if; 
--                                updated_weights_FF(FF_update_index)<='1';
                                weight_FF_we <= '1'; -- Enable write
                                weight_FF_write_addr <= to_unsigned((FF_update_index - 2) * (N1+1) + current_neuron_index_int, weight_FF_write_addr'length);
                            elsif toggle_write_FF = '1' and apost_read_data_FF='1' and stdp_enable_read_data_FF='1' then --Ashish added stdp_enable_read_data_FF='1'
                                if (FF_read_data - delta_w_neg) < to_signed(-1, 8) then
                                    weight_FF_data_in <= to_signed(-1, 8);
                                else
                                    weight_FF_data_in <= FF_read_data - delta_w_neg;
                                end if;
                                weight_FF_we <= '1'; -- Enable write
                                weight_FF_write_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (FF_update_index - 2), weight_FF_write_addr'length);
                            else
                                weight_FF_we <= '0'; -- No write
                            end if;
            
                                
--                                toggle_write <= not toggle_write; -- Toggle between original and transposed writes
--                            else
--                                weight_FF_we <= '0'; -- No write
--                            end if;
                                                    -- Iterate through indices
                            -- Move to the next index
                            if FF_update_index <= N1 then
                                FF_update_index <= FF_update_index + 1;
                            elsif Spike_out='1' and toggle_write_FF='0' then
--                                toggle_write_FF<='1';
            --                    flag_missed_tpre_increment_trigger<='0';
                                FF_update_active <= '0';
                                FF_update_done <= '1';
                            else
                                FF_update_active <= '0';
                                FF_update_done <= '1';
--                                toggle_write_FF<='0';
                                updated_weights_FF<=(others=>'0');--Check gautam
            --                    flag_missed_tpre_increment_trigger<='0';
                            end if;                                                    
                        elsif FF_update_index = N0 then
                            FF_update_index <= FF_update_index + 1;
                        end if;
            

                    else
                        weight_FF_we <= '0'; -- Default to no write
                    end if;            
                when others =>
                    null;
                end case;
        END IF;
    END PROCESS;
    
    tpre_skip_flag_FF_tracker: process(clk100M)
    begin
        if rising_edge(clk100M) then
            if counter_skip_flag=1000 then
                skip_flag<='0';
                skip_flag_once<='1';
                counter_skip_flag<=counter_skip_flag+1;
            elsif flag_trig_counter_FF='1' then
                counter_skip_flag<= (others =>'0');
                skip_flag<='0';
                skip_flag_once<='0';
                
            elsif current_neuron_index_int=NA_loader and skip_flag_once ='0' and trigger_seen='1' then
                counter_skip_flag<=counter_skip_flag+1;
                skip_flag<='1';
            else 
                skip_flag <='0';
            end if;

        end if;
    end process;
----------------------------------TPRE CALCULATION FOR STDP UPDATES OF feedforward connected weights------------------
    tpre_updater_FF: process(clk100M)--seperate write needed for apre
    begin
        if rising_edge(clk100M) then
            port_spike_in_prev <= Port_Spike_in;
            
            if multiple_spike_counter_FF=multiple_spike_counter_max_FF then
                multiple_spike_counter_FF<=(others=>'0');
                flag_multiple_spike_counter_FF<='1';        
            elsif flag_trig_counter_FF='1' or multiple_spike_counter_FF>0 then
                multiple_spike_counter_FF<=multiple_spike_counter_FF+1;
                flag_multiple_spike_counter_FF<='0';
            else
                flag_multiple_spike_counter_FF<='0';
            end if;
    
            -- Start update cycle when triggered
            -- Detect rising edge of Port_Spike_out
            if ((en_tpre_update_prev_FF = '0' and en_tpre_update_FF = '1') or (flag_multiple_no_spike_counter_FF='1' and en_tpre_update_FF = '1')) and start_flag='1' then
              flag_trig_no_spike_counter_FF <= '1';
              tpre_update_index_FF <= N0;
              update_active_FF    <= '1';
              update_done_FF      <= '0';
            elsif((port_spike_in_prev = '0' and Port_Spike_in = '1') or 
                (flag_multiple_spike_counter_FF='1' and Port_Spike_in = '1')) then
--              flag_trig_no_spike_counter <= '1';
              tpre_update_index_FF <= N0;
              update_active_FF    <= '1';
              update_done_FF      <= '0';
              flag_trig_counter_FF <='1';
--              apre(current_neuron_index_int) <= (others => '1');--If this is not all to all connected use a for loop
--              apre(current_neuron_index_int)(current_neuron_index_int) <= '0';  -- Set the specific element to '0'
--              flag_missed_tpre_increment<= '1';
--              addr_missed_tpre_increment<= current_neuron_index_int;
            elsif flag_missed_tpre_increment_FF ='1' and update_active_FF ='0' then                
              tpre_update_index_FF <= N0;
              update_active_FF    <= '1';
              update_done_FF      <= '0';
--              flag_missed_tpre_increment<= '0';
--            elsif flag_missed_tpre_increment_trigger ='0' then
--                flag_missed_tpre_increment <='0';
--                flag_missed_tpre_increment_trigger <='1';
            else
              flag_trig_no_spike_counter_FF <= '0';
              flag_trig_counter_FF <='0';
            end if;
            en_tpre_update_prev_FF <= en_tpre_update_FF;
        
            if multiple_no_spike_counter_FF=multiple_spike_counter_max_FF then
                multiple_no_spike_counter_FF<=(others=>'0');
                flag_multiple_no_spike_counter_FF<='1';        
            elsif flag_trig_no_spike_counter_FF='1' or multiple_no_spike_counter_FF>0 then
                multiple_no_spike_counter_FF<=multiple_no_spike_counter_FF+1;
                flag_multiple_no_spike_counter_FF<='0';
            else
                flag_multiple_no_spike_counter_FF<='0';
            end if;
            
            
            if update_active_FF = '1' then
                -- Step 1: Set BRAM read address
                if Port_Spike_in='1' and tpre_update_index_FF <= N1 and flag_missed_tpre_increment_FF = '1' then
                    tpre_read_addr_FF <= to_unsigned(tpre_update_index_FF * (N1+1) + NA, tpre_read_addr_FF'length);--NA or current_neuron_index_int
                elsif Port_Spike_in='1' and tpre_update_index_FF <= N1 then
                    tpre_read_addr_FF <= to_unsigned(NA * (N1+1) + tpre_update_index_FF, tpre_read_addr_FF'length);
                elsif en_tpre_update_FF='1' and tpre_update_index_FF <= N1 then
                    tpre_read_addr_FF <= to_unsigned(tpre_update_index_FF * (N1+1) + current_neuron_index_int, tpre_read_addr_FF'length);
                elsif tpre_update_index_FF = N1+1 then
                    tpre_read_addr_FF <= to_unsigned(0 * (N1+1) + 0, tpre_read_addr_FF'length);
                    
                end if;
    
                -- Step 2: Process previous cycle’s data and update
--                if flag_missed_tpre_increment<= '1' then
--                    tpre_write_data <= tpre_read_data+1;
--                    tpre_write_addr <=tpre_read_addr;
--                    tpre_we <= '1'; -- Write enable tpre
                if tpre_update_index_FF > N0 and Port_Spike_in='1' and flag_missed_tpre_increment_FF= '0' then
                    tpre_write_data_FF <= (others => '0');
                    apre_write_data_FF <= "01";
--                    apre(current_neuron_index_int)(tpre_update_index-1)<='1';
                    tpre_write_addr_FF <=tpre_read_addr_FF;
                    tpre_we_FF <= '1'; -- Write enable tpre
                    apre_we_FF <= '1';
                elsif tpre_update_index_FF > (N0+1) then

                    if tpre_read_data_FF(7) = '0' and flag_missed_tpre_increment_FF= '1' and tpre_update_index_FF-2/=NA then
                        tpre_write_data_FF <= tpre_read_data_FF+1;--this should be ff
--                            apre_write_data <= "00";--and this should be 00 for resetting.
                        tpre_we_FF <= '1'; -- Write enable tpre
                        apre_we_FF <= '0';
                        tpre_write_addr_FF <= to_unsigned((tpre_update_index_FF - 2) * (N1+1) + NA, tpre_write_addr_FF'length);
--                        skip_flag <='1';
                    elsif tpre_read_data_FF(7) = '0' and tpre_read_data_FF < tpre_FF_max and flag_missed_tpre_increment_FF= '0'and skip_flag ='0'then --current_neuron_index_int/=NA_loader 
                        tpre_write_data_FF <= tpre_read_data_FF + 1;
                        tpre_we_FF <= '1'; -- Write enable tpre
                        apre_we_FF <= '0';
                        tpre_write_addr_FF <= to_unsigned((tpre_update_index_FF - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr_FF'length);
--                        skip_flag <='1';                        
                    elsif tpre_read_data_FF(7) = '0' and tpre_read_data_FF >= tpre_FF_max then
                        tpre_write_data_FF <= (others => '1'); -- Max out value
                        apre_write_data_FF <= "00";
                        tpre_we_FF <= '1'; -- Write enable tpre
                        apre_we_FF <= '1';
                        tpre_write_addr_FF <= to_unsigned((tpre_update_index_FF - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr_FF'length);                        
--                            apre(tpre_update_index - 2)(current_neuron_index_int)<='0';
--                            apre_write_data <= '0'; -- Reset apre
--                            apre_we <= '1'; -- Write enable apre

--                        tpre_we_FF <= '1'; -- Write enable tpre
--                        tpre_write_addr_FF <= to_unsigned((tpre_update_index_FF - 2) * (N1+1) + NA, tpre_write_addr_FF'length);
                    else
                        tpre_we_FF <= '0';
                        apre_we_FF <= '0';
--                        skip_flag <='0';
                        
                    end if;
                
                end if;
    
                -- Move to the next index
                if tpre_update_index_FF <= N1 then
                    tpre_update_index_FF <= tpre_update_index_FF + 1;
                elsif Port_Spike_in='1' and flag_missed_tpre_increment_FF='0' then
                    flag_missed_tpre_increment_FF<='1';
--                    flag_missed_tpre_increment_trigger<='0';
                    update_active_FF <= '0';
                    update_done_FF <= '1';
                else
                    update_active_FF <= '0';
                    update_done_FF <= '1';
                    flag_missed_tpre_increment_FF<='0';
--                    flag_missed_tpre_increment_trigger<='0';
                end if;
            else
                tpre_we_FF <= '0';
                apre_we_FF <= '0';
            end if;
    
        end if;
    end process;

----------------------------------TPRE CALCULATION FOR STDP UPDATES OF All-to-All connected weights------------------
    tpre_updater: process(clk100M)
    variable flat_index_tpre : integer range 0 to 100000;
    begin
        if rising_edge(clk100M) then
            case loader_status is   
                when init_weight =>
                    IF (En_Weight_AA = '1') THEN
                        -- Compute the flat address from row_index_tpre and col_index_tpre
                        flat_index_tpre := row_index_tpre * (N1 + 1) + col_index_tpre;
                        -- Drive the weight_ram write interface
                        tpre_we         <= '1';
                        tpre_write_addr <= to_unsigned(flat_index_tpre, tpre_write_addr'length);
                        tpre_write_data <= (others=>'1');
                        apre_write_data <= (others=>'0');
                        tpost_dummy <=(others => (others => '1'));
                        apost_dummy <=(others=>'0');
            
                        -- Update indices (row and column counters)
                        IF col_index_tpre < N1 THEN
                            col_index_tpre <= col_index_tpre + 1;  -- Move to the next column in the same row
                        ELSE
                            col_index_tpre <= 0;              -- Reset column index for new row
                            IF row_index_tpre < N1 THEN
                                row_index_tpre <= row_index_tpre + 1; -- Move to the next row
                            ELSE
                                row_index_tpre <= 0;          -- Reset row index if all rows are filled
                            END IF;
                        END IF;
                    ELSE
                        tpre_we <= '0';  -- Ensure write enable is low when not writing
                        tpre_write_addr <= to_unsigned(0, tpre_write_addr'length);
                    END IF;
                when stdp_update =>
    
                    -- Start update cycle when triggered
                    -- Detect rising edge of Port_Spike_out
                    if ((en_tpre_update_prev = '0' and en_tpre_update = '1') or (flag_multiple_no_spike_counter='1' and en_tpre_update = '1')) and start_flag='1' then
                      flag_trig_no_spike_counter <= '1';
                      tpre_update_index <= N0;
                      update_active    <= '1';
                      update_done      <= '0';
        
                      if tpost_dummy(current_neuron_index_int)(7)='0' and  tpost_dummy(current_neuron_index_int)< tpost_AA_max then
                        tpost_dummy(current_neuron_index_int)<=tpost_dummy(current_neuron_index_int)+1;
                      elsif tpost_dummy(current_neuron_index_int)(7)='0' and  tpost_dummy(current_neuron_index_int)>= tpost_AA_max then
                        tpost_dummy(current_neuron_index_int)<=(others => '1');
                        apost_dummy(current_neuron_index_int)<='0';
                      end if;
        
                    elsif((port_spike_out_prev = '0' and Spike_out = '1') or 
                        (flag_multiple_spike_counter='1' and Spike_out = '1')) then
        --              flag_trig_no_spike_counter <= '1';
                      tpre_update_index <= N0;
                      update_active    <= '1';
                      update_done      <= '0';
                      tpost_dummy(current_neuron_index_int) <=(others => '0');
                      apost_dummy(current_neuron_index_int) <='1';
        --              apre(current_neuron_index_int) <= (others => '1');--If this is not all to all connected use a for loop
        --              apre(current_neuron_index_int)(current_neuron_index_int) <= '0';  -- Set the specific element to '0'
        --              flag_missed_tpre_increment<= '1';
        --              addr_missed_tpre_increment<= current_neuron_index_int;
                    elsif flag_missed_tpre_increment ='1' and update_active ='0' then                
                      tpre_update_index <= N0;
                      update_active    <= '1';
                      update_done      <= '0';
        --              flag_missed_tpre_increment<= '0';
        --            elsif flag_missed_tpre_increment_trigger ='0' then
        --                flag_missed_tpre_increment <='0';
        --                flag_missed_tpre_increment_trigger <='1';
                    else
                      flag_trig_no_spike_counter <= '0';
                    end if;
                    en_tpre_update_prev <= en_tpre_update;
                
                    if multiple_no_spike_counter=multiple_spike_counter_max then
                        multiple_no_spike_counter<=(others=>'0');
                        flag_multiple_no_spike_counter<='1';        
                    elsif flag_trig_no_spike_counter='1' or multiple_no_spike_counter>0 then
                        multiple_no_spike_counter<=multiple_no_spike_counter+1;
                        flag_multiple_no_spike_counter<='0';
                    else
                        flag_multiple_no_spike_counter<='0';
                    end if;
                    
                    if update_active = '1' then
                        -- Step 1: Set BRAM read address
                        if Spike_out='1' and tpre_update_index <= N1 and flag_missed_tpre_increment = '1' then
                            tpre_read_addr <= to_unsigned(tpre_update_index * (N1+1) + current_neuron_index_int, tpre_read_addr'length);
                        elsif Spike_out='1' and tpre_update_index <= N1 then
                            tpre_read_addr <= to_unsigned(current_neuron_index_int * (N1+1) + tpre_update_index, tpre_read_addr'length);
                        elsif en_tpre_update='1' and tpre_update_index <= N1 then
                            tpre_read_addr <= to_unsigned(tpre_update_index * (N1+1) + current_neuron_index_int, tpre_read_addr'length);
                        elsif tpre_update_index = N1+1 then
                            tpre_read_addr <= to_unsigned(0 * (N1+1) + 0, tpre_read_addr'length);
                            
                        end if;
            
                        -- Step 2: Process previous cycle’s data and update
        --                if flag_missed_tpre_increment<= '1' then
        --                    tpre_write_data <= tpre_read_data+1;
        --                    tpre_write_addr <=tpre_read_addr;
        --                    tpre_we <= '1'; -- Write enable tpre
                        if tpre_update_index > N0 and Spike_out='1' and flag_missed_tpre_increment= '0' then
                            tpre_write_data <= (others => '0');
                            apre_write_data <= "01";
        --                    apre(current_neuron_index_int)(tpre_update_index-1)<='1';
                            tpre_write_addr <=tpre_read_addr;
                            tpre_we <= '1'; -- Write enable tpre
                        elsif tpre_update_index > (N0+1) then
                            if tpre_read_data(7) = '0' and flag_missed_tpre_increment= '1' and (tpre_update_index-2)/=current_neuron_index_int then
        --                        if flag_missed_tpre_increment= '1' and (tpre_update_index-2)/=current_neuron_index_int then
                                tpre_write_data <= tpre_read_data+1;--this should be ff
                                tpre_we <= '1'; -- Write enable tpre
                                tpre_write_addr <= to_unsigned((tpre_update_index - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr'length);
                                apre_write_data <= "01";--and this should be 00 for resetting.                            
                            elsif tpre_read_data(7) = '0' and tpre_read_data < tpre_AA_max and flag_missed_tpre_increment= '0'then --Ashish error should be 1?
                                tpre_write_data <= tpre_read_data + 1;
                                tpre_we <= '1'; -- Write enable tpre
                                tpre_write_addr <= to_unsigned((tpre_update_index - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr'length);
                                apre_write_data <= "01";
                            elsif tpre_read_data(7) = '0' and tpre_read_data >= tpre_AA_max then
                                tpre_write_data <= (others => '1'); -- Max out value
                                apre_write_data <= "00";
                                tpre_we <= '1'; -- Write enable tpre
                                tpre_write_addr <= to_unsigned((tpre_update_index - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr'length);
        --                            apre(tpre_update_index - 2)(current_neuron_index_int)<='0';
        --                            apre_write_data <= '0'; -- Reset apre
        --                            apre_we <= '1'; -- Write enable apre
                                
        
        --                        end if;
        --                        tpre_we <= '1'; -- Write enable tpre
        --                        tpre_write_addr <= to_unsigned((tpre_update_index - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr'length);
                            else
                                tpre_we <= '0';
        --                        apre_we <= '0';
                            end if;
                        
                        end if;
            
                        -- Move to the next index
                        if tpre_update_index <= N1 then
                            tpre_update_index <= tpre_update_index + 1;
                        elsif Spike_out='1' and flag_missed_tpre_increment='0' then
                            flag_missed_tpre_increment<='1';
        --                    flag_missed_tpre_increment_trigger<='0';
                            update_active <= '0';
                            update_done <= '1';
                        else
                            update_active <= '0';
                            update_done <= '1';
                            flag_missed_tpre_increment<='0';
        --                    flag_missed_tpre_increment_trigger<='0';
                        end if;
                    else
                        tpre_we <= '0';
        --                apre_we <= '0';
                    end if;
                when others=>
                    null;
            end case;  
        end if;
    end process;

    en_tpre_update_FF<=not PORT_Spike_in;
    
    Spike_FF_updater : PROCESS(CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF PORT_Spike_in='1' and ACT_TRIGER='1' THEN
                Sin_latch<=PORT_Spike_in;                

            END IF;
            IF current_neuron_index_int =N1 then
                Sin_prev<=Sin_latch;
                Sin_latch<='0';

            END IF;
        END IF;
    END PROCESS;

    LIF_updater : PROCESS (CLK) --NEURON OPERATION HERE
    
    BEGIN
        IF (rising_edge(CLK)) THEN
            ----------------------------------- 1st stage---------------------------------------------------
--            vtheta_in <= PORT_vtheta_in; --If we are going to have adaptable threshold while simulation 
--            vthr_in <= PORT_vthr_in;     --If we are going to change threshold while simulation
            Iin <= PORT_Iin; --From UART or constant.
            vin <= PORT_vin;
            Isyn_in<=PORT_Isyn_in;
            Isyn_in_FF<=PORT_Isyn_in_FF;
            
            if current_neuron_index_int<=N1-4 then --95, 15
                Sin_1st <= Sin_prev;--PORT_Spike_in goes to Sin_latch which goes to Sin_prev;
                Sin_2nd <= Sin_1st;
                Sin <= Sin_2nd;
                Sin_internal_1st <= spikes_L_prev(current_neuron_index_int+4);
                Sin_internal_2nd <=Sin_internal_1st; 
                Sin_internal<= Sin_internal_2nd;
                w_comb <= weight_prev(current_neuron_index_int+4);
                w_comb_FF <=weight_FF_prev(current_neuron_index_int+4);

            elsif current_neuron_index_int=N1-3 then
                Sin_internal<= Sin_internal_2nd;
                w_comb_FF <=(OTHERS => '0');
            else
                Sin_internal <=(OTHERS => '0');
                w_comb <=(OTHERS => '0'); 
                w_comb_FF <=(OTHERS => '0');
               
            end if;

            ----------------------------------- 2nd stage---------------------------------------------------
            if Sin_internal >to_signed(0, Sin_internal'length) and Sin = '1' then --If both input and network neurons spike at the same time
                Isyn_out<=Isyn_in+mul_result_2;
--                Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
                if vin_2nd>=vthr_in(current_neuron_index_int) and current_neuron_index_int <N1-1 and current_neuron_index_int >N0+3 and T_ref_ctr(current_neuron_index_int)="000000000000000000" THEN
                    Isyn_out_FF<=All_zeros;
                else    
--                    Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
                    Isyn_out_FF<=mul_result_2_FF;--April 28
                end if;
                
                            
            elsif Sin_internal >to_signed(0, Sin_internal'length) then 
                Isyn_out<=Isyn_in+mul_result_2;
            
            elsif Sin = '1' then
--                Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
                if vin_2nd>=vthr_in(current_neuron_index_int) and current_neuron_index_int <N1-1 and current_neuron_index_int >N0+3 and T_ref_ctr(current_neuron_index_int)="000000000000000000" THEN
                    Isyn_out_FF<=All_zeros;
                else    
--                    Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
                    Isyn_out_FF<=mul_result_2_FF;--April 28
                end if;
            else
                Isyn_out_FF<=All_zeros; --April 28, all lines below.
--                if Isyn_by_Tau_dt=All_zeros then
--                    Isyn_out<=All_zeros;
--                else
--                    Isyn_out<=Isyn_in-Isyn_by_Tau_dt;
--                end if;
--                if Isyn_FF_by_Tau_dt=All_zeros then
--                    Isyn_out_FF<=All_zeros;
--                else
--                    Isyn_out_FF<=Isyn_in_FF-Isyn_FF_by_Tau_dt;
--                end if;
                
            end if;
            vin_2nd<=vin+Iin;---V_by_Tau_dt;

            IF vin_2nd>=vthr_in(current_neuron_index_int) and current_neuron_index_int <N1-1 and current_neuron_index_int >N0+3 and T_ref_ctr(current_neuron_index_int)="000000000000000000" THEN
                PORT_Spike_out<= '1';
                Spike_out<='1'; --for internal clock domain tranfer
                PORT_vout<=vreset;
                en_tpre_update<='0'; --for STDP updates
                T_ref_ctr(current_neuron_index_int)<="000000000000000001";

                for i in N0 to N1 loop--As it is all to all connected, we add spikes for all neurons that will be used in the next cycle.
                    if i/=current_neuron_index then
                        spikes_L(i)<=spikes_L(i)+1;
                    end if;
                end loop;

                IF current_neuron_index_int =N1 then
                    spikes_L_prev <= spikes_L;
                    spikes_L<=(others => (others => '0'));
                END IF;                                                    
            ELSE
                en_tpre_update<='1';--for STDP updates
                IF current_neuron_index_int =N1 then
                    spikes_L_prev <= spikes_L;
                    spikes_L<=(others => (others => '0'));
                END IF;
--                for i in N0 to N1 loop--As it is all to all connected, we add spikes for all neurons that will be used in the next cycle.
                if T_ref_ctr(current_neuron_index_int)>="000000000000000001" and T_ref_ctr(current_neuron_index_int)< Tref_max(current_neuron_index_int) then
                    T_ref_ctr(current_neuron_index_int)<=T_ref_ctr(current_neuron_index_int)+1;
                elsif T_ref_ctr(current_neuron_index_int)>=Tref_max(current_neuron_index_int) then
                    T_ref_ctr(current_neuron_index_int)<= (others=>'0');
                end if;
--                end loop;
                
                PORT_Spike_out <= '0';
                Spike_out <= '0';
                IF ACT_TRIGER='0' THEN
                    PORT_vout <= (OTHERS => '0');--_2nd;
                ELSE 
--                    IF V_by_Tau_dt=All_zeros THEN               --April 28     
--                        PORT_vout<=Isyn_out+Isyn_out_FF;
--                    ELSE
                    PORT_vout<=vin_2nd-V_by_Tau_dt+Isyn_out+Isyn_out_FF;--;
--                    END IF;
                END IF;
                 
            END IF;
            ----------------------------------- 3rd stage---------------------------------------------------
            IF ACT_TRIGER='0' THEN
                PORT_Isyn_out <= (OTHERS => '0');--_2nd;
                PORT_Isyn_out_FF <= (OTHERS => '0');
            
            ELSE 
                PORT_Isyn_out <= Isyn_out;--_2nd;
                PORT_Isyn_out_FF <= Isyn_out_FF;
            END IF;

            IF ACT_TRIGER='0' THEN
                current_neuron_index <=(OTHERS => '0');
                current_neuron_index_int <= 0;
            ELSIF 
                Triger = '0' and trigger_seen='1' then
                current_neuron_index <= current_neuron_index+1;
                current_neuron_index_int <= current_neuron_index_int+1;
            ELSE
                current_neuron_index <=(OTHERS => '0');
                current_neuron_index_int <= 0;
            END IF;
        END IF;
    END PROCESS;

--------------------------------Neuron and Synapse Decay Calculations----------------
--    temp_result_vin<=fixed_point_constant_vin*vin_2nd;
    V_by_Tau_dt <= tau_mem(8); --"000000000000000000" ;
    temp_result_Isyn<=fixed_point_constant_Isyn*Isyn_in;
    Isyn_by_Tau_dt <= resize(temp_result_Isyn(27 downto 10), 18);    
    temp_result_Isyn_FF<=fixed_point_constant_Isyn*Isyn_in_FF;
    Isyn_FF_by_Tau_dt <= resize(temp_result_Isyn_FF(27 downto 10), 18);  
    
    mul_result<=w_comb*Syn_amp;-- * Sin_internal;
    mul_result_2 <= resize(mul_result sll 10, Isyn_out'length);
--    mul_result_2<=resize(mul_result, Isyn_out'length);
    
    mul_result_FF<=w_comb_FF*Syn_amp_FF;-- * Sin_internal;
    mul_result_2_FF <= resize(mul_result_FF sll 10, Isyn_out_FF'length);
--    mul_result_2_FF<=resize(mul_result_FF, Isyn_out_FF'length);


------------------------------Below are integer conversions-------------------------
    NA<=to_integer(unsigned(PORT_Neuron_Addr));
    NA_loader<=to_integer(unsigned(NA_weight_loader));
    Vin_int <= to_integer(unsigned(vin));
    tpre_read_addr_int <= to_integer(unsigned(tpre_read_addr));
    lat_read_addr_int <= to_integer(unsigned(lat_read_addr));
    V_by_Tau_dt_int <= to_integer(unsigned(V_by_Tau_dt));
    Isyn_in_int <= to_integer(unsigned(Isyn_in));
    Isyn_out_int <= to_integer(unsigned(Isyn_out));
    Isyn_by_Tau_dt_int <= to_integer(unsigned(Isyn_by_Tau_dt));

END;
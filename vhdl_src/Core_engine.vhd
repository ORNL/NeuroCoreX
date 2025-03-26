------------------------------------------------------
-- Author: Ashish Gautam
-- Model: CLIF model
-- Port Descriptions:
--    clk: clock
--    PORT_Sin: Stimulus spike input
--    PORT_vin/out: Membrane potential
--    PORT_vthr_in/out: Variable threshold
--    PORT_theta_in/out: Variable threshold time constatnt
--    PORT_I
--    PORT_spike_flag: This becomes 1 only when a spike occurs
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
    En_Weight_AA: IN STD_LOGIC;
    En_Weight_FF: IN STD_LOGIC;
    PORT_vout : OUT SIGNED(17 DOWNTO 0);
--    PORT_vthr_out : OUT SIGNED(17 DOWNTO 0);
--    PORT_vtheta_out : OUT SIGNED(17 DOWNTO 0);
--    PORT_tcount_out: OUT SIGNED(17 DOWNTO 0);
    PORT_Isyn_out : OUT SIGNED(17 DOWNTO 0);
    PORT_Isyn_out_FF : OUT SIGNED(17 DOWNTO 0);
    PORT_Spike_out : OUT STD_LOGIC
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
    TYPE STATE_TYPE IS (READY);
    SIGNAL STATE : STATE_TYPE := READY;
    SIGNAL Sin, Sin_prev, Sin_1st, Sin_2nd : STD_LOGIC := '0';
    SIGNAL Sin_internal, Sin_internal_1st, Sin_internal_2nd : SIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Iin : SIGNED(17 DOWNTO 0) := (OTHERS => '0');--Iin/Cmem
    SIGNAL Isyn_in, Isyn_in_FF : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL V_by_Tau_dt : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL V_by_Tau_dt_std : STD_LOGIC_VECTOR(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Isyn_by_Tau_dt,Isyn_FF_by_Tau_dt : SIGNED(17 DOWNTO 0) := (OTHERS => '0'); 
--    SIGNAL Syn_amp : SIGNED(17 DOWNTO 0) := "000000000000110000";
    SIGNAL Syn_amp : SIGNED(27 DOWNTO 0) := "0000000000000000000000000001";
    SIGNAL Syn_amp_FF : SIGNED(27 DOWNTO 0) := "0000000000000000000000000000";
    --SIGNAL V_by_Tau_0 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL V_by_Tau_1 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL V_by_Tau_2 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL V_by_Tau_3 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL V_by_Tau_4 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL V_by_Tau : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Isyn_out, Isyn_out_FF : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Isyn_out_1st, Isyn_out_2nd : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
--    SIGNAL Isyn_out_36 : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vin : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
--    SIGNAL vthr_in : SIGNED(17 DOWNTO 0) :=  "000000001000000001";
    SIGNAL vtheta_in : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vout : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
--    SIGNAL vthr_out : SIGNED(18 DOWNTO 0) := (OTHERS => '0');
--    SIGNAL vtheta_out : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vin_2nd : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vreset : SIGNED(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Vout_int : INTEGER:=0;
    SIGNAL Vin_int, tpre_read_addr_int, lat_read_addr_int : INTEGER:=0;
    SIGNAL Vin_2nd_int : INTEGER:=0;
    SIGNAL V_by_Tau_dt_int : INTEGER:=0;
    SIGNAL Isyn_in_int : INTEGER:=0;
    SIGNAL Isyn_out_int : INTEGER:=0;
    SIGNAL Isyn_by_Tau_dt_int : INTEGER:=0;
    CONSTANT N2 : NATURAL := 39;
    CONSTANT N1 : NATURAL := 19;
    CONSTANT N0 : NATURAL := 0;
    CONSTANT fixed_point_constant_vin : signed(17 downto 0) := to_signed(102, 18);  -- 0.1 in Q7.10 format
    CONSTANT fixed_point_constant_Isyn : signed(17 downto 0) := to_signed(102, 18);  -- 0.1 in Q7.10 format
    SIGNAL current_neuron_index_int :INTEGER:=0; 
    SIGNAL temp_result_vin : signed(35 downto 0):= (OTHERS => '0');
    SIGNAL temp_result_Isyn, temp_result_Isyn_FF : signed(35 downto 0):= (OTHERS => '0');
    SIGNAL current_neuron_index : SIGNED(15 downto 0) := (OTHERS => '0');
    SIGNAL flag_check : STD_LOGIC:='0';
    SIGNAL NA, NA_loader : INTEGER:=0;
    SIGNAL Sin_latch: STD_LOGIC:='0';
   
    SIGNAL mul_result, mul_result_FF : SIGNED(35 downto 0):= (OTHERS => '0'); -- Signal to hold multiplication result
    SIGNAL mul_result_2, mul_result_2_FF : SIGNED(17 downto 0):= (OTHERS => '0'); -- Signal to hold multiplication result
       
    TYPE spikes_lateral is array (0 to N1) of SIGNED(7 downto 0);
    SIGNAL spikes_L, spikes_L_prev : spikes_lateral := (others => (others => '0'));
    signal ram : spikes_lateral:= (others => (others => '0'));
--    attribute ram_style : string;
--    attribute ram_style of ram : signal is "distributed";
--    SIGNAL spikes_FF, spikes_FF_prev : spikes_lateral := (others => (others => '0'));
    
--    attribute ram_style of spikes_L, spikes_FF, spikes_L_prev : signal is "";
    TYPE Neuron_parameters is array (0 to N1) of SIGNED(17 downto 0);
    SIGNAL vthr_in : Neuron_parameters :=  (others =>"000000001000000001");
--    signal ram_par : Neuron_parameters:= (others => (others => '0'));
--    attribute ram_style of ram_par : signal is "distributed";
    --SIGNAL spikes_L_A : spikes_lateral := (others => (others => '0'));
    SIGNAL w_comb, w_comb_FF : SIGNED(7 downto 0):= (OTHERS => '0');--weight
        
    -------------2D WEIGHTS but I am not able to store them in BRAM------------
    TYPE weight_matrix is array (0 to N1) of SIGNED(7 downto 0);--weight
    SIGNAL weight, weight_FF : weight_matrix := (others => (others => '0'));
    SIGNAL weight_prev, weight_FF_prev : weight_matrix := (others => (others => '0'));

    TYPE weight_matrix_lat is array (0 to N1) of weight_matrix;

--    SIGNAL weight_lat : weight_matrix_lat := 
--    (0 => (others => "00000000"), 
--        1=>(others => "00000000"),
--            2=>(others => "00000000"),
--            3=>(others => "00000000"),
--            4=>(others => "00000000"),
--            5=>(others => "00000000"),
--            6=>(others => "00000001"),-- Initialize the sixth row with the value --0x06, this is the weight from all input neurons to the 1st neuron in the excitatory layer
----            7=>(others => "00000000"),
----            8=>(others => "00000000"),
----            9=>(others => "00000000"),
--                others => (others =>"00000001"));           
                           

----weight_mat_FF: Column corresponds to the neuron number of the input layer and row corresponds to neuron number of the excitatory layer.
--    SIGNAL weight_mat_FF : weight_matrix_lat := --Weights are stored from 6th row to 99th row resultig in weights for 94 neurons in excitatory layer.
--    (0 => (others => "00000000"), 
--        1=>(others => "00000000"),
--            2=>(others => "00000000"),
--            3=>(others => "00000000"),
--            4=>(others => "00000000"),
--            5=>(others => "00000000"),
--            6=>(others => "00000110"),-- Initialize the sixth row with the value --0x06, this is the weight from all input neurons to the 1st neuron in the excitatory layer
--            7=>(others => "00000111"),
--            8=>(others => "00001000"),
----            9=>(others => "00001001"),
--                others => (others =>"00000000"));
   -----------------------------------If using 2D weights, uncomment this block above-------------------
--    type weight_array is array (0 to (N1+1)*(N1+1)-1) of SIGNED(7 downto 0);
--    signal weight_lat : weight_array := (others => (others => '0'));
--    signal weight_mat_FF : weight_array := (others => (others => '0'));


--RECTANGULAR STDP learning
    TYPE STDP_STATE is array (0 to N1) of STD_LOGIC;
--    TYPE STDP_apre is array (0 to N1) of STDP_STATE;
--    SIGNAL apre : STDP_apre := (others => (others => '0'));
--    SIGNAL tpre : weight_matrix_lat := (others => (others => "00000001"));
    SIGNAL apost : STDP_STATE := (others => '0');
    SIGNAL apost_read_data_FF: STD_LOGIC:= '0';
    SIGNAL tpost : spikes_lateral := (others => (others => '1'));
    SIGNAL delta_w: SIGNED(7 DOWNTO 0) := "00000001";
--    signal ram_par_a : weight_matrix_lat:= (others => (others => "00000001"));
--    attribute ram_style of ram_par_a : signal is "distributed";
    TYPE STDP_UPDATED is array (0 to N1+1) of STD_LOGIC;
--    TYPE STDP_apre is array (0 to N1) of STDP_STATE;
--    SIGNAL apre : STDP_apre := (others => (others => '0'));
--    SIGNAL tpre : weight_matrix_lat := (others => (others => "00000001"));
    SIGNAL updated_weights, updated_weights_FF : STDP_UPDATED := (others => '0');
    
    SIGNAL weight_count : INTEGER RANGE 0 TO N1 * N1 := 0; -- Keeps track of incoming weights
    SIGNAL row_index, row_index_FF : INTEGER RANGE 0 TO N1 := 0;  -- Row selector
    SIGNAL col_index, col_index_FF : INTEGER RANGE 0 TO N1 := 0;  -- Column selector
    signal accumulation_done, we  : std_logic := '1';
    signal acc_index          : integer range 0 to N1 := 0;
    signal bram_addr, bram_addr_write : unsigned(15 downto 0); -- adjust width as needed
    signal bram_data, bram_data_write  : signed(7 downto 0);  -- data output from BRAM
    signal port_spike_out_prev, Spike_out, port_spike_in_prev: std_logic := '0';
    signal lat_acc_index          : integer range 0 to N1 := 0;
    signal lat_accumulation_done  : std_logic := '1';
    signal lat_bram_addr, weight_AA_write_addr, weight_FF_write_addr : unsigned(15 downto 0);  -- adjust width to cover (N1+1)*(N1+1) words
    signal lat_bram_data, weight_AA_data_in, weight_FF_data_in: signed(7 downto 0);       -- data from BRAM
    signal weight_AA_we, weight_FF_we : std_logic :='0';
    signal bram_data_prev : signed(7 downto 0);  -- Pipeline register for previous BRAM data
    signal clk_delayed : std_logic :='0';
    signal multiple_spike_counter, multiple_spike_counter_FF : std_logic_vector(10 downto 0):=(others=>'0');
    signal multiple_spike_counter_max, multiple_spike_counter_max_FF : std_logic_vector(10 downto 0):= "01111101000";
    signal flag_multiple_spike_counter, flag_trig_counter, flag_multiple_spike_counter_FF, flag_trig_counter_FF : std_logic :='0';
    signal multiple_no_spike_counter, multiple_no_spike_counter_FF : std_logic_vector(10 downto 0):=(others=>'0');
    signal multiple_no_spike_counter_max, multiple_no_spike_counter_max_FF : std_logic_vector(10 downto 0):= "01111101000";
    signal flag_multiple_no_spike_counter, flag_trig_no_spike_counter, flag_missed_tpre_increment, flag_multiple_no_spike_counter_FF, flag_trig_no_spike_counter_FF, flag_missed_tpre_increment_FF : std_logic :='0';
--    signal flag_missed_tpre_increment_trigger : std_logic :='1';
    
    --STDP with BRAM--
    signal lat_update_index        : integer range N0 to N1 := N0;
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
--    signal apre_we          : std_logic;
--    signal apre_write_data  : std_logic;
    signal tpre_update_index, tpre_update_index_FF, FF_update_index : integer range N0 to N1 := N0;
    signal update_active, update_active_FF, FF_update_active    : std_logic := '0';
    signal update_done, update_done_FF, FF_update_done      : std_logic := '1';
    signal en_tpre_update, en_tpre_update_FF    : std_logic := '0';
    signal en_tpre_update_prev, en_tpre_update_prev_FF   : std_logic := '0';
    signal start_flag : std_logic := '0';  -- Output signal that stays high after first trigger
    signal trigger_seen : std_logic := '0'; -- Internal flag to track first detection
    type loader_state is (init_weight, stdp_update);
    signal loader_status : loader_state := init_weight;
    signal tpre_FF_max, tpost_FF_max, tpre_AA_max, tpost_AA_max : signed(7 downto 0):="01111111"; 


BEGIN
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
           
    Core_run_start: process(clk)
    begin
        if rising_edge(clk) then
            if TRIGER = '1' and trigger_seen = '0' then
                start_flag <= '1';  -- Set flag when TRIGER goes high for the first time
                trigger_seen <= '1'; -- Remember that TRIGER has been seen
                loader_status<=stdp_update;
            end if;
        end if;
    end process; 
    --    accumulation_process : process(clk100M)
--    begin
--      if rising_edge(clk100M) then
    
--        -- When en_input goes high, start a new accumulation cycle:
--        if en_input = '1' then
--          acc_index <= 0;
--          accumulation_done <= '0';
--          bram_addr <= to_unsigned(0 * (N1 + 1) + NA_loader, bram_addr'length);
----          bram_valid <= '0'; -- BRAM data isn't valid yet
--        end if;
    
--        -- If we're in accumulation mode (i.e. accumulation not complete)
--        if accumulation_done = '0' then
--          -- Set the BRAM read address for the current index.
--          -- This computes the flattened address for (acc_index, NA)
--          bram_addr <= to_unsigned(acc_index * (N1 + 1) + NA_loader, bram_addr'length);
    
--          -- Because BRAM read is synchronous, the data read in the current cycle (bram_data)
--          -- corresponds to the address set in the previous cycle.
--          -- Hence, for acc_index > 0, accumulate the previously read value.
--          if acc_index > 0 then
--            weight_FF(acc_index - 1) <= weight_FF(acc_index - 1) + bram_data;
--          end if;
    
--          -- Check if this is the last index:
--          if acc_index = N1 then
--            -- For the final index, accumulate the value and mark the accumulation as complete.
--            weight_FF(N1) <= weight_FF(N1) + bram_data;
--            acc_index <= 0;         -- Reset the index for the next accumulation trigger.
--            accumulation_done <= '1';
--          else
--            -- Otherwise, move to the next index.
--            acc_index <= acc_index + 1;
--          end if;
--        end if;
--        IF current_neuron_index_int =N1 then
--            weight_FF<=(others => (others => '0'));
--        end if;
--      end if;
--    end process;    
    accumulation_process : process(clk100M)
    begin
      if rising_edge(clk100M) then
      
        -- When en_input goes high, start a new accumulation cycle
        clk_delayed <= clk;
        if en_input = '1' then
          acc_index <= 0;
          accumulation_done <= '0';
          bram_addr <= to_unsigned(0 * (N1 + 1) + NA_loader, bram_addr'length); -- First address setup
        elsif accumulation_done = '0' then  -- Active accumulation phase
        
          -- Pipeline BRAM data
--          bram_data_prev <= bram_data;  -- Save previous cycle's BRAM data
          -- Accumulate previously read value (after BRAM read latency)
          if acc_index > 0 then
            weight_FF(acc_index - 1) <= weight_FF(acc_index - 1) + bram_data;
          elsif acc_index=N1+1 then
            weight_FF(N1) <= weight_FF(N1) + bram_data;
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
        end if;
    
      end if;
    end process;

    
    
    lat_accumulation_process : process(clk100M)
    begin
      if rising_edge(clk100M) then
              
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
              weight(lat_acc_index - 1) <= weight(lat_acc_index - 1) + lat_bram_data;
            elsif (lat_acc_index - 1) /= current_neuron_index and current_neuron_index=N1+1 then
              weight(N1) <= weight(N1) + lat_bram_data;
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
      end if;
    end process;
--    AA_weight_loader : PROCESS(CLK100M)
--        variable flat_index : integer;
--    BEGIN
--        IF rising_edge(CLK100M) THEN
        
--    --        IF (En_Weight_AA = '1') THEN
--    --            -- Compute the flat address from row_index and col_index
--    --            flat_index := row_index * (N1 + 1) + col_index;
--    --            -- Drive the weight_ram write interface
--    --            weight_AA_we         <= '1';
--    --            weight_AA_write_addr <= to_unsigned(flat_index, weight_AA_write_addr'length);
--    --            weight_AA_data_in    <= signed(PORT_Weight_AA);
    
--    --            -- Update indices (row and column counters)
--    --            IF col_index < N1 THEN
--    --                col_index <= col_index + 1;  -- Move to the next column in the same row
--    --            ELSE
--    --                col_index <= 0;              -- Reset column index for new row
--    --                IF row_index < N1 THEN
--    --                    row_index <= row_index + 1; -- Move to the next row
--    --                ELSE
--    --                    row_index <= 0;          -- Reset row index if all rows are filled
--    --                END IF;
--    --            END IF;
--    --        ELSE
--    --            weight_AA_we <= '0';  -- Ensure write enable is low when not writing
--    --        END IF;
--                    -- Start the update when required
--            if ((port_spike_out_prev = '0' and Spike_out = '1') or (flag_multiple_spike_counter='1' and Spike_out = '1')) and (lat_update_done = '1') then
--                lat_update_index  <= N0;  -- Start iteration
--                lat_update_done   <= '0';
--                lat_update_active <= '1';
--            end if;
    
--            if lat_update_active = '1' then
--                -- Set BRAM read address for current index
--                lat_read_addr <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
    
--                -- One cycle later, read value is available
--                if lat_update_index > N0 then
--                    -- Read previous cycle's data and update if conditions are met
--                    if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then
--                        weight_AA_data_in <= lat_read_data + delta_w;
--                        weight_AA_we <= '1'; -- Enable write
--                        weight_AA_write_addr <= to_unsigned((lat_update_index - 1) * (N1+1) + current_neuron_index_int, lat_write_addr'length);
----                    elsif apost(lat_update_index - 1)='i' then
                        
--                    else
--                        weight_AA_we <= '0'; -- No write
--                    end if;
--                end if;
    
--                -- Iterate through indices
--                if lat_update_index = N1 then
--                    lat_update_active <= '0'; -- Stop updates
--                    lat_update_done   <= '1';
--                else
--                    lat_update_index <= lat_update_index + 1;
--                end if;
--            else
--                weight_AA_we <= '0'; -- Default to no write
--            end if;
--        END IF;
--    END PROCESS;
    
    AA_weight_loader : PROCESS(CLK100M)
--        variable toggle_write : std_logic := '0';  -- Toggle between original and transposed writes
        variable flat_index : integer;
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
                        (lat_update_done = '1') then--This might be incorrect and i might need seperate flags here
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
                            lat_read_addr <= to_unsigned((lat_update_index+1) * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                            apre_read_addr <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                        elsif toggle_write = '1' and lat_update_index <= N1 then
                            lat_read_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index), lat_read_addr'length);
                            apre_read_addr <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index), lat_read_addr'length);
                        else
                            lat_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apre_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                        end if;
                        lat_read_data_prev<=lat_read_data;
            
                        -- BRAM Read Pipeline: Apply Update after One Cycle
                        if lat_update_index > N0 then
--                            if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then--current_neuron_index_int-1?
                            if apre_read_data = "01" then
                                -- Read data from BRAM and add or subtract delta_w
                                -- Compute Write Address Based on Toggle Logic
                                if toggle_write = '0' then
                                    if (lat_read_data + delta_w) > to_signed(127, 8) then
                                        weight_AA_data_in <= to_signed(127, 8);
                                    else
                                        weight_AA_data_in <= lat_read_data + delta_w;
                                    end if; 
                                    updated_weights(lat_update_index)<='1';
                                    weight_AA_we <= '1'; -- Enable write
                                    weight_AA_write_addr <= to_unsigned((lat_update_index - 1) * (N1+1) + current_neuron_index_int, weight_AA_write_addr'length);
                                elsif toggle_write = '1' and updated_weights(lat_update_index)='1' then
                                    if (lat_read_data - delta_w) < to_signed(-1, 8) then
                                        weight_AA_data_in <= to_signed(-1, 8);
                                    else
                                        weight_AA_data_in <= lat_read_data - delta_w;
                                    end if;
                                    weight_AA_we <= '1'; -- Enable write
                                    weight_AA_write_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index - 2), weight_AA_write_addr'length);
                                else
                                    weight_AA_we <= '0'; -- No write
                                end if;
            
                                
--                                toggle_write <= not toggle_write; -- Toggle between original and transposed writes
                            else
                                weight_AA_we <= '0'; -- No write
                            end if;
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
---------------------------------------------------------------------------------------------------------------------------------------------
--                    -- Detect the start of an update cycle
--                    if ((port_spike_out_prev = '0' and Spike_out = '1') or 
--                        (flag_multiple_spike_counter='1' and Spike_out = '1')) and 
--                        (lat_update_done = '1') then--This might be incorrect and i might need seperate flags here
--                        lat_update_index  <= N0;  -- Start iteration
--                        lat_update_done   <= '0';
--                        lat_update_active <= '1';
--                        toggle_write      <= '0';  -- Start with original address
----                        toggle_write_next <= '0';
--                    end if;
            
--                    if lat_update_active = '1' then
--                        -- Compute Read Address Based on Toggle Logic
--                        if toggle_write = '0' then
--                            lat_read_addr <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
--                            apre_read_addr <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
--                        else
--                            lat_read_addr <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index - 1), lat_read_addr'length);
--                            apre_read_addr <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index - 1), lat_read_addr'length);
--                        end if;
            
--                        -- BRAM Read Pipeline: Apply Update after One Cycle
--                        if lat_update_index > N0 then
----                            if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then--current_neuron_index_int-1?
--                            if apre_read_data = "01" then
--                                -- Read data from BRAM and add or subtract delta_w
--                                -- Compute Write Address Based on Toggle Logic
--                                if toggle_write = '0' then
--                                    if (lat_read_data + delta_w) > to_signed(127, 8) then
--                                        weight_AA_data_in <= to_signed(127, 8);
--                                    else
--                                        weight_AA_data_in <= lat_read_data + delta_w;
--                                    end if; 
--                                    weight_AA_write_addr <= to_unsigned((lat_update_index - 1) * (N1+1) + current_neuron_index_int, weight_AA_write_addr'length);
--                                else
--                                    if (lat_read_data - delta_w) < to_signed(-1, 8) then
--                                        weight_AA_data_in <= to_signed(-1, 8);
--                                    else
--                                        weight_AA_data_in <= lat_read_data - delta_w;
--                                    end if;
--                                    weight_AA_write_addr <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index - 1), weight_AA_write_addr'length);
--                                end if;
            
--                                weight_AA_we <= '1'; -- Enable write
--                                toggle_write <= not toggle_write; -- Toggle between original and transposed writes
--                            else
--                                weight_AA_we <= '0'; -- No write
--                            end if;
--                                                    -- Iterate through indices
----                            if toggle_write = '1' or (toggle_write = '0' and apre(lat_update_index-1)(current_neuron_index_int) = '0') then
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
--                        elsif lat_update_index = N0 then
--                            lat_update_index <= lat_update_index + 1;
--                        end if;
            

--                    else
--                        weight_AA_we <= '0'; -- Default to no write
--                    end if;
---------------------------------------------------------------------------------------------------------------------------------------------
                when others =>
                    null;
            end case;
        END IF;
    END PROCESS;

    FF_weight_loader : PROCESS(CLK100M)
        variable flat_index_FF : integer;
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
                        (FF_update_done = '1') then--This might be incorrect and i might need seperate flags here
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
                    if lat_update_active = '1' then
                        -- Compute Read Address Based on Toggle Logic
                        if toggle_write_FF = '0' and lat_update_index < N1 then
                            FF_read_addr <= to_unsigned((lat_update_index) * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(lat_update_index * (N1+1) + current_neuron_index_int, lat_read_addr'length);
                            apost_read_data_FF <= '0';
                        elsif toggle_write_FF = '1' and lat_update_index <= N1 then
                            FF_read_addr <= to_unsigned((current_neuron_index_int+1) * (N1+1) + (lat_update_index), lat_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apost_read_data_FF <=apost(lat_update_index);
--                            apre_read_addr_FF <= to_unsigned(current_neuron_index_int * (N1+1) + (lat_update_index), lat_read_addr'length);
                        else
                            FF_read_addr <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                            apre_read_addr_FF <= to_unsigned(0 * (N1+1) + 0, lat_read_addr'length);
                        end if;
--                        FF_read_data_prev<=FF_read_data;
            
                        -- BRAM Read Pipeline: Apply Update after One Cycle
                        if FF_update_index > N0 then
--                            if apre(lat_update_index - 1)(current_neuron_index_int) = '1' then--current_neuron_index_int-1?
                            if apre_read_data_FF = "01" and toggle_write_FF = '0' then
                                -- Read data from BRAM and add or subtract delta_w
                                -- Compute Write Address Based on Toggle Logic
                                if (FF_read_data + delta_w) > to_signed(127, 8) then
                                    weight_FF_data_in <= to_signed(127, 8);
                                else
                                    weight_FF_data_in <= FF_read_data + delta_w;
                                end if; 
--                                updated_weights_FF(FF_update_index)<='1';
                                weight_FF_we <= '1'; -- Enable write
                                weight_FF_write_addr <= to_unsigned((FF_update_index - 2) * (N1+1) + current_neuron_index_int, weight_FF_write_addr'length);
                            elsif toggle_write_FF = '1' and apost_read_data_FF='1' then
                                if (FF_read_data - delta_w) < to_signed(-1, 8) then
                                    weight_FF_data_in <= to_signed(-1, 8);
                                else
                                    weight_FF_data_in <= FF_read_data - delta_w;
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
                                toggle_write_FF<='1';
            --                    flag_missed_tpre_increment_trigger<='0';
                                FF_update_active <= '0';
                                FF_update_done <= '1';
                            else
                                FF_update_active <= '0';
                                FF_update_done <= '1';
                                toggle_write_FF<='0';
                                updated_weights_FF<=(others=>'0');--Check gautam
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
                    tpre_read_addr_FF <= to_unsigned(tpre_update_index_FF * (N1+1) + NA, tpre_read_addr_FF'length);
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
                    elsif tpre_read_data_FF(7) = '0' and tpre_read_data_FF < tpre_FF_max and flag_missed_tpre_increment_FF= '0'then
                        tpre_write_data_FF <= tpre_read_data_FF + 1;
                        tpre_we_FF <= '1'; -- Write enable tpre
                        apre_we_FF <= '0';
                        tpre_write_addr_FF <= to_unsigned((tpre_update_index_FF - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr_FF'length);                        
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

    tpre_updater: process(clk100M)
    begin
        if rising_edge(clk100M) then
    
            -- Start update cycle when triggered
            -- Detect rising edge of Port_Spike_out
            if ((en_tpre_update_prev = '0' and en_tpre_update = '1') or (flag_multiple_no_spike_counter='1' and en_tpre_update = '1')) and start_flag='1' then
              flag_trig_no_spike_counter <= '1';
              tpre_update_index <= N0;
              update_active    <= '1';
              update_done      <= '0';
            elsif((port_spike_out_prev = '0' and Spike_out = '1') or 
                (flag_multiple_spike_counter='1' and Spike_out = '1')) then
--              flag_trig_no_spike_counter <= '1';
              tpre_update_index <= N0;
              update_active    <= '1';
              update_done      <= '0';
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
                if tpre_update_index > N0 and Spike_out='1' and flag_missed_tpre_increment<= '0' then
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
--                            apre_write_data <= "00";--and this should be 00 for resetting.                            
                    elsif tpre_read_data(7) = '0' and tpre_read_data < "00000100" and flag_missed_tpre_increment= '0'then
                        tpre_write_data <= tpre_read_data + 1;
                        tpre_we <= '1'; -- Write enable tpre
                        tpre_write_addr <= to_unsigned((tpre_update_index - 2) * (N1+1) + current_neuron_index_int, tpre_write_addr'length);
                    elsif tpre_read_data(7) = '0' and tpre_read_data >= "00000100" then
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
    
        end if;
    end process;

    en_tpre_update_FF<=not PORT_Spike_in;
    
    FF_updater : PROCESS(CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF PORT_Spike_in='1' THEN
--                for i in N0 to N1 loop
----                    spikes_FF(i)<=spikes_FF(i)+1;
--                    weight_FF(i)<=weight_FF(i)+weight_mat_FF(i)(NA);
--                end loop;
                Sin_latch<=PORT_Spike_in;
--                for i in N0 to N1 loop
--                    if i/=current_neuron_index_int then
--                        apre_FF(i)(NA) <= '1';  -- Set the specific column NA to '1' for each row
--                    end if;
--                end loop;

            END IF;
            IF current_neuron_index_int =N1 then
--                flag_weight_FF_prev<='1';
--                weight_FF_prev<= weight_FF;
--                spikes_FF_prev <= spikes_FF;
                Sin_prev<=Sin_latch;
--                weight_FF<=(others => (others => '0'));
--                spikes_FF<=(others => (others => '0'));
                Sin_latch<='0';
--            ELSE
--                flag_weight_FF_prev<='0';
--                Sin_prev<='0';
            END IF;
        END IF;
    END PROCESS;

    updater : PROCESS (CLK)
    
    BEGIN
        IF (rising_edge(CLK)) THEN
            -- 1st stage
            Iin <= PORT_Iin;
            vin <= PORT_vin;
            
--            vtheta_in <= PORT_vtheta_in;
            Isyn_in<=PORT_Isyn_in;
            Isyn_in_FF<=PORT_Isyn_in_FF;
            
            if current_neuron_index_int<=N1-4 then --95, 15
                Sin_1st <= Sin_prev;--PORT_Spike_in;
                Sin_2nd <= Sin_1st;
                Sin <= Sin_2nd;
                Sin_internal_1st <= spikes_L_prev(current_neuron_index_int+4);
                Sin_internal_2nd <=Sin_internal_1st; 
                Sin_internal<= Sin_internal_2nd;
                w_comb <= weight_prev(current_neuron_index_int+4);
                flag_check<='1';
                w_comb_FF <=weight_FF_prev(current_neuron_index_int+4);
                
            else
                Sin_internal <=(OTHERS => '0');
                w_comb <=(OTHERS => '0'); 
                w_comb_FF <=(OTHERS => '0');
                flag_check<='0';                 
            end if;

                     
            --vthr_in <= PORT_vthr_in;

            -- 2nd stage
            if Sin_internal >to_signed(0, Sin_internal'length) and Sin = '1' then
--                mul_result<=w_comb*Syn_amp;-- * Sin_internal;
--                mul_result_2<=resize(mul_result, Isyn_out'length);
                Isyn_out<=Isyn_in+mul_result_2;
                
--                mul_result_FF<=w_comb_FF*Syn_amp;-- * Sin_internal;
--                mul_result_2_FF<=resize(mul_result_FF, Isyn_out_FF'length);
                Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
                
                --Isyn_out <=Isyn_out_36(27 downto 10);
            elsif Sin_internal >to_signed(0, Sin_internal'length) then 
--                mul_result<=w_comb*Syn_amp;-- * Sin_internal;
--                mul_result_2<=resize(mul_result, Isyn_out'length);
                Isyn_out<=Isyn_in+mul_result_2;--w_comb;I need to distribute this into two statements for Sin and Sin_internal case
                --Isyn_out <=Isyn_out_36(27 downto 10);
            
            elsif Sin = '1' then
--                mul_result_FF<=w_comb_FF*Syn_amp;-- * Sin_internal;
--                mul_result_2_FF<=resize(mul_result_FF, Isyn_out_FF'length);
                Isyn_out_FF<=Isyn_in_FF+mul_result_2_FF;
--                Isyn_out<=Isyn_in+Syn_amp;
--                mul_result_2 <=(OTHERS => '0');
--                mul_result <=(OTHERS => '0');
            else
                Isyn_out<=Isyn_in-Isyn_by_Tau_dt; 
                Isyn_out_FF<=Isyn_in_FF-Isyn_FF_by_Tau_dt;
--                mul_result_2 <=(OTHERS => '0');
--                mul_result <=(OTHERS => '0');
            end if;
            vin_2nd<=vin+Iin;---V_by_Tau_dt;
--            Isyn_out_2nd<=Isyn_out_1st;
--            Isyn_out<=Isyn_out_2nd;

            IF vin_2nd>=vthr_in(current_neuron_index_int) and current_neuron_index_int <N1-1 and current_neuron_index_int >N0+2 THEN
                PORT_Spike_out<= '1';
                Spike_out<='1';
                PORT_vout<=vreset;
                en_tpre_update<='0';
                --vthr_in <="000000101000000001";
                for i in N0 to N1 loop
                    if i/=current_neuron_index then
                        spikes_L(i)<=spikes_L(i)+1;
                    end if;
                end loop;
--                for i in N0 to N1 loop
--                    if i/=current_neuron_index then
----                        weight(i)<=weight(i)+weight_lat(i)(current_neuron_index_int);--check indexing order for stdp
--                        weight(i) <= weight(i) + weight_lat(i * (N1+1) + current_neuron_index_int);
--                    end if;
--                end loop;
                IF current_neuron_index_int =N1 then
--                    weight_prev<= weight;
                    spikes_L_prev <= spikes_L;
--                    weight<=(others => (others => '0'));
                    spikes_L<=(others => (others => '0'));
                END IF;
                
                apost(current_neuron_index_int) <='1';
                tpost(current_neuron_index_int) <="00000000";
--                apre(current_neuron_index_int) <= (others => '1');--If this is not all to all connected use a for loop
--                apre(current_neuron_index_int)(current_neuron_index_int) <= '0';  -- Set the specific element to '0'
--                tpre(current_neuron_index_int) <= (others => "00000000");
--                for i in N0 to N1 loop
--                    if i/=current_neuron_index_int then
--                        if apre(i)(current_neuron_index_int)='1' then
--                            weight_lat(i)(current_neuron_index_int)<=weight_lat(i)(current_neuron_index_int)+delta_w;
--                        end if;
--                    end if;
--                end loop;
                
--                for i in N0 to N1 loop
--                    if i/=current_neuron_index_int then
--                        if apost(i)='1' then
--                            weight_lat(current_neuron_index_int)(i)<=weight_lat(current_neuron_index_int)(i)-delta_w;
--                        end if;
--                    end if;
--                end loop;                         
                
            ELSE
                en_tpre_update<='1';
                if tpost(current_neuron_index_int)(7)='0' then--17
                    if tpost(current_neuron_index_int)< "00100000" then
                        tpost(current_neuron_index_int)<=tpost(current_neuron_index_int)+1;
                    else
                        tpost(current_neuron_index_int)<=(others => '1');
                        apost(current_neuron_index_int)<='0';
                    end if;
                end if;
                
--                for i in N0 to N1 loop
--                    if tpre(i)(current_neuron_index_int)(7)='0' then--17
--                        if tpre(i)(current_neuron_index_int)<"00100000" then
--                            tpre(i)(current_neuron_index_int)<=tpre(i)(current_neuron_index_int)+1;
--                        else
--                            tpre(i)(current_neuron_index_int)<=(others => '1');
--                            apre(i)(current_neuron_index_int)<='0';
--                        end if;
--                    end if;
--                end loop;
----Ye neeche wala pehele se commented hai.
--                for i in 0 to N1 loop
--                    if i/=current_neuron_index then
--                        spikes_L(i)<=(OTHERS => '0');
--                    end if;
--                end loop;
--                for i in 0 to N1 loop
--                    if i/=current_neuron_index then
--                        weight(i)<=(OTHERS => '0');
--                    end if;
--                end loop;
                IF current_neuron_index_int =N1 then
--                    weight_prev<= weight;
                    spikes_L_prev <= spikes_L;
--                    weight<=(others => (others => '0'));
                    spikes_L<=(others => (others => '0'));
                END IF;
                PORT_Spike_out <= '0';
                Spike_out <= '0';
                PORT_vout<=vin_2nd-V_by_Tau_dt+Isyn_out+Isyn_out_FF;--; 
                --Isyn_out_2nd<= Isyn_out;
            END IF;
            -- 3rd stage
            --PORT_Vout<=vout;
            PORT_Isyn_out <= Isyn_out;--_2nd;
            PORT_Isyn_out_FF <= Isyn_out_FF;
            --Vout_int <= to_integer(unsigned(vout));

            IF Triger = '0' then
                current_neuron_index <= current_neuron_index+1;
                current_neuron_index_int <= current_neuron_index_int+1;
            ELSE
                current_neuron_index <=(OTHERS => '0');
                current_neuron_index_int <= 0;
            END IF;


        END IF;
    END PROCESS;
--    vout<=PORT_Vout;
    NA<=to_integer(unsigned(PORT_Neuron_Addr));
    NA_loader<=to_integer(unsigned(NA_weight_loader));
    Vin_int <= to_integer(unsigned(vin));
    tpre_read_addr_int <= to_integer(unsigned(tpre_read_addr));
    lat_read_addr_int <= to_integer(unsigned(lat_read_addr));
--    vout_int<=to_integer(unsigned(vout));
    V_by_Tau_dt_int <= to_integer(unsigned(V_by_Tau_dt));
    Isyn_in_int <= to_integer(unsigned(Isyn_in));
    Isyn_out_int <= to_integer(unsigned(Isyn_out));
    Isyn_by_Tau_dt_int <= to_integer(unsigned(Isyn_by_Tau_dt));
    --0.1*(-vin)
    temp_result_vin<=fixed_point_constant_vin*vin_2nd;
    V_by_Tau_dt <= resize(temp_result_vin(27 downto 10), 18);
    -- (-1/Tau_syn)*dt*(Isyn)= -0.1*Isyn: 0.0001100110     OLD:v * 0.038787841796875 : 00000000.00001001111011100000    32bit
    temp_result_Isyn<=fixed_point_constant_Isyn*Isyn_in;
    Isyn_by_Tau_dt <= resize(temp_result_Isyn(27 downto 10), 18);    
    temp_result_Isyn_FF<=fixed_point_constant_Isyn*Isyn_in_FF;
    Isyn_FF_by_Tau_dt <= resize(temp_result_Isyn_FF(27 downto 10), 18); 
    --V_by_Tau_dt <= 
    mul_result<=w_comb*Syn_amp;-- * Sin_internal;
    mul_result_2<=resize(mul_result, Isyn_out'length);
    
    mul_result_FF<=w_comb_FF*Syn_amp_FF;-- * Sin_internal;
    mul_result_2_FF<=resize(mul_result_FF, Isyn_out_FF'length);
--    weight_A<=weight_lat(10)(0);
    

--    FF_weight_loader : PROCESS(CLK100M)
--    BEGIN
--        IF rising_edge(clk100M) THEN
--            IF (En_Weight_FF='1') THEN
--                -- Store the new weight at the current column-row position
--                weight_mat_FF(row_index_FF)(col_index_FF) <= signed(PORT_Weight_FF);
    
--                -- Update indices
--                IF col_index_FF < N1 THEN
--                    col_index_FF <= col_index_FF + 1; -- Move to the next row in the same column
--                ELSE
--                    col_index_FF <= 0;  -- Reset row index for new column
--                    IF row_index_FF < N1 THEN
--                        row_index_FF <= row_index_FF + 1; -- Move to the next column
--                    ELSE
--                        row_index_FF <= 0; -- Reset column index if all are filled
--                    END IF;
--                END IF;
--            END IF;
--        END IF;
--    END PROCESS;

--    AA_weight_loader : PROCESS(CLK100M)
--    BEGIN
--        IF rising_edge(clk100M) THEN
--            IF (En_Weight_AA='1') THEN
--                -- Store the new weight at the current column-row position
--                weight_lat(row_index)(col_index) <= signed(PORT_Weight_AA);
    
--                -- Update indices
--                IF col_index < N1 THEN
--                    col_index <= col_index + 1; -- Move to the next row in the same column
--                ELSE
--                    col_index <= 0;  -- Reset row index for new column
--                    IF row_index < N1 THEN
--                        row_index <= row_index + 1; -- Move to the next column
--                    ELSE
--                        row_index <= 0; -- Reset column index if all are filled
--                    END IF;
--                END IF;
--            END IF;
--        END IF;
--    END PROCESS;

END;
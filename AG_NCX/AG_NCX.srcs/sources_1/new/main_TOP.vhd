------------------------------------------------------
-- Title: NeuroCoreX
-- Simulate a network of N all-to-all connected LIF neurons with exponential current-based synapse 
-- and a simple pair-wise STDP learning rule
------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY main IS
    GENERIC( CLIF_BIT_WIDTH : NATURAL := 18); 
	PORT (
		CLK : IN STD_LOGIC;       -- clock
--        PORT_tb_READ_DONE: OUT STD_LOGIC; 
		UART_RXD : IN STD_LOGIC;  -- UART receiver pin
		UART_TXD : OUT STD_LOGIC  -- UART transmitter pin
	);
END main;

ARCHITECTURE Behavioral OF main IS

    -- clock generator 
    -- generate 100 MHz clock from on-board 12MHz clock
	COMPONENT clk_wiz_0
		PORT (
			clk_in1 : IN STD_LOGIC;
			clk_out1 : OUT STD_LOGIC
		);
	END COMPONENT;
------------------------LOGIC ANALYSER FOR DEBUGGING-------------------------
--	COMPONENT ila_0
--		PORT (
--            clk : IN STD_LOGIC;            
--            probe0 : IN STD_LOGIC;
--            probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--            probe2 : IN STD_LOGIC;
--            probe3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
--            );
--	END COMPONENT;	

	COMPONENT triger_generator_uart
		PORT (
            CLK : IN STD_LOGIC;
            TRIGER : OUT STD_LOGIC;
            ACTIVATE_TRIGER : IN STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT clock_domain_interface IS
        PORT (
            clk_100MHz       : IN  std_logic;  -- Fast clock (100 MHz)
            clk_100kHz       : IN  std_logic;  -- Slow clock (100 kHz)
            Activate_fifo_in : IN  std_logic;  -- Pulse in 100 MHz domain
            Activate_fifo_out: OUT std_logic   -- Stretched pulse in 100 kHz domain
        );
    END COMPONENT;
	
    COMPONENT UART_RX_SORTER_Input is
        PORT ( CLK : in STD_LOGIC;
               DATA_IN : in STD_LOGIC_VECTOR (7 downto 0);
               READ_EN : in STD_LOGIC;
               ACTIVATE_FIFO : in STD_LOGIC;
               PORT_flag_READ_DONE : in STD_LOGIC;
               DATA_OUT_WEIGHT_FF : out STD_LOGIC_VECTOR (7 downto 0);
               DATA_OUT_WEIGHT_AA: out STD_LOGIC_VECTOR (7 downto 0);
               DATA_OUT_SPIKE_ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
               DATA_OUT_NEURON_PARAM :  out STD_LOGIC_VECTOR (17 downto 0);
               DATA_OUT_NEURON_DEBUG : out STD_LOGIC_VECTOR (17 downto 0);
               DATA_OUT_STDP_FLAG: out STD_LOGIC_VECTOR (7 downto 0);
               FLAG_OVERFLOW: out STD_LOGIC;
               FLAG_UNDERFLOW: out STD_LOGIC;
               WRITE_EN_FF_W : out STD_LOGIC;
               WRITE_EN_AA_W : out STD_LOGIC;
               WRITE_EN_INPUT : out STD_LOGIC;
               READ_EN_AA_W : out STD_LOGIC;
               WRITE_EN_PARAM : out STD_LOGIC;
               WRITE_EN_DEBUG : out STD_LOGIC;
               WRITE_EN_STDP_FLAG: out STD_LOGIC;
               ILA_TEST_PORT: out STD_LOGIC_VECTOR(3 downto 0);
               RESET_TRIGER: out STD_LOGIC;
               READ_WEIGHT_AA: out STD_LOGIC;
               ACTIVATE_TRIGER : out STD_LOGIC
               );
    END COMPONENT;
    
    -- LIF unit
	COMPONENT LIF_unit IS
        PORT (
            CLK : IN STD_LOGIC;
            CLK100M: IN STD_LOGIC;
            en_Input: IN STD_LOGIC;
            SPIKE_IN : IN STD_LOGIC;
            TRIGER : IN STD_LOGIC;
            START_TRIGER : IN STD_LOGIC;
            RESET_TRIGER: IN STD_LOGIC;
            READ_WEIGHT: IN STD_LOGIC;
            UART_RXD_I : IN SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
            NEURON_ADDRESS: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            WEIGHT_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            WEIGHT_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            N_PARAM_IN : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
            N_DEBUG_IN : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
            N_STDP_FLAG_D_IN: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            EN_LOAD_FF_W: IN STD_LOGIC;
            EN_LOAD_AA_W: IN STD_LOGIC;
            EN_READ_AA_W: IN STD_LOGIC;
            EN_LOAD_N_PARAM: IN STD_LOGIC;
            EN_LOAD_N_DEBUG: IN STD_LOGIC;
            EN_LOAD_N_STDP_FLAG: IN STD_LOGIC;
            SEND_READY_SOUT: IN STD_LOGIC;
            ILA_DEBUG: OUT SIGNED (7 DOWNTO 0);
            WEIGHT_AA_TX:  OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            Write_Weight_AA_TX: OUT STD_LOGIC;
            UART_TXD_V : OUT SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
            UART_TXD_I : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
            Spike_OUT_Tx : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            en_SOUT_Tx: OUT STD_LOGIC;
            en_flag_READ_DONE : OUT STD_LOGIC
--            ACTIVATE_TRIGGER : IN STD_LOGIC 
        );
	END COMPONENT;
 

--	COMPONENT v_transmitter
--		PORT (
--			clk : IN STD_LOGIC;
--			triger : IN STD_LOGIC;
--			uart_txd : OUT STD_LOGIC;
--			uart_txd_v : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
--			uart_txd_I : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0)
--		);
--	END COMPONENT;
 
 
    COMPONENT UART_RX_CTRL
		PORT (
		   UART_RX : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           DATA : out  STD_LOGIC_VECTOR (7 downto 0);
           READ_DATA : out  STD_LOGIC := '0'
		);
	END COMPONENT;
 
    COMPONENT triger_generator IS
        PORT (
            CLK : IN STD_LOGIC;
            TRIGER : OUT STD_LOGIC;
    --		TRIGER_UART_FIFO:OUT STD_LOGIC;
            ACTIVATE_TRIGER : IN STD_LOGIC
        );
    END COMPONENT;
    
    COMPONENT Clock_Divider is
    Port (
        clk_in  : in  std_logic;  -- 100 MHz input clock
        rst     : in  std_logic;  -- Reset signal
        clk_out : out std_logic   -- 100 kHz output clock
        );
    END COMPONENT;

	COMPONENT Weight_Tx_AA IS
	PORT (
		CLK : IN STD_LOGIC;
		TRIGER : IN STD_LOGIC;
		UART_TXD : OUT STD_LOGIC;
		SEND_READY_TX:OUT STD_LOGIC;
		UART_TXD_W : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
    END COMPONENT;

	SIGNAL clk100, clk_lif_100k : STD_LOGIC:= '0';
	SIGNAL triger, trig_fifo, trig_triger, rst : STD_LOGIC := '0';
	SIGNAL uart_rxd_I : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_rxd_I_S: SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_txd_v : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	signal uart_txd_v_std : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 downto 0);  -- Converted output
    SIGNAL uart_txd_I : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S_in : STD_LOGIC := '0';
    SIGNAL uart_byte_ready : STD_LOGIC := '0';
    SIGNAL uart_recieved_message : STD_LOGIC_VECTOR(7 DOWNTO 0):= (OTHERS => '0');
    SIGNAL flag_under_flow, flag_over_flow : STD_LOGIC := '0';
    SIGNAL en_FF_W_read, en_AA_W_read, en_AA_W_read_Tx, en_param, en_Input, en_Input_streched, en_debug : STD_LOGIC := '0';
    SIGNAL en_AA_W_read_to_LIF: STD_LOGIC := '0';
    SIGNAL N_address : STD_LOGIC_VECTOR(15 DOWNTO 0):= (OTHERS => '0');
    SIGNAL N_Param,N_Debug  : STD_LOGIC_VECTOR(17 DOWNTO 0):= (OTHERS => '0');
    SIGNAL weight_ff : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL weight_aa, W_AA_TX : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL read_AA_weight: STD_LOGIC := '0';
    
    signal ila_probe0 : std_logic_vector(3 downto 0); 
    signal ila_probe1 : std_logic_vector(7 downto 0); 
    signal ila_probe2 : std_logic;
    signal ila_probe3 : std_logic_vector(7 downto 0);
    signal ila_probe4 : std_logic;
    signal ila_probe5 : std_logic_vector(15 downto 0);
    signal ila_probe6 : std_logic;
    signal ila_probe7 : std_logic_vector(17 downto 0);
    signal ila_probe8 : std_logic;
    signal ila_probe9 : std_logic;
    signal ila_probe3_muxed : std_logic_vector(7 downto 0);
    signal ila_debug_core_std : std_logic_vector(7 downto 0);
    signal ila_debug_core : signed(7 downto 0);
    signal reset_emulation: std_logic;
    signal uart_txd_VI, uart_txd_weight, uart_txd_Sout, en_SOUT_Tx, en_READ_DONE, send_ready_tx_sout, send_ready_tx_weight: std_logic:='0'; 
    signal uart_txd_Sout_vec: std_logic_vector(7 downto 0):= (OTHERS => '0');
    signal N_STDP_flag_data: std_logic_vector(7 downto 0):= (OTHERS => '0');
    signal en_stdp_flag: std_logic:='0';
BEGIN
    uart_txd_v_std<=std_logic_vector(uart_txd_v);
    uart_rxd_I_S <= signed(UART_RXD_I);
    ila_debug_core_std <=std_logic_vector(ila_debug_core);
    ila_probe3_muxed<="0000" & ila_debug_core_std(7 downto 4);
    uart_txd <= uart_txd_weight when read_AA_weight = '1' else uart_txd_Sout;

-----ENABLE FOR BEHAVIORAL SIMULATION-------------
--    PORT_tb_READ_DONE<=en_READ_DONE;
--    clk100<=clk;
--------------------------------------------------
   
    inst_clk: clk_wiz_0
    port map(
        clk_in1 => CLK,
        clk_out1 => clk100
        );

	LIF_unit_0 : LIF_unit
	PORT MAP(
		clk => clk_lif_100k, 
		clk100M=>clk100,
		en_Input=> en_Input,
		spike_in => en_Input_streched,
        triger => triger, 
        START_TRIGER =>trig_triger,
		RESET_TRIGER => reset_emulation,
		READ_WEIGHT => read_AA_weight,
		uart_rxd_I => uart_rxd_I_S,
        neuron_address => N_address,
        weight_aa => weight_aa,
        weight_ff => weight_ff,
        n_param_in => n_param,
        n_debug_in =>n_debug,
        n_stdp_flag_d_in=>N_STDP_flag_Data,
        en_load_ff_w =>en_FF_W_read,
        en_load_aa_w =>en_AA_W_read,
        en_read_aa_w =>en_AA_W_read_to_LIF,
        en_load_n_param => en_param,
        en_load_n_debug => en_debug,
        en_load_n_STDP_FLAG=>en_stdp_flag,
        send_ready_sout=> send_ready_tx_sout,
        ILA_DEBUG => ila_debug_core,
        WEIGHT_AA_TX=> W_AA_TX,
        Write_Weight_AA_TX=>en_AA_W_read_Tx,
		uart_txd_v => uart_txd_v, 
		uart_txd_I => uart_txd_I,
		Spike_OUT_Tx => uart_txd_Sout_vec,
		en_SOUT_Tx =>en_SOUT_Tx,
		en_flag_READ_DONE=>en_READ_DONE
--		ACTIVATE_TRIGGER =>trig_triger
	);
 
	triger_generator_0 : triger_generator_uart
	PORT MAP(
		clk => clk100, 
		triger => trig_fifo,
		ACTIVATE_TRIGER =>triger
	);
	clock_domain_interface_0:clock_domain_interface
 	PORT MAP(
		clk_100MHz => clk100,
		clk_100kHz => clk_lif_100k,
		Activate_fifo_in => en_Input,
		Activate_fifo_out =>en_Input_streched
	);
    Trig_0 : triger_generator
    PORT MAP(
		CLK => clk_lif_100k,
		TRIGER => TRIGER,
		ACTIVATE_TRIGER=> trig_triger
	);
--	v_transmitter_0 : v_transmitter
--	PORT MAP(
--		clk => clk100, 
--		triger => triger, 
--		uart_txd => uart_txd_VI, 
--		uart_txd_v => uart_txd_v_std,
--		uart_txd_I => uart_txd_I
--	); 
 
	
--	--Component used to recieve a byte of data over a UART line.
    Inst_UART_RX_CTRL: UART_RX_CTRL port map(
        UART_RX => uart_rxd,
        CLK => CLK100,
        DATA => uart_recieved_message,
        READ_DATA => uart_byte_ready
    );
    
     Inst_UART_RX_SORTER_INPUT: UART_RX_SORTER_Input 
     PORT MAP(
            CLK => clk100,
            DATA_IN => uart_recieved_message,
            READ_EN => uart_byte_ready,
            ACTIVATE_FIFO => trig_fifo,
            PORT_flag_READ_DONE => en_READ_DONE,
            DATA_OUT_WEIGHT_FF => weight_ff,
            DATA_OUT_WEIGHT_AA => weight_aa,
            DATA_OUT_SPIKE_ADDRESS => N_address,
            DATA_OUT_NEURON_PARAM =>N_param,
            DATA_OUT_NEURON_DEBUG =>N_debug,
            DATA_OUT_STDP_FLAG=>N_STDP_flag_data,
            FLAG_OVERFLOW => flag_over_flow,
            FLAG_UNDERFLOW => flag_under_flow,
            WRITE_EN_FF_W =>en_FF_W_read,
            WRITE_EN_AA_W => en_AA_W_read,
            READ_EN_AA_W => en_AA_W_read_to_LIF,
            WRITE_EN_INPUT => en_Input,
            WRITE_EN_PARAM => en_param,
            WRITE_EN_DEBUG => en_debug,
            WRITE_EN_STDP_FLAG => en_stdp_flag,
            ILA_TEST_PORT =>ila_probe0,
            RESET_TRIGER => reset_emulation,
            READ_WEIGHT_AA => read_AA_weight,
            ACTIVATE_TRIGER => trig_triger
            );
    Inst_Clk_div: Clock_Divider
    PORT MAP (
        clk_in  =>clk100,  -- 100 MHz input clock
        rst     =>rst,  -- Reset signal
        clk_out =>clk_lif_100k   -- 100 kHz output clock
        );
    
    Inst_Weight_Tx:  Weight_Tx_AA
	PORT MAP(
		CLK =>clk100,  -- 100 MHz input clock
		TRIGER =>en_AA_W_read_Tx,
		UART_TXD => uart_txd_weight,
		SEND_READY_TX=>send_ready_tx_weight,
		UART_TXD_W => W_AA_TX
	);

    Inst_SOUT_Tx:  Weight_Tx_AA
	PORT MAP(
		CLK =>clk100,  -- 100 MHz input clock
		TRIGER =>en_SOUT_Tx,
		UART_TXD => uart_txd_sout,
		SEND_READY_TX=>send_ready_tx_sout,
		UART_TXD_W => uart_txd_Sout_vec
	);            
END Behavioral;
------------------------------------------------------
-- Author: Ashish Gautam
-- Title: NeuroCoreX
-- Simulate a network of N all-to-all connected Turning complete LIF neurons with exponential current-based synapse 
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
--		CLK_LIF : IN STD_LOGIC;
		UART_RXD : IN STD_LOGIC;  -- UART receiver pin
		UART_TXD : OUT STD_LOGIC  -- UART transmitter pin
	);
END main;

ARCHITECTURE Behavioral OF main IS

    -- clock generator 
    -- generate 100 MHz clock from on-board 12MHz clock
--	COMPONENT clk_wiz_0
--		PORT (
--			clk_in1 : IN STD_LOGIC;
--			clk_out1 : OUT STD_LOGIC
--		);
--	END COMPONENT;

    -- generate triger signal that becomes 1 every 0.1 ms
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
               DATA_OUT_WEIGHT_FF : out STD_LOGIC_VECTOR (7 downto 0);
               DATA_OUT_WEIGHT_AA: out STD_LOGIC_VECTOR (7 downto 0);
               DATA_OUT_SPIKE_ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
               FLAG_OVERFLOW: out STD_LOGIC;
               FLAG_UNDERFLOW: out STD_LOGIC;
               WRITE_EN_FF_W : out STD_LOGIC;
               WRITE_EN_AA_W : out STD_LOGIC;
               WRITE_EN_INPUT : out STD_LOGIC;
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
            --TRIGGER_UART_FIFO:OUT STD_LOGIC;
            UART_RXD_I : IN SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
            NEURON_ADDRESS: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            WEIGHT_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            WEIGHT_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            EN_LOAD_FF_W: IN STD_LOGIC;
            EN_LOAD_AA_W: IN STD_LOGIC;
            UART_TXD_V : OUT SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
            UART_TXD_I : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0)
--            ACTIVATE_TRIGGER : IN STD_LOGIC 
        );
	END COMPONENT;
 
    -- UART transmitter
    -- transmit v and I 
    -- v is a membrane potential of the target neuron
    -- I is the input stimulus received at the receiver and given to the neuron
    -- both signals are represented by 18-bit and encoded into 3 byte data through UART communication
    -- signals are sent every 0.1 ms
	COMPONENT v_transmitter
		PORT (
			clk : IN STD_LOGIC;
			triger : IN STD_LOGIC;
			uart_txd : OUT STD_LOGIC;
			uart_txd_v : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
			uart_txd_I : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0)
		);
	END COMPONENT;
 
    -- UART receiver
    -- receive I (stimulus input)
--	COMPONENT I_receiver
--		PORT (
--			clk : IN STD_LOGIC;
--			triger : IN STD_LOGIC;
--			uart_rxd : IN STD_LOGIC;
--			uart_rxd_I : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0)
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
	
	SIGNAL clk100, clk_lif_100k : STD_LOGIC:= '0';
	SIGNAL triger, trig_fifo, trig_triger, rst : STD_LOGIC := '0';
	SIGNAL uart_rxd_I : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_rxd_I_S: SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_txd_v : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	signal uart_txd_v_std : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 downto 0);  -- Converted output
    SIGNAL uart_txd_I : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S_in : STD_LOGIC := '0';
--    CONSTANT N_IN : NATURAL := 100;
    SIGNAL uart_byte_ready : STD_LOGIC := '0';
    SIGNAL uart_recieved_message : STD_LOGIC_VECTOR(7 DOWNTO 0):= (OTHERS => '0');
    SIGNAL flag_under_flow, flag_over_flow : STD_LOGIC := '0';
    SIGNAL en_FF_W_read, en_AA_W_read, en_Input, en_Input_streched : STD_LOGIC := '0';
    SIGNAL N_address : STD_LOGIC_VECTOR(15 DOWNTO 0):= (OTHERS => '0');
--    TYPE row_vector is array (0 to N_IN) of SIGNED(17 downto 0);
--    TYPE MATRIX is array (0 to N_IN) of row_vector;

    --SIGNAL weight_lat : weight_matrix_lat := (others => (others => "000000000000000001"));
--    SIGNAL WEIGHT_FF_MATRIX : MATRIX := 
--    (4 => (others => "000000000000000001"), -- Initialize the fifth row with the value --0x11
--    others => (others =>"000000000000000001")); -- Initialize all other elements to 0 --0x03
--    SIGNAL array_x_index : INTEGER:=0;
--    SIGNAL array_y_index : INTEGER:=0;
    SIGNAL weight_ff : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL weight_aa : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    
BEGIN
    uart_txd_v_std<=std_logic_vector(uart_txd_v);
    uart_rxd_I_S <= signed(UART_RXD_I);

    clk100<=clk;
--    clk_lif_100k<=clk_div_out;
   

--    inst_clk: clk_wiz_0
--    port map(
--        clk_in1 => CLK,
--        clk_out1 => clk100
--        );

	LIF_unit_0 : LIF_unit
	PORT MAP(
		clk => clk_lif_100k, 
		clk100M=>clk100,
		en_Input=> en_Input,
		spike_in => en_Input_streched,
		--TRIGGER_UART_FIFO=>trig_fifo,
		triger => triger, 
		uart_rxd_I => uart_rxd_I_S,
        neuron_address => N_address,
        weight_aa => weight_aa,
        weight_ff => weight_ff,
        en_load_ff_w =>en_FF_W_read,
        en_load_aa_w =>en_AA_W_read,
		uart_txd_v => uart_txd_v, 
		uart_txd_I => uart_txd_I
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
--        TRIGER_UART_FIFO=> TRIGGER_UART_FIFO,
		ACTIVATE_TRIGER=> trig_triger
	);
	v_transmitter_0 : v_transmitter
	PORT MAP(
		clk => clk100, 
		triger => triger, 
		uart_txd => uart_txd, 
		uart_txd_v => uart_txd_v_std,
		uart_txd_I => uart_txd_I
	); 
 
--	I_receiver_0 : I_receiver
--	PORT MAP(
--		clk => clk100, 
--		triger => triger, 
--	    uart_rxd => uart_rxd, 
--		uart_rxd_I => uart_rxd_I
--	); 
	
--	--Component used to recieve a byte of data over a UART line.
    Inst_UART_RX_CTRL: UART_RX_CTRL port map(
        UART_RX => uart_rxd,
        CLK => CLK100,
        DATA => uart_recieved_message,
        READ_DATA => uart_byte_ready
    );
--    --uartRX <= UART_RXD;
     Inst_UART_RX_SORTER_INPUT: UART_RX_SORTER_Input 
     PORT MAP(
            CLK => clk100,
            DATA_IN => uart_recieved_message,
            READ_EN => uart_byte_ready,
            ACTIVATE_FIFO => trig_fifo,
            DATA_OUT_WEIGHT_FF => weight_ff,
            DATA_OUT_WEIGHT_AA => weight_aa,
            DATA_OUT_SPIKE_ADDRESS => N_address,

            FLAG_OVERFLOW => flag_over_flow,
            FLAG_UNDERFLOW => flag_under_flow,
            WRITE_EN_FF_W =>en_FF_W_read,
            WRITE_EN_AA_W => en_AA_W_read,
            WRITE_EN_INPUT => en_Input,
            ACTIVATE_TRIGER => trig_triger
            );
    Inst_Clk_div: Clock_Divider
    PORT MAP (
        clk_in  =>clk100,  -- 100 MHz input clock
        rst     =>rst,  -- Reset signal
        clk_out =>clk_lif_100k   -- 100 kHz output clock
        );
            
END Behavioral;
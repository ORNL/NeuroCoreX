----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LIF_unit is
	GENERIC (clif_BIT_WIDTH : NATURAL := 18);
	PORT (
		CLK : IN STD_LOGIC;
		CLK100M: IN STD_LOGIC;
		en_Input: IN STD_LOGIC;
		SPIKE_IN : IN STD_LOGIC;
		TRIGER : IN STD_LOGIC;
		START_TRIGER : IN STD_LOGIC;
		RESET_TRIGER: IN STD_LOGIC;
		READ_WEIGHT: IN STD_LOGIC;
        --TRIGGER_UART_FIFO:OUT STD_LOGIC;
		UART_RXD_I : IN SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
		NEURON_ADDRESS: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		WEIGHT_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        WEIGHT_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        N_PARAM_IN : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
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
        WRITE_WEIGHT_AA_Tx: OUT STD_LOGIC;
		UART_TXD_V : OUT SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
		UART_TXD_I : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
		Spike_OUT_Tx : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		en_SOUT_Tx: OUT STD_LOGIC;
		en_flag_READ_DONE : OUT STD_LOGIC
--        ACTIVATE_TRIGGER : IN STD_LOGIC 
	);
end LIF_unit;

architecture Behavioral of LIF_unit is

    COMPONENT NEUROCORE_ENGINE is
        PORT(
            CLK : IN STD_LOGIC;
            CLK100M: IN STD_LOGIC;
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
--            PORT_vthr_in : IN SIGNED(17 DOWNTO 0);
--            PORT_vtheta_in : IN SIGNED(17 DOWNTO 0);
--            PORT_tcount_in: IN SIGNED(17 DOWNTO 0);
            PORT_Weight_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            PORT_Weight_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            PORT_Param_in : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
            PORT_STDP_Data_flag : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            En_Weight_AA: IN STD_LOGIC;
            EN_READ_AA_W: IN STD_LOGIC;
            En_Weight_FF: IN STD_LOGIC;
            En_Param_Load: IN STD_LOGIC;
            En_STDP_Data_Flag: IN STD_LOGIC;
            En_READ_WEIGHT: IN STD_LOGIC;
            PORT_vout : OUT SIGNED(17 DOWNTO 0);
            PORT_ILA_DEBUG: OUT SIGNED (7 DOWNTO 0);
            PORT_WEIGHT_AA_TX:  OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            PORT_Write_Weight_AA_TX: OUT STD_LOGIC;
--            PORT_vthr_out : OUT SIGNED(17 DOWNTO 0);
--            PORT_vtheta_out : OUT SIGNED(17 DOWNTO 0);
--            PORT_tcount_out: OUT SIGNED(17 DOWNTO 0);
            PORT_Isyn_out : OUT SIGNED(17 DOWNTO 0);
            PORT_Isyn_out_FF : OUT SIGNED(17 DOWNTO 0);
            PORT_Spike_out : OUT STD_LOGIC;
            PORT_flag_READ_DONE : OUT STD_LOGIC
            
        );
        END COMPONENT;
        
    COMPONENT fifo_generator_1 IS
        PORT (
            clk : IN STD_LOGIC;
            srst : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
--            data_count : OUT SIGNED(13 DOWNTO 0)
        );
    END COMPONENT;
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
        
	CONSTANT N0 : NATURAL := 90; --14;--94-- number of neurons in one instance
	SIGNAL counter0 : STD_LOGIC_VECTOR(14 DOWNTO 0) := (OTHERS => '0');
	SIGNAL Iin : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL vin : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL vout : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL spike_flag : STD_LOGIC := '0';
	SIGNAL fifo_srst : STD_LOGIC := '0';
	SIGNAL fifo_wr_en : STD_LOGIC:= '0';
	SIGNAL fifo_rd_en : STD_LOGIC:= '0';
	SIGNAL fifo_v_full, fifo_Isyn_full, fifo_Isyn_full_FF : STD_LOGIC:= '0';
	SIGNAL fifo_v_empty, fifo_Isyn_empty, fifo_Isyn_empty_FF : STD_LOGIC:= '0';
	SIGNAL fifo_v_din, fifo_Isyn_din, fifo_Isyn_din_FF : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL fifo_v_dout, fifo_Isyn_dout, fifo_Isyn_dout_FF : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL fifo_v_din_std, fifo_Isyn_din_std, fifo_Isyn_din_FF_std : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL fifo_v_dout_std, fifo_Isyn_dout_std, fifo_Isyn_dout_FF_std : STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	
	SIGNAL fifo_v_data_count, fifo_Isyn_data_count, fifo_Isyn_data_count_FF : SIGNED(13 DOWNTO 0) := (OTHERS => '0');
	SIGNAL S_in,S_in_latch,S_in_L : STD_LOGIC :='0';
--	SIGNAL vthr_in : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL vtheta_in : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL tcount_in : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL vthr_out : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL vtheta_out : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL tcount_out:  SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL Isyn_in, Isyn_in_FF:  SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL Isyn_out, Isyn_out_FF:  SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL sout: STD_LOGIC := '0';
	SIGNAL TRIGGER: STD_LOGIC :='0';
	SIGNAL NEURON_ADDR : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL I_bias :SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := "000000000001011100";
	SIGNAL I_bias_std :STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0) := "000000000001011100";
	SIGNAL N_debug : UNSIGNED(7 DOWNTO 0) := "00000001";--Neuron whose membrane potential, you want to plot
	SIGNAL N_debug_int:  INTEGER RANGE 0 TO N0+7 := 1;
	

	TYPE STATE_TYPE IS (SYNC_RESET_A, SYNC_RESET_B, SET, READY, RUN);
	SIGNAL STATE : STATE_TYPE := SET;
	SIGNAL FLAG_Sin: STD_LOGIC := '0';
	SIGNAL All_Zeros : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := "000000000000000000";
	TYPE DEBUG_PARAM is array (0 to 2) of STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL DEBUG_PARAMS : DEBUG_PARAM := (others => (others => '0'));
    SIGNAL DEBUG_INDEX: INTEGER range 0 to 3 := 0;
    signal NUM_DEBUG_PARAM : INTEGER range 0 to 3 := 2;
    signal spike_buffer : std_logic_vector(7 downto 0) := (others => '0');
    signal spike_index : integer range 0 to N0-1 := 0;
    signal byte_ready : std_logic := '0';
    signal byte_count : integer range 0 to 1024 := 0;
    signal fifo_Spike_IN, fifo_Spike_OUT, Spike_OUT_Tx_vec: std_logic_vector(7 downto 0) := (others => '0');
	signal fifo_wr_en_Spike, fifo_rd_en_Spike, fifo_Spike_full, fifo_Spike_empty, fifo_Spike_srst,en_SOUT_Tx_int: std_logic := '0';
    signal en_SOUT_Tx_int_sync      : std_logic_vector(1 downto 0) := (others => '1');  -- initialize to '1'
    signal en_SOUT_Tx_falling_edge, read_pending_A, read_pending_B  : std_logic := '0';
    signal fifo_wr_en_Spike_last : std_logic := '0';
--    signal start_trigger : std_logic := '0';
        -- Signals
    constant CLOCKS_PER_TRIGGER : integer := 10;  -- 11 us at 100 MHz
--    constant N1 : integer := 19;  -- for example
--    constant TRIGGER_COUNT_MAX : integer := (N1 + 1) * (N1 + 1);  -- 400 for N1=19        
    signal trigger_counter : integer range 0 to CLOCKS_PER_TRIGGER := 0;
    signal trigger_count   : integer := 0;
    signal trigger_active  : std_logic := '0';
    signal trigger_pulse, begin_trigger, spike_ready_next: std_logic := '0';
    signal send_start_marker : std_logic := '1'; 

  

begin
    trigger<=triger;
    N_debug_int<=to_integer(N_debug);
    fifo_v_dout<=signed(fifo_v_dout_std);
    fifo_v_din_std<=std_logic_vector(fifo_v_din);
    
    fifo_Isyn_dout<=signed(fifo_Isyn_dout_std);
    fifo_Isyn_din_std<=std_logic_vector(fifo_Isyn_din);
    
    fifo_Isyn_dout_FF<=signed(fifo_Isyn_dout_FF_std);
    fifo_Isyn_din_FF_std<=std_logic_vector(fifo_Isyn_din_FF);
    I_bias_std <=std_logic_vector(I_bias);
    Spike_OUT_Tx <= Spike_OUT_Tx_vec;
    en_SOUT_Tx <= en_SOUT_Tx_falling_edge;

	Core_0 : NEUROCORE_ENGINE
	PORT MAP(
		clk => CLK, 
		clk100M=>clk100M,
		en_Input=>en_Input,
		NA_weight_loader=>NEURON_ADDRESS,
		TRIGER => trigger,
		ACT_TRIGER => START_TRIGER,
		PORT_Spike_in => S_in,
		PORT_Neuron_Addr => Neuron_Addr,
		PORT_Isyn_in => Isyn_in,
		PORT_Isyn_in_FF=> Isyn_in_FF,
		PORT_Iin => Iin, 
		PORT_vin => vin, 
--		PORT_vthr_in =>vthr_in,
--		PORT_vtheta_in =>vtheta_in,
--		PORT_tcount_in =>tcount_in,
		PORT_Weight_AA => weight_AA,
		PORT_Weight_FF => weight_FF,
		PORT_Param_in => N_Param_in,
		PORT_STDP_Data_flag =>N_STDP_FLAG_D_IN,
        En_Weight_AA => EN_LOAD_AA_W,
        EN_READ_AA_W => EN_READ_AA_W,
        En_Weight_FF =>EN_LOAD_FF_W,
        En_Param_Load => En_LOAD_N_PARAM,
        En_STDP_Data_Flag=>EN_LOAD_N_STDP_FLAG,
        En_READ_WEIGHT => READ_WEIGHT,
		PORT_vout => vout,
		PORT_ILA_DEBUG => ila_debug,
		PORT_WEIGHT_AA_TX => WEIGHT_AA_TX,
		PORT_WRITE_WEIGHT_AA_Tx => Write_Weight_AA_TX,
--		PORT_vthr_out =>vthr_out,
--		PORT_vtheta_out =>vtheta_out,
--		PORT_tcount_out =>tcount_out,
		PORT_Isyn_out =>Isyn_out,
		PORT_Isyn_out_FF=> Isyn_out_FF,
		PORT_Spike_out => sout,
		PORT_flag_READ_DONE=>en_flag_READ_DONE
		);
		
    -- LIF unit control
    lif_ctrl : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            CASE STATE IS
                WHEN SYNC_RESET_A=>
                    fifo_srst<='0';
			        vin <= All_zeros;
                    Isyn_in <= All_zeros;
                    Isyn_in_FF <= All_zeros;
                    fifo_wr_en <= '0';
                    send_start_marker <= '1';
			        STATE<=SYNC_RESET_B; 
				WHEN SET => 
				    IF (counter0 = N0-1) THEN
				        fifo_v_din <= (OTHERS => '0');
				        counter0 <= counter0 + 1;
					ELSIF (counter0 < N0) THEN
						counter0 <= counter0 + 1;
						fifo_wr_en <= '1';
						fifo_rd_en <= '0';
						fifo_v_din <= (OTHERS => '0');
						fifo_Isyn_din <= (OTHERS => '0');
						fifo_Isyn_din_FF <= (OTHERS => '0');
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '0';
						fifo_v_din <= "000000000000000000";
						STATE <= READY;
					END IF;
                WHEN SYNC_RESET_B => 
                    IF (counter0 < N0) THEN
                        counter0 <= counter0 + 1;
                        fifo_rd_en <= '1';
                        fifo_wr_en <= '1';
                        fifo_v_din <= (OTHERS => '0');--write v-fifo with zeors for N0 count
						fifo_Isyn_din <= (OTHERS => '0');--write I-fifo with zeors for N0 count
						fifo_Isyn_din_FF <= (OTHERS => '0');
                    ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '0';
						fifo_v_din <= "000000000000000000";
						STATE <= READY;
					END IF;
				WHEN READY => 
					IF (TRIGGER = '1') THEN 
						fifo_rd_en <= '1';
						STATE <= RUN;
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '0';
						UART_TXD_V <= (OTHERS => '0');
						UART_TXD_I <= (OTHERS => '0');
					END IF;
				WHEN RUN => 
					IF (counter0 < N0 + 5) THEN
						counter0 <= counter0 + 1;
						
						IF (counter0 = 1) THEN
						  S_in<=Spike_IN;--This timing must be coordinated with the input data stream from PC
						  NEURON_ADDR<=NEURON_ADDRESS;
                            
						ELSE
							S_in <= '0';
							NEURON_ADDR<=(OTHERS => '0');
						END IF;
                        IF (counter0=N_debug_int) THEN
                            Iin <= I_bias;--"000000000001011100";
                            UART_TXD_V <= fifo_v_dout;
                            UART_TXD_I <= fifo_Isyn_dout_FF_std; --I_bias_std;--"000000000001011100";
                        ELSE
                            Iin <= (OTHERS => '0');--"000000000001011100";
                        END IF;

						IF (counter0 < N0 - 1) THEN
							fifo_rd_en <= '1';
						ELSE
							fifo_rd_en <= '0';
						END IF;
						IF (counter0 < N0 + 1 AND counter0 > 0) THEN
							vin <= fifo_v_dout;
							Isyn_in <= fifo_Isyn_dout;
							Isyn_in_FF <= fifo_Isyn_dout_FF;
						END IF;
						IF START_TRIGER='0' and counter0= N0+4 then
                            counter0<=(others=>'0');  
                            STATE <= SYNC_RESET_A;  
							spike_index <=0;
							fifo_wr_en_Spike <= '0';
						ELSIF (counter0 >= 5) THEN --AND (START_TRIGER='1') 
							fifo_wr_en <= '1';
							fifo_v_din <= vout;
							fifo_Isyn_din <= Isyn_out;
							fifo_Isyn_din_FF <= Isyn_out_FF;
 
                            -- Assign spike bit to buffer
                        spike_buffer(spike_index) <= sout;
                        
                        if spike_index = 7 then
                            spike_ready_next <= '1';  -- signal that buffer is ready next cycle
                            spike_index <= 0;
                        else
                            spike_ready_next <= '0';
                            spike_index <= spike_index + 1;
                        end if;
                        -- Separate stage to push to FIFO once buffer is complete
                        if send_start_marker = '1' and spike_ready_next = '0' then
                            fifo_Spike_IN <= (others => '1'); -- 0xFF = all 1's
                            fifo_wr_en_Spike <= '1';
                            send_start_marker <= '0';
                        elsif spike_ready_next = '1' then
                          fifo_Spike_IN <= spike_buffer;
                          fifo_wr_en_Spike <= '1';
                        else
                          fifo_wr_en_Spike <= '0';
                        end if;
                                                  
                                      
						ELSE
							fifo_wr_en <= '0';
							fifo_wr_en_Spike<= '0';
							fifo_v_din <= (others=>'0');
							fifo_Isyn_din <= (others=>'0');
							fifo_Isyn_din_FF <= (others=>'0');
						END IF;
						
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '1';
						fifo_wr_en_Spike<= '0';
                        UART_TXD_V <= (OTHERS => '0');
						UART_TXD_I <= (OTHERS => '0');
					END IF;
				WHEN OTHERS => 
					STATE <= READY;
			END CASE;
		END IF;
	END PROCESS;
	

    Neuron_debug_loaders : PROCESS(CLK100M)
    BEGIN
        IF rising_edge(CLK100M) THEN
            if (EN_LOAD_N_DEBUG = '1' and debug_index<NUM_DEBUG_PARAM) then                
                DEBUG_PARAMS(debug_index)<=N_DEBUG_IN;
                debug_index<=debug_index+1;
            elsif debug_index=2 then
                debug_index<=0;                              
            end if;
        END IF;
    END PROCESS;  
    I_bias<=signed(DEBUG_PARAMS(0));
    N_debug<=unsigned(DEBUG_PARAMS(1)(7 downto 0));

    Spike_transmitter : PROCESS(CLK)
    BEGIN
        IF rising_edge(CLK) THEN
    
            -- Generate 1-cycle pulse and wait one cycle for valid FIFO output
            IF read_pending_A = '1' THEN
--                Spike_OUT_Tx_vec <= fifo_Spike_OUT;  -- valid data now
--                en_SOUT_Tx_int    <= '1';
                fifo_rd_en_Spike  <= '0';
                read_pending_A      <= '0';
                read_pending_B      <= '1';
            ELSIF read_pending_B = '1' THEN
                Spike_OUT_Tx_vec <= fifo_Spike_OUT;  -- valid data now
                en_SOUT_Tx_int    <= '1';
                fifo_rd_en_Spike  <= '0';
                read_pending_B      <= '0';    
            ELSIF fifo_Spike_empty = '0' and send_ready_sout='1' THEN
                fifo_rd_en_Spike  <= '1';  -- read enable pulse
                read_pending_A      <= '1';  -- set flag to read data next cycle
                en_SOUT_Tx_int    <= '0';  -- wait to set it high until data is valid
    
            ELSE
                fifo_rd_en_Spike  <= '0';
                en_SOUT_Tx_int    <= '0';
                read_pending_A      <= '0';
                read_pending_B      <= '0';
            END IF;
    
        END IF;
    END PROCESS;
    
    
    process(clk100M)
    begin
        if rising_edge(clk100M) then
            -- 2-stage synchronizer
            en_SOUT_Tx_int_sync(0) <= en_SOUT_Tx_int;
            en_SOUT_Tx_int_sync(1) <= en_SOUT_Tx_int_sync(0);
    
            -- Falling edge detection
            if en_SOUT_Tx_int_sync(1) = '1' and en_SOUT_Tx_int_sync(0) = '0' then
                en_SOUT_Tx_falling_edge <= '1';  -- 1-cycle pulse
            else
                en_SOUT_Tx_falling_edge <= '0';
            end if;
        end if;
    end process;
    
	fifo_v : fifo_generator_1
	PORT MAP(
		clk => CLK, 
		srst => fifo_srst, 
		din => fifo_v_din_std, 
		wr_en => fifo_wr_en, 
		rd_en => fifo_rd_en, 
		dout => fifo_v_dout_std, 
		full => fifo_v_full, 
		empty => fifo_v_empty 
--		data_count => fifo_v_data_count
	);

	fifo_Isyn : fifo_generator_1
	PORT MAP(
		clk => CLK, 
		srst => fifo_srst, 
		din => fifo_Isyn_din_std, 
		wr_en => fifo_wr_en, 
		rd_en => fifo_rd_en, 
		dout => fifo_Isyn_dout_std, 
		full => fifo_Isyn_full, 
		empty => fifo_Isyn_empty 
--		data_count => fifo_Isyn_data_count
	);
	
    fifo_Isyn_FF : fifo_generator_1
	PORT MAP(
		clk => CLK, 
		srst => fifo_srst, 
		din => fifo_Isyn_din_FF_std, 
		wr_en => fifo_wr_en, 
		rd_en => fifo_rd_en, 
		dout => fifo_Isyn_dout_FF_std, 
		full => fifo_Isyn_full_FF, 
		empty => fifo_Isyn_empty_FF 
--		data_count => fifo_Isyn_data_count_FF
	);
	--S_in<=SPIKE_IN;

    fifo_Spike_Tx : fifo_generator_2
	PORT MAP(
		clk => CLK, 
		srst => fifo_Spike_srst, 
		din => fifo_Spike_IN, 
		wr_en => fifo_wr_en_Spike, 
		rd_en => fifo_rd_en_Spike, 
		dout => fifo_Spike_OUT, 
		full => fifo_Spike_full, 
		empty => fifo_Spike_empty 
--		data_count => fifo_Isyn_data_count_FF
	);	
end Behavioral;
    
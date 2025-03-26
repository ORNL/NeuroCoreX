----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/15/2024 10:09:01 PM
-- Design Name: 
-- Module Name: LIF_unit - Behavioral
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
        --TRIGGER_UART_FIFO:OUT STD_LOGIC;
		UART_RXD_I : IN SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
		NEURON_ADDRESS: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		WEIGHT_AA: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        WEIGHT_FF: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        EN_LOAD_FF_W: IN STD_LOGIC;
        EN_LOAD_AA_W: IN STD_LOGIC;
		UART_TXD_V : OUT SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0);
		UART_TXD_I : OUT STD_LOGIC_VECTOR(CLIF_BIT_WIDTH-1 DOWNTO 0)
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
            En_Weight_AA: IN STD_LOGIC;
            En_Weight_FF: IN STD_LOGIC;
            PORT_vout : OUT SIGNED(17 DOWNTO 0);
--            PORT_vthr_out : OUT SIGNED(17 DOWNTO 0);
--            PORT_vtheta_out : OUT SIGNED(17 DOWNTO 0);
--            PORT_tcount_out: OUT SIGNED(17 DOWNTO 0);
            PORT_Isyn_out : OUT SIGNED(17 DOWNTO 0);
            PORT_Isyn_out_FF : OUT SIGNED(17 DOWNTO 0);
            PORT_Spike_out : OUT STD_LOGIC
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
    
--    COMPONENT triger_generator IS
--	PORT (
--		CLK : IN STD_LOGIC;
--		TRIGER : OUT STD_LOGIC;
----		TRIGER_UART_FIFO:OUT STD_LOGIC;
--		ACTIVATE_TRIGER : IN STD_LOGIC
--	);
--    END COMPONENT;
        
	CONSTANT N0 : NATURAL := 14;--9994-- number of neurons in one instance
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
	SIGNAL vthr_in : SIGNED(CLIF_BIT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
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
--	SIGNAL NEURON_ADDR_LATCH : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	--SIGNAL weight_aa_in, weight_ff_in :STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
--	SIGNAL en_AA, en_FF: STD_LOGIC:='0';
	

	TYPE STATE_TYPE IS (SET, READY, RUN);
	SIGNAL STATE : STATE_TYPE := SET;
	SIGNAL FLAG_Sin: STD_LOGIC := '0';
begin
    trigger<=triger;
    fifo_v_dout<=signed(fifo_v_dout_std);
    fifo_v_din_std<=std_logic_vector(fifo_v_din);
    
    fifo_Isyn_dout<=signed(fifo_Isyn_dout_std);
    fifo_Isyn_din_std<=std_logic_vector(fifo_Isyn_din);

    fifo_Isyn_dout_FF<=signed(fifo_Isyn_dout_FF_std);
    fifo_Isyn_din_FF_std<=std_logic_vector(fifo_Isyn_din_FF);

	Core_0 : NEUROCORE_ENGINE
	PORT MAP(
		clk => CLK, 
		clk100M=>clk100M,
		en_Input=>'0',--en_Input,
		NA_weight_loader=>NEURON_ADDRESS,
		TRIGER => trigger,
		PORT_Spike_in => '0',--S_in,
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
        En_Weight_AA => EN_LOAD_AA_W,
        En_Weight_FF =>EN_LOAD_FF_W,
		PORT_vout => vout,
--		PORT_vthr_out =>vthr_out,
--		PORT_vtheta_out =>vtheta_out,
--		PORT_tcount_out =>tcount_out,
		PORT_Isyn_out =>Isyn_out,
		PORT_Isyn_out_FF=> Isyn_out_FF,
		PORT_Spike_out => sout);
		
--    Trig_0 : triger_generator
--    PORT MAP(
--		CLK => CLK,
--		TRIGER => TRIGGER,
----        TRIGER_UART_FIFO=> TRIGGER_UART_FIFO,
--		ACTIVATE_TRIGER=> ACTIVATE_TRIGGER
--	);
	
	
    -- LIF unit control
	lif_ctrl : PROCESS (CLK)
	BEGIN
		IF (rising_edge(CLK)) THEN
			CASE STATE IS
				WHEN SET => 
				    IF (counter0 = N0-1) THEN
				        fifo_v_din <= (OTHERS => '0');
				        counter0 <= counter0 + 1;
					ELSIF (counter0 < N0) THEN
						counter0 <= counter0 + 1;
						fifo_wr_en <= '1';
						fifo_rd_en <= '0';
						fifo_v_din <= (OTHERS => '0');--write v-fifo with zeors for N0 count
						fifo_Isyn_din <= (OTHERS => '0');--write I-fifo with zeors for N0 count
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '0';
						fifo_v_din <= "000000000000000000";
						STATE <= READY;--Goes here when fifo is filled with N0 number of 18 bit data
					END IF;
				WHEN READY => 
					IF (TRIGGER = '1') THEN--every 0.1 ms
						fifo_rd_en <= '1';
						STATE <= RUN;
--						NEURON_ADDR_LATCH<=NEURON_ADDRESS;
--						S_in_latch <=Spike_IN;
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '0';
					END IF;
				WHEN RUN => 
					IF (counter0 < N0 + 5) THEN
						counter0 <= counter0 + 1;
						
						IF (counter0 = 1) THEN
						  S_in<=Spike_IN;--This timing must be coordinated with the input data stream from PC
						  NEURON_ADDR<=NEURON_ADDRESS;--This timing must be coordinated with the input data stream from PC
                          UART_TXD_V <= fifo_v_dout;
                          UART_TXD_I <= "000000000001011100";
						  Iin <= "000000000001011100";--UART_RXD_I;--"000000000000000000"; --"000000000001011100"
--							IF FLAG_Sin='0' THEN
--							    S_in <= '1';
--							    FLAG_Sin<='1';
--                            END IF;
                        ELSIF (counter0=N0) THEN
                            Iin <= "000000000001011100";--"000000000001011100";
						ELSE
							Iin <= (OTHERS => '0');
							S_in <= '0';
							NEURON_ADDR<=(OTHERS => '0');
						END IF;
--						IF (counter0 = 2) THEN
--							UART_TXD_V <= fifo_v_dout;
--							UART_TXD_I <= "000000000000000000";--UART_RXD_I;"000000000001011100"
--							--Iin <= UART_RXD_I;
--						END IF;
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
						IF (counter0 >= 5) THEN
							fifo_wr_en <= '1';
							fifo_v_din <= vout;
							fifo_Isyn_din <= Isyn_out;
							fifo_Isyn_din_FF <= Isyn_out_FF;
						ELSE
							fifo_wr_en <= '0';
							fifo_v_din <= (others=>'0');
							fifo_Isyn_din <= (others=>'0');
							fifo_Isyn_din_FF <= (others=>'0');
						END IF;
					ELSE
						counter0 <= (OTHERS => '0');
						fifo_wr_en <= '0';
						fifo_rd_en <= '1';
						--STATE <= READY;
					END IF;
				WHEN OTHERS => 
					STATE <= READY;
			END CASE;
		END IF;
	END PROCESS;

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

	
end Behavioral;
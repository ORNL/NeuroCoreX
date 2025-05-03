## This file is a general .xdc for the CmodA7 rev. B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal 12 MHz
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports CLK]
create_clock -period 83.330 -name sys_clk_pin -waveform {0.000 41.660} -add [get_ports CLK]
#create_clock -name clk_lif_100k -period 10.0 [get_ports clk_out]
#create_generated_clock -name clk_out -source [get_pins <path_to_clk_in>] -divide_by 1000 [get_nets <path_to_clk_out>]
#create_generated_clock -name clk_out -source [get_nets clk_in] -divide_by 1000 [get_nets clk_out_BUFG]
#create_generated_clock -name clk_out -source [get_clocks clk_out1_clk_wiz_0] -divide_by 1000 [get_nets clk_out1]
#create_generated_clock -name clk_out -source [get_clocks clk_out1] -divide_by 1000 [get_nets clk_out]





# LEDs
#set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
#set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]

#set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports RGB0_Red]
#set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports RGB0_Green]
#set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports RGB0_Blue]


# Buttons
#set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {BTN[0]}]
#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {BTN[1]}]


## Pmod Header JA
#set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]; #IO_L5N_T0_D07_14 Sch=ja[1]
#set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]; #IO_L4N_T0_D05_14 Sch=ja[2]
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]; #IO_L9P_T1_DQS_14 Sch=ja[3]
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]; #IO_L8P_T1_D11_14 Sch=ja[4]
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]; #IO_L5P_T0_D06_14 Sch=ja[7]
#set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]; #IO_L4P_T0_D04_14 Sch=ja[8]
#set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]; #IO_L6N_T0_D08_VREF_14 Sch=ja[9]
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]; #IO_L8N_T1_D12_14 Sch=ja[10]


## Analog XADC Pins
## Only declare these if you want to use pins 15 and 16 as single ended analog inputs. pin 15 -> vaux4, pin16 -> vaux12
#set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports { xa_n[0] }]; #IO_L1N_T0_AD4N_35 Sch=ain_n[15]
#set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { xa_p[0] }]; #IO_L1P_T0_AD4P_35 Sch=ain_p[15]
#set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { xa_n[1] }]; #IO_L2N_T0_AD12N_35 Sch=ain_n[16]
#set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { xa_p[1] }]; #IO_L2P_T0_AD12P_35 Sch=ain_p[16]


## GPIO Pins
## Pins 15 and 16 should remain commented if using them as analog inputs
#set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports {PORTA[0]}]
#set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports {PORTA[1]}]
#set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {PORTA[2]}]
#set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {PORTA[3]}]
#set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {PORTA[4]}]
#set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {PORTA[5]}]
#set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {PORTA[6]}]
#set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {PORTA[7]}]
#set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {PORTB[0]}]
#set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {PORTB[1]}]
#set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {PORTB[2]}]
#set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {PORTB[3]}]
#set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {PORTB[4]}]
#set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports {PORTB[5]}]
#set_property -dict {PACKAGE_PIN M1 IOSTANDARD LVCMOS33} [get_ports {PORTB[6]}]
#set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports {PORTB[7]}]
#set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {PORTC[0]}]
#set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports {PORTC[1]}]
#set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports {PORTC[2]}]
#set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports {PORTC[3]}]
#set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {PORTC[4]}]
#set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports {PORTC[5]}]
#set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {PORTC[6]}]
#set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {PORTC[7]}]
#set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {PORTD[7]}]
#set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports {PORTD[6]}]
#set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {PORTD[5]}]
#set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports {PORTD[4]}]
#set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {PORTD[3]}]
#set_property -dict {PACKAGE_PIN W3 IOSTANDARD LVCMOS33} [get_ports {PORTD[2]}]
#set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports {PORTD[1]}]
#set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports {PORTD[0]}]
#set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {PORTE[7]}]
#set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {PORTE[6]}]
#set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {PORTE[5]}]
#set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {PORTE[4]}]
#set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {PORTE[3]}]
#set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {PORTE[2]}]
#set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {PORTE[1]}]
#set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports {PORTE[0]}]
#set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { pio[45]  }]; #IO_L19P_T3_34 Sch=pio[45]
#set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { pio[46]  }]; #IO_L13P_T2_MRCC_34 Sch=pio[46]
#set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {PORTF[1]}]
#set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {PORTF[0]}]


## UART
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports UART_TXD]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports UART_RXD]


## Crypto 1 Wire Interface
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { crypto_sda }]; #IO_0_14 Sch=crypto_sda


## QSPI
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs    }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]


## Cellular RAM
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[0]  }]; #IO_L11P_T1_SRCC_14 Sch=sram- a[0]
#set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[1]  }]; #IO_L11N_T1_SRCC_14 Sch=sram- a[1]
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[2]  }]; #IO_L12N_T1_MRCC_14 Sch=sram- a[2]
#set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[3]  }]; #IO_L13P_T2_MRCC_14 Sch=sram- a[3]
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[4]  }]; #IO_L13N_T2_MRCC_14 Sch=sram- a[4]
#set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[5]  }]; #IO_L14P_T2_SRCC_14 Sch=sram- a[5]
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[6]  }]; #IO_L14N_T2_SRCC_14 Sch=sram- a[6]
#set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[7]  }]; #IO_L16N_T2_A15_D31_14 Sch=sram- a[7]
#set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[8]  }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=sram- a[8]
#set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[9]  }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=sram- a[9]
#set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[10] }]; #IO_L16P_T2_CSI_B_14 Sch=sram- a[10]
#set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[11] }]; #IO_L17P_T2_A14_D30_14 Sch=sram- a[11]
#set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[12] }]; #IO_L17N_T2_A13_D29_14 Sch=sram- a[12]
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[13] }]; #IO_L18P_T2_A12_D28_14 Sch=sram- a[13]
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[14] }]; #IO_L18N_T2_A11_D27_14 Sch=sram- a[14]
#set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[15] }]; #IO_L19P_T3_A10_D26_14 Sch=sram- a[15]
#set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[16] }]; #IO_L20P_T3_A08_D24_14 Sch=sram- a[16]
#set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[17] }]; #IO_L20N_T3_A07_D23_14 Sch=sram- a[17]
#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[18] }]; #IO_L21P_T3_DQS_14 Sch=sram- a[18]
#set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { MemDB[0]   }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=sram-dq[0]
#set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { MemDB[1]   }]; #IO_L22P_T3_A05_D21_14 Sch=sram-dq[1]
#set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[2]   }]; #IO_L22N_T3_A04_D20_14 Sch=sram-dq[2]
#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { MemDB[3]   }]; #IO_L23P_T3_A03_D19_14 Sch=sram-dq[3]
#set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { MemDB[4]   }]; #IO_L23N_T3_A02_D18_14 Sch=sram-dq[4]
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { MemDB[5]   }]; #IO_L24P_T3_A01_D17_14 Sch=sram-dq[5]
#set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[6]   }]; #IO_L24N_T3_A00_D16_14 Sch=sram-dq[6]
#set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[7]   }]; #IO_25_14 Sch=sram-dq[7]
#set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { RamOEn     }]; #IO_L10P_T1_D14_14 Sch=sram-oe
#set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { RamWEn     }]; #IO_L10N_T1_D15_14 Sch=sram-we
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports { RamCEn     }]; #IO_L9N_T1_DQS_D13_14 Sch=sram-ce



#set_property MARK_DEBUG true [get_nets clk100MHz]
#set_property MARK_DEBUG true [get_nets UART_TXD_OBUF]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[3]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[6]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[5]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[2]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[0]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[4]}]
#set_property MARK_DEBUG true [get_nets {uartData_reg_n_0_[1]}]
#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list inst_clk/inst/clk_out1]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 1 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list clk100MHz]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 1 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list UART_TXD_OBUF]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 1 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list {uartData_reg_n_0_[0]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 1 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list {uartData_reg_n_0_[1]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 1 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list {uartData_reg_n_0_[2]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 1 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list {uartData_reg_n_0_[3]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
#set_property port_width 1 [get_debug_ports u_ila_0/probe6]
#connect_debug_port u_ila_0/probe6 [get_nets [list {uartData_reg_n_0_[4]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
#set_property port_width 1 [get_debug_ports u_ila_0/probe7]
#connect_debug_port u_ila_0/probe7 [get_nets [list {uartData_reg_n_0_[5]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
#set_property port_width 1 [get_debug_ports u_ila_0/probe8]
#connect_debug_port u_ila_0/probe8 [get_nets [list {uartData_reg_n_0_[6]}]]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk100]

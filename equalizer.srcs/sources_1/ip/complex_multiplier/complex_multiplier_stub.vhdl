-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Fri Aug 15 14:03:17 2025
-- Host        : LAPTOP-G48H7BNI running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               e:/vivado/test/OFDM_RX/OPENOFDM_RX/equalizer/equalizer.srcs/sources_1/ip/complex_multiplier/complex_multiplier_stub.vhdl
-- Design      : complex_multiplier
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity complex_multiplier is
  Port ( 
    aclk : in STD_LOGIC;
    s_axis_a_tvalid : in STD_LOGIC;
    s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axis_b_tvalid : in STD_LOGIC;
    s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axis_dout_tvalid : out STD_LOGIC;
    m_axis_dout_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

end complex_multiplier;

architecture stub of complex_multiplier is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aclk,s_axis_a_tvalid,s_axis_a_tdata[31:0],s_axis_b_tvalid,s_axis_b_tdata[31:0],m_axis_dout_tvalid,m_axis_dout_tdata[63:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "cmpy_v6_0_17,Vivado 2019.1";
begin
end;

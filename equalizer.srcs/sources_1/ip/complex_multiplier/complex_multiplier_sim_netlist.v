// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Fri Aug 15 14:03:17 2025
// Host        : LAPTOP-G48H7BNI running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               e:/vivado/test/OFDM_RX/OPENOFDM_RX/equalizer/equalizer.srcs/sources_1/ip/complex_multiplier/complex_multiplier_sim_netlist.v
// Design      : complex_multiplier
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z020clg400-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "complex_multiplier,cmpy_v6_0_17,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "cmpy_v6_0_17,Vivado 2019.1" *) 
(* NotValidForBitStream *)
module complex_multiplier
   (aclk,
    s_axis_a_tvalid,
    s_axis_a_tdata,
    s_axis_b_tvalid,
    s_axis_b_tdata,
    m_axis_dout_tvalid,
    m_axis_dout_tdata);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 aclk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME aclk_intf, ASSOCIATED_BUSIF S_AXIS_CTRL:S_AXIS_B:S_AXIS_A:M_AXIS_DOUT, ASSOCIATED_RESET aresetn, ASSOCIATED_CLKEN aclken, FREQ_HZ 10000000, PHASE 0.000, INSERT_VIP 0" *) input aclk;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 S_AXIS_A TVALID" *) (* x_interface_parameter = "XIL_INTERFACENAME S_AXIS_A, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.000, LAYERED_METADATA undef, INSERT_VIP 0" *) input s_axis_a_tvalid;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 S_AXIS_A TDATA" *) input [31:0]s_axis_a_tdata;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 S_AXIS_B TVALID" *) (* x_interface_parameter = "XIL_INTERFACENAME S_AXIS_B, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.000, LAYERED_METADATA undef, INSERT_VIP 0" *) input s_axis_b_tvalid;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 S_AXIS_B TDATA" *) input [31:0]s_axis_b_tdata;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TVALID" *) (* x_interface_parameter = "XIL_INTERFACENAME M_AXIS_DOUT, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.000, LAYERED_METADATA undef, INSERT_VIP 0" *) output m_axis_dout_tvalid;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TDATA" *) output [63:0]m_axis_dout_tdata;

  wire aclk;
  wire [63:0]m_axis_dout_tdata;
  wire m_axis_dout_tvalid;
  wire [31:0]s_axis_a_tdata;
  wire s_axis_a_tvalid;
  wire [31:0]s_axis_b_tdata;
  wire s_axis_b_tvalid;
  wire NLW_U0_m_axis_dout_tlast_UNCONNECTED;
  wire NLW_U0_s_axis_a_tready_UNCONNECTED;
  wire NLW_U0_s_axis_b_tready_UNCONNECTED;
  wire NLW_U0_s_axis_ctrl_tready_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_dout_tuser_UNCONNECTED;

  (* C_A_WIDTH = "16" *) 
  (* C_B_WIDTH = "16" *) 
  (* C_HAS_ACLKEN = "0" *) 
  (* C_HAS_ARESETN = "0" *) 
  (* C_HAS_S_AXIS_A_TLAST = "0" *) 
  (* C_HAS_S_AXIS_A_TUSER = "0" *) 
  (* C_HAS_S_AXIS_B_TLAST = "0" *) 
  (* C_HAS_S_AXIS_B_TUSER = "0" *) 
  (* C_HAS_S_AXIS_CTRL_TLAST = "0" *) 
  (* C_HAS_S_AXIS_CTRL_TUSER = "0" *) 
  (* C_LATENCY = "3" *) 
  (* C_MULT_TYPE = "1" *) 
  (* C_M_AXIS_DOUT_TDATA_WIDTH = "64" *) 
  (* C_M_AXIS_DOUT_TUSER_WIDTH = "1" *) 
  (* C_OPTIMIZE_GOAL = "1" *) 
  (* C_OUT_WIDTH = "32" *) 
  (* C_S_AXIS_A_TDATA_WIDTH = "32" *) 
  (* C_S_AXIS_A_TUSER_WIDTH = "1" *) 
  (* C_S_AXIS_B_TDATA_WIDTH = "32" *) 
  (* C_S_AXIS_B_TUSER_WIDTH = "1" *) 
  (* C_S_AXIS_CTRL_TDATA_WIDTH = "8" *) 
  (* C_S_AXIS_CTRL_TUSER_WIDTH = "1" *) 
  (* C_THROTTLE_SCHEME = "3" *) 
  (* C_TLAST_RESOLUTION = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICE = "xc7z020" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* HAS_NEGATE = "0" *) 
  (* ROUND = "0" *) 
  (* SINGLE_OUTPUT = "0" *) 
  (* USE_DSP_CASCADES = "1" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  complex_multiplier_cmpy_v6_0_17 U0
       (.aclk(aclk),
        .aclken(1'b1),
        .aresetn(1'b1),
        .m_axis_dout_tdata(m_axis_dout_tdata),
        .m_axis_dout_tlast(NLW_U0_m_axis_dout_tlast_UNCONNECTED),
        .m_axis_dout_tready(1'b0),
        .m_axis_dout_tuser(NLW_U0_m_axis_dout_tuser_UNCONNECTED[0]),
        .m_axis_dout_tvalid(m_axis_dout_tvalid),
        .s_axis_a_tdata(s_axis_a_tdata),
        .s_axis_a_tlast(1'b0),
        .s_axis_a_tready(NLW_U0_s_axis_a_tready_UNCONNECTED),
        .s_axis_a_tuser(1'b0),
        .s_axis_a_tvalid(s_axis_a_tvalid),
        .s_axis_b_tdata(s_axis_b_tdata),
        .s_axis_b_tlast(1'b0),
        .s_axis_b_tready(NLW_U0_s_axis_b_tready_UNCONNECTED),
        .s_axis_b_tuser(1'b0),
        .s_axis_b_tvalid(s_axis_b_tvalid),
        .s_axis_ctrl_tdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axis_ctrl_tlast(1'b0),
        .s_axis_ctrl_tready(NLW_U0_s_axis_ctrl_tready_UNCONNECTED),
        .s_axis_ctrl_tuser(1'b0),
        .s_axis_ctrl_tvalid(1'b0));
endmodule

(* C_A_WIDTH = "16" *) (* C_B_WIDTH = "16" *) (* C_HAS_ACLKEN = "0" *) 
(* C_HAS_ARESETN = "0" *) (* C_HAS_S_AXIS_A_TLAST = "0" *) (* C_HAS_S_AXIS_A_TUSER = "0" *) 
(* C_HAS_S_AXIS_B_TLAST = "0" *) (* C_HAS_S_AXIS_B_TUSER = "0" *) (* C_HAS_S_AXIS_CTRL_TLAST = "0" *) 
(* C_HAS_S_AXIS_CTRL_TUSER = "0" *) (* C_LATENCY = "3" *) (* C_MULT_TYPE = "1" *) 
(* C_M_AXIS_DOUT_TDATA_WIDTH = "64" *) (* C_M_AXIS_DOUT_TUSER_WIDTH = "1" *) (* C_OPTIMIZE_GOAL = "1" *) 
(* C_OUT_WIDTH = "32" *) (* C_S_AXIS_A_TDATA_WIDTH = "32" *) (* C_S_AXIS_A_TUSER_WIDTH = "1" *) 
(* C_S_AXIS_B_TDATA_WIDTH = "32" *) (* C_S_AXIS_B_TUSER_WIDTH = "1" *) (* C_S_AXIS_CTRL_TDATA_WIDTH = "8" *) 
(* C_S_AXIS_CTRL_TUSER_WIDTH = "1" *) (* C_THROTTLE_SCHEME = "3" *) (* C_TLAST_RESOLUTION = "0" *) 
(* C_VERBOSITY = "0" *) (* C_XDEVICE = "xc7z020" *) (* C_XDEVICEFAMILY = "zynq" *) 
(* HAS_NEGATE = "0" *) (* ORIG_REF_NAME = "cmpy_v6_0_17" *) (* ROUND = "0" *) 
(* SINGLE_OUTPUT = "0" *) (* USE_DSP_CASCADES = "1" *) (* downgradeipidentifiedwarnings = "yes" *) 
module complex_multiplier_cmpy_v6_0_17
   (aclk,
    aclken,
    aresetn,
    s_axis_a_tvalid,
    s_axis_a_tready,
    s_axis_a_tuser,
    s_axis_a_tlast,
    s_axis_a_tdata,
    s_axis_b_tvalid,
    s_axis_b_tready,
    s_axis_b_tuser,
    s_axis_b_tlast,
    s_axis_b_tdata,
    s_axis_ctrl_tvalid,
    s_axis_ctrl_tready,
    s_axis_ctrl_tuser,
    s_axis_ctrl_tlast,
    s_axis_ctrl_tdata,
    m_axis_dout_tvalid,
    m_axis_dout_tready,
    m_axis_dout_tuser,
    m_axis_dout_tlast,
    m_axis_dout_tdata);
  input aclk;
  input aclken;
  input aresetn;
  input s_axis_a_tvalid;
  output s_axis_a_tready;
  input [0:0]s_axis_a_tuser;
  input s_axis_a_tlast;
  input [31:0]s_axis_a_tdata;
  input s_axis_b_tvalid;
  output s_axis_b_tready;
  input [0:0]s_axis_b_tuser;
  input s_axis_b_tlast;
  input [31:0]s_axis_b_tdata;
  input s_axis_ctrl_tvalid;
  output s_axis_ctrl_tready;
  input [0:0]s_axis_ctrl_tuser;
  input s_axis_ctrl_tlast;
  input [7:0]s_axis_ctrl_tdata;
  output m_axis_dout_tvalid;
  input m_axis_dout_tready;
  output [0:0]m_axis_dout_tuser;
  output m_axis_dout_tlast;
  output [63:0]m_axis_dout_tdata;

  wire \<const0> ;
  wire aclk;
  wire [63:0]m_axis_dout_tdata;
  wire m_axis_dout_tvalid;
  wire [31:0]s_axis_a_tdata;
  wire s_axis_a_tvalid;
  wire [31:0]s_axis_b_tdata;
  wire s_axis_b_tvalid;
  wire NLW_i_synth_m_axis_dout_tlast_UNCONNECTED;
  wire NLW_i_synth_s_axis_a_tready_UNCONNECTED;
  wire NLW_i_synth_s_axis_b_tready_UNCONNECTED;
  wire NLW_i_synth_s_axis_ctrl_tready_UNCONNECTED;
  wire [0:0]NLW_i_synth_m_axis_dout_tuser_UNCONNECTED;

  assign m_axis_dout_tlast = \<const0> ;
  assign m_axis_dout_tuser[0] = \<const0> ;
  assign s_axis_a_tready = \<const0> ;
  assign s_axis_b_tready = \<const0> ;
  assign s_axis_ctrl_tready = \<const0> ;
  GND GND
       (.G(\<const0> ));
  (* C_A_WIDTH = "16" *) 
  (* C_B_WIDTH = "16" *) 
  (* C_HAS_ACLKEN = "0" *) 
  (* C_HAS_ARESETN = "0" *) 
  (* C_HAS_S_AXIS_A_TLAST = "0" *) 
  (* C_HAS_S_AXIS_A_TUSER = "0" *) 
  (* C_HAS_S_AXIS_B_TLAST = "0" *) 
  (* C_HAS_S_AXIS_B_TUSER = "0" *) 
  (* C_HAS_S_AXIS_CTRL_TLAST = "0" *) 
  (* C_HAS_S_AXIS_CTRL_TUSER = "0" *) 
  (* C_LATENCY = "3" *) 
  (* C_MULT_TYPE = "1" *) 
  (* C_M_AXIS_DOUT_TDATA_WIDTH = "64" *) 
  (* C_M_AXIS_DOUT_TUSER_WIDTH = "1" *) 
  (* C_OPTIMIZE_GOAL = "1" *) 
  (* C_OUT_WIDTH = "32" *) 
  (* C_S_AXIS_A_TDATA_WIDTH = "32" *) 
  (* C_S_AXIS_A_TUSER_WIDTH = "1" *) 
  (* C_S_AXIS_B_TDATA_WIDTH = "32" *) 
  (* C_S_AXIS_B_TUSER_WIDTH = "1" *) 
  (* C_S_AXIS_CTRL_TDATA_WIDTH = "8" *) 
  (* C_S_AXIS_CTRL_TUSER_WIDTH = "1" *) 
  (* C_THROTTLE_SCHEME = "3" *) 
  (* C_TLAST_RESOLUTION = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICE = "xc7z020" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* HAS_NEGATE = "0" *) 
  (* ROUND = "0" *) 
  (* SINGLE_OUTPUT = "0" *) 
  (* USE_DSP_CASCADES = "1" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  complex_multiplier_cmpy_v6_0_17_viv i_synth
       (.aclk(aclk),
        .aclken(1'b0),
        .aresetn(1'b0),
        .m_axis_dout_tdata(m_axis_dout_tdata),
        .m_axis_dout_tlast(NLW_i_synth_m_axis_dout_tlast_UNCONNECTED),
        .m_axis_dout_tready(1'b0),
        .m_axis_dout_tuser(NLW_i_synth_m_axis_dout_tuser_UNCONNECTED[0]),
        .m_axis_dout_tvalid(m_axis_dout_tvalid),
        .s_axis_a_tdata(s_axis_a_tdata),
        .s_axis_a_tlast(1'b0),
        .s_axis_a_tready(NLW_i_synth_s_axis_a_tready_UNCONNECTED),
        .s_axis_a_tuser(1'b0),
        .s_axis_a_tvalid(s_axis_a_tvalid),
        .s_axis_b_tdata(s_axis_b_tdata),
        .s_axis_b_tlast(1'b0),
        .s_axis_b_tready(NLW_i_synth_s_axis_b_tready_UNCONNECTED),
        .s_axis_b_tuser(1'b0),
        .s_axis_b_tvalid(s_axis_b_tvalid),
        .s_axis_ctrl_tdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axis_ctrl_tlast(1'b0),
        .s_axis_ctrl_tready(NLW_i_synth_s_axis_ctrl_tready_UNCONNECTED),
        .s_axis_ctrl_tuser(1'b0),
        .s_axis_ctrl_tvalid(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2019.1"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
GHj57reejxYFGgGc6LkZz4g/3YZfuX6BBkTzGzxAFmGxXPZd1ZfrKbFSB3Kf0vroWPybe1Gol0o0
+cBTpPNMBg==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
n9+vYOPSnFKvc6pC387PcTZwbrWT+fWkUrI+oOavbngpCWri68aZK9GGlCF/fJxpI66bPiAl6JZ6
V0t8HLKw5q3Xn/pbYkEKPXAR2BoblzdXXGtJQJvpNFuY0G2mZG0kNoQl+IMNuLIiBZS8ss2AOG9+
YqC36/azPiUO66xQRPQ=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mKEU/RLurfnQ+XE9PeT8SKIF6kPUMD2hMub4vB5Szp1294z0a2QlL5llChbu+pHRdcFIyUriIk3F
b22qgY5Cg8uaupKP3TJbx1GkqwJNGggQm59ipEctR7JtrEA8t3+400ih5/Bm2mBZiZ9x3G79mdev
3eWL7dgekLJ3/ChiFUQf3yQ4nYbNdjF48fHSCB67lz1con0XJ3J2egbb5E7dI0YxIBGQ2tIUUi5h
PWqTR27+iNjxuCmCjaKEb/vEpVr71h8sD4priNGny/o8QEr5/Mm0oYYSS2NoR/h0tdmb+uGKZoqH
vZQaO5HceAI/SDvkcV+g91N8O/5WrT+w+slOXQ==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
VWUegNSdBneRURRrY4DumXXk9XZp9PQK94dtnGjTkahp/e55rblm1jToZv6Jab0HWMcuq/CWOPlF
k18mSm/2y/RCM5TBpiVYGA/JKD7ThZRcGjKbiMVrcLEHH+Hy+3ucgoQYtVM/Zdo68TeDBkkOKq+b
8x7lRuWMdJseCvUzmfB0qyVqKCmzjXls8LAUj6vF1Ozvq9umIj8rrZ1LdSapD7n5wmJYOwyj3gbb
MhXwaZEDd+S5F+qIwwy3qyCFO5+ej0JMc7sHL45tMQ7txHQ6eitvpVFyWwinQZj9ujmzqEVb+bAR
vN8HBgcyPd8BeJ9P6zt4PVIerH925LlnNnhPYw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2019_02", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Cstmp5Bb8G6Bzy7V7zmMVktQNWslah06n4/OH8Gd0WlwpoMwqgyEr0Iika4vK3BqyIDD5LQlZnuM
kk+UuwYDypAcqydXYFIV4ts+GfY8gYi8XreHcjo/nWVpp0fSQmSM2ZtxfO5sZarVznUif75i6q+f
t0YLGOKwi0AF9RzLa03wJqxywP8cSfGOe6IUt6cquiFEzyppddiFL5D6luwl5RcQFluPwE+4im44
8xq+MC6MucWChnG6qlOECd5RwEZ+OeozKmH8LuzETRWoQJr1CC4sjBW67liynFphJVQZBaSMNehw
l3R938BnTORSBr7Ct4TVuxjD6rkn3nJAZe/fKg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
MxyGfhwOu3oss5K9NV7veV77843Ar77I9FFbUD+W2Pj9Z31LE/ruF/UjqV6LLUU0oP/iZamL75qr
HdwKcUjhS6jY2DMFps1AI+ucQtKZs21V8DpN5yaFgJxsDfuArIQaNK6g4v02B2OAAOc7fYiFZZSy
ydVicltaIM3fjRd16SE=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
OFXbv8BsHW2mJ0LkjBlH+1hDsMYZqsHN0pD/2KduWzbbuiFSTxEhjTOUxuu1T72XHB5hmOI7c2Wv
EezeIUzi+gkK7VcneKAOrd2KKpkWcyMFDmZk9g/3+uGLZTcvpsJGS5FeydCwE4nW05La5/zNSFJt
dJXxm5mGqVZtQ322fNaFXasMV+Z7HjTDs9S072EHwGGPwkoh3ySxtdsWHahI/m7SLIjN+Bg2loeW
Dvg27GzcHORDWnrZH/q02It7QOiqv8OMVPRJ9xYcqNXTfOCiZna8yJnA5DvCHFnzwlRxuI2Cqdnr
4xQ+xWwnzrtIu80IIxowrPF2NJorkrzBG+ncrQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
C7DYnFTAhTuokvH476I28La71xjFwLKZyIGOzM0t5f//Z7EjpYs8URTOYBtGMGzmL+fIqPukqDob
vLB1H0isTSL/TcceUkVWpguKwAJscj44faUuUyeRUfcuZfqayOEMQ0yJS8qqEQJahomam3W/9ftq
46zljlXhfNvWn5VQocwGya92uQCmgCUQ5CqNbTR0JDQsslv+Y3McEYt2Bkd6siGsqCoaoUhEbYtd
NZqVG8KAa6pL7qxDC4ZeBYILcEMXJkJ3hwJ65tNb5Gn2bVCtPmq24sh/xD8RRiEG178AHxPkkwqv
LotgLOLW7rVeFRWS4dp9hNQyCmR/wgCSGwMobw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
IsTmmVbxB1WwAzG3h4a7OZyj7eUZfxvYQ8dkvPwMKfopa37NyFnACJfy946eR5qtG4LTGql8meCT
hF2URZa06u3hJR6EWnkSfaSNX27BsUzd+urnv/5Lgk7CBC6FkM/DegP+L0rSQOnQet4CUdUFBnNr
kgzrKiRj/m/frtVjjIy0wHKzUNX68ANxDsFCJ4OTR4uTUbhUjAEsoRGMtMGK8qeHCfgAMmFogA7A
nfeVabTKYjfCUkETGs1WYR56LNmVSgT8osj4kL9mqNsxJfMt3u5g6Jm+KJhwnMbgz5A9a1Z8UIJg
C537f7Ik9HKC57QAVHxl4OI8ZghjPHDehSFQzA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 26544)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif

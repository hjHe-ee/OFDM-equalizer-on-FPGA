`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 13:48:02
// Design Name: 
// Module Name: equalizer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "common_defs.v"// 包含通用定义文件

module equalizer
(
    input clock,// 时钟信号
    input enable,// 使能信号
    input reset,// 复位信号

    input [31:0] sample_in,// 32位输入样本
    input sample_in_strobe,// 输入样本有效标志
    input ht_next,// HT模式指示
    input pkt_ht,// HT包指示
    input ht_smoothing,// HT平滑指示
    input wire disable_all_smoothing,// 禁用所有平滑

    output [31:0] phase_in_i,// 相位输入I分量
    output [31:0] phase_in_q,// 相位输入Q分量
    output reg phase_in_stb,// 相位输入有效标志
    input [15:0] phase_out,// 相位输出
    input phase_out_stb,// 相位输出

    output [`ROTATE_LUT_LEN_SHIFT-1:0] rot_addr,// 旋转查找表地址
    input [31:0] rot_data,// 旋转查找表数据

    output reg [31:0] sample_out,// 32位输出样本
    output reg sample_out_strobe,// 输出样本有效标志
    
    output reg [3:0] state,// 状态机状态

    // for side channel// 用于旁路信道
    output wire [31:0] csi,// 信道状态信息
    output wire csi_valid// CSI有效标志
);


// mask[0] is DC, mask[1:26] -> 1,..., 26
// mask[38:63] -> -26,..., -1
// 子载波掩码定义
localparam SUBCARRIER_MASK =
    64'b1111111111111111111111111100000000000111111111111111111111111110;

localparam HT_SUBCARRIER_MASK =
    64'b1111111111111111111111111111000000011111111111111111111111111110;

// -7, -21, 21, 7
// 导频子载波掩码定义
localparam PILOT_MASK =
    64'b0000001000000000000010000000000000000000001000000000000010000000;

// 数据子载波掩码定义
localparam DATA_SUBCARRIER_MASK =
    SUBCARRIER_MASK ^ PILOT_MASK;

localparam HT_DATA_SUBCARRIER_MASK = 
    HT_SUBCARRIER_MASK ^ PILOT_MASK;

// 长训练序列参考值定义
// -1,..,-26, 26,..,1
localparam LTS_REF =
    64'b0000101001100000010100110000000000000000010101100111110101001100;

localparam HT_LTS_REF =
    64'b0000101001100000010100110000000000011000010101100111110101001100;

// 极性序列定义
localparam POLARITY = 
    127'b1111111000111011000101001011111010101000010110111100111001010110011000001101101011101000110010001000000100100110100111101110000;

// 21, 7, -7, -21// HT极性定义
localparam HT_POLARITY = 4'b1000;

// 输入缓冲区长度移位量
localparam IN_BUF_LEN_SHIFT = 6;

// 内部寄存器定义
reg enable_delay;
// 内部复位信号
wire reset_internal = (enable==0 && enable_delay==1);//reset internal after the module is disabled in case the disable lock the state/stb to a non-end state.

reg ht;// HT模式标志
reg [5:0] num_data_carrier;// 数据子载波数量
reg [7:0] num_ofdm_sym;// OFDM符号数量

// bit masks// 参考值和掩码寄存器
reg [63:0] lts_ref;// 长训练序列参考值
reg [63:0] ht_lts_ref;// HT长训练序列参考值
reg [63:0] subcarrier_mask;// 子载波掩码
reg [63:0] data_subcarrier_mask;// 数据子载波掩码
reg [63:0] pilot_mask;// 导频子载波掩码
reg [5:0] pilot_loc[3:0];// 导频位置数组
reg signed [5:0] pilot_idx[3:0];// 导频索引数组
localparam pilot_loc1 = 7;
localparam pilot_loc2 = 21;
localparam pilot_loc3 = 43; 
localparam pilot_loc4 = 57; 
localparam signed pilot_idx1 = 8; 
localparam signed pilot_idx2 = 22; 
localparam signed pilot_idx3 = -20;
localparam signed pilot_idx4 = -6; 

// 导频位置和索引初始化
initial begin 
    pilot_loc[0] = pilot_loc1;
    pilot_idx[0] = pilot_idx1;
    pilot_loc[1] = pilot_loc2;
    pilot_idx[1] = pilot_idx2;
    pilot_loc[2] = pilot_loc3;
    pilot_idx[2] = pilot_idx3;
    pilot_loc[3] = pilot_loc4;
    pilot_idx[3] = pilot_idx4;
end

// 极性相关寄存器
reg [126:0] polarity;// 极性序列
reg [3:0] ht_polarity;// HT极性
reg [3:0] current_polarity;// 当前极性
reg [3:0] pilot_count1, pilot_count2, pilot_count3;// 导频计数器

// 输入数据寄存器
reg signed [15:0] input_i;// 输入I分量
reg signed [15:0] input_q;// 输入Q分量

reg current_sign;// 当前符号

// 长训练序列相关信号
wire signed [15:0] new_lts_i;// 新长训练序列I分量
wire signed [15:0] new_lts_q;// 新长训练序列Q分量
wire new_lts_stb;// 新长训练序列有效标志

reg calc_mean_strobe;// 计算均值有效标志

// 长训练序列存储器接口
reg [5:0] lts_waddr;// 写地址
reg [6:0] lts_raddr; // one bit wider to detect overflow// 读地址（多1位用于溢出检测）
reg [15:0] lts_i_in;// 输入I分量
reg [15:0] lts_q_in;// 输入Q分量
reg lts_in_stb;// 输入有效标志
wire signed [15:0] lts_i_out;// 输出I分量
wire signed [15:0] lts_q_out;// 输出Q分量
wire signed [15:0] lts_q_out_neg = ~lts_q_out + 1;// Q分量取反

// 输入缓冲区接口
reg [5:0] in_waddr;// 写地址
reg [6:0] in_raddr;// 读地址
wire [15:0] buf_i_out;// 输出I分量
wire [15:0] buf_q_out;// 输出Q分量

// 导频处理相关信号
reg pilot_in_stb;// 导频输入有效标志
wire signed [31:0] pilot_i;// 导频I分量
wire signed [31:0] pilot_q;// 导频Q分量
reg signed [31:0] pilot_i_reg, pilot_q_reg;// 导频寄存器
reg signed [15:0] pilot_iq_phase[0:3];// 导频相位数组

// 导频求和寄存器
reg signed [31:0] pilot_sum_i;// 导频I分量和
reg signed [31:0] pilot_sum_q;// 导频Q分量和

// 相位误差相关信号
assign phase_in_i = pilot_i_reg;// 相位输入I分量
assign phase_in_q = pilot_q_reg;// 相位输入Q分量

//reg signed [15:0] pilot_phase_err;
reg signed [16:0] pilot_phase_err; // 15 --> 16 = 15 + 1, extended from cpe// 导频相位误差
reg signed [15:0] cpe; // common phase error due to RFO// 公共相位误差
//reg signed [15:0] Sxy;
reg signed [23:0] Sxy; // 15-->23. to avoid overflow: pilot_phase_err 16 + 5 + 2. 5 for 21* (rounding to 32); 2 for 4 pilots// 相位误差相关参数
localparam Sx2 = 980;// 固定参数

// 线性变化相位误差参数
// linear varying phase error (LVPE) parameters
reg signed [7:0] sym_idx, sym_idx2;// 符号索引 
reg lvpe_in_stb;// 线性相位误差输入有效标志
wire lvpe_out_stb;// 线性相位误差输出有效标志
wire signed [31:0] lvpe_dividend, lvpe, peg_sym_scale;// 线性相位误差相关信号
wire signed [23:0] lvpe_divisor;// 除数
assign lvpe_dividend = (sym_idx <= 33 ? sym_idx*Sxy : (sym_idx-64)*Sxy);// 被除数计算
assign lvpe_divisor = Sx2;// 除数
reg signed [31:0] prev_peg, prev_peg_reg, peg_pilot_scale; // 前导相位误差
assign peg_sym_scale = (sym_idx2 <= 33 ? sym_idx2*prev_peg : (sym_idx2-64)*prev_peg);// 相位误差缩放

//reg signed [15:0] phase_err;
reg signed  [17:0] phase_err; // 15-->16: phase_err <= cpe + lvpe[17:0]; 16 + 1 = 17 for sym_phase// 相位误差
//wire signed [15:0] sym_phase;
wire signed [17:0] sym_phase;// phase_err 16 + 1// 符号相位
assign sym_phase = (phase_err > 1608) ? (phase_err - 3217) : ((phase_err < -1608) ? (phase_err + 3217) : phase_err);//only taking [15:0] to rotate could have overflow!// 符号相位计算

// 旋转相关信号
reg rot_in_stb;// 旋转输入有效标志
wire signed [15:0] rot_i;// 旋转后I分量
wire signed [15:0] rot_q;// 旋转后Q分量

// 乘积相关信号
wire [31:0] mag_sq;// 幅度平方
wire [31:0] prod_i;// 乘积I分量
wire [31:0] prod_q;// 乘积Q分量
wire [31:0] prod_i_scaled = prod_i<<(`CONS_SCALE_SHIFT+1);// 缩放后I分量
wire [31:0] prod_q_scaled = prod_q<<(`CONS_SCALE_SHIFT+1); // +1 to fix the bug threshold for demodulate.v// 缩放后Q分量
wire prod_stb;// 乘积有效标志

// 长训练序列寄存器组
reg signed [15:0] lts_reg1_i, lts_reg2_i, lts_reg3_i, lts_reg4_i, lts_reg5_i;
reg signed [15:0] lts_reg1_q, lts_reg2_q, lts_reg3_q, lts_reg4_q, lts_reg5_q;

// 长训练序列求和信号
wire signed [18:0] lts_sum_1_3_i = lts_reg1_i + lts_reg2_i + lts_reg3_i;
wire signed [18:0] lts_sum_1_3_q = lts_reg1_q + lts_reg2_q + lts_reg3_q;
wire signed [18:0] lts_sum_1_4_i = lts_reg1_i + lts_reg2_i + lts_reg3_i + lts_reg4_i;
wire signed [18:0] lts_sum_1_4_q = lts_reg1_q + lts_reg2_q + lts_reg3_q + lts_reg4_q;
wire signed [18:0] lts_sum_1_5_i = lts_reg1_i + lts_reg2_i + lts_reg3_i + lts_reg4_i + lts_reg5_i;
wire signed [18:0] lts_sum_1_5_q = lts_reg1_q + lts_reg2_q + lts_reg3_q + lts_reg4_q + lts_reg5_q;
wire signed [18:0] lts_sum_2_5_i =              lts_reg2_i + lts_reg3_i + lts_reg4_i + lts_reg5_i;
wire signed [18:0] lts_sum_2_5_q =              lts_reg2_q + lts_reg3_q + lts_reg4_q + lts_reg5_q;
wire signed [18:0] lts_sum_3_5_i =                           lts_reg3_i + lts_reg4_i + lts_reg5_i;
wire signed [18:0] lts_sum_3_5_q =                           lts_reg3_q + lts_reg4_q + lts_reg5_q;
wire signed [18:0] lts_sum_wo3_i = lts_reg1_i + lts_reg2_i              + lts_reg4_i + lts_reg5_i;
wire signed [18:0] lts_sum_wo3_q = lts_reg1_q + lts_reg2_q              + lts_reg4_q + lts_reg5_q;
reg signed [18:0] lts_sum_i;// I分量和
reg signed [18:0] lts_sum_q;// Q分量和

reg [2:0] lts_mv_avg_len;// 移动平均长度
reg lts_div_in_stb;// 除法输入有效标志

// 除法器输入信号
wire [31:0] dividend_i = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? (lts_sum_i[18] == 0 ? {13'h0,lts_sum_i} : {13'h1FFF,lts_sum_i}) : (state == S_ALL_SC_PE_CORRECTION ? prod_i_scaled : 0);
wire [31:0] dividend_q = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? (lts_sum_q[18] == 0 ? {13'h0,lts_sum_q} : {13'h1FFF,lts_sum_q}) : (state == S_ALL_SC_PE_CORRECTION ? prod_q_scaled : 0);
wire [23:0] divisor_i = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? {21'b0,lts_mv_avg_len} : (state == S_ALL_SC_PE_CORRECTION ? mag_sq[23:0] : 1);
wire [23:0] divisor_q = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? {21'b0,lts_mv_avg_len} : (state == S_ALL_SC_PE_CORRECTION ? mag_sq[23:0] : 1);
wire div_in_stb = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? lts_div_in_stb : (state == S_ALL_SC_PE_CORRECTION ? prod_out_strobe : 0);

reg [15:0] num_output;// 输出计数器
wire [31:0] quotient_i;// 商I分量
wire [31:0] quotient_q;// 商Q分量
wire [31:0] norm_i = quotient_i;// 归一化I分量
wire [31:0] norm_q = quotient_q;// 归一化Q分量
wire [31:0] lts_div_i = quotient_i;// 长训练序列除法I分量
wire [31:0] lts_div_q = quotient_q;// 长训练序列除法Q分量

wire div_out_stb;// 除法输出有效标志
wire norm_out_stb = div_out_stb;// 归一化输出有效标志
wire lts_div_out_stb = div_out_stb;// 长训练序列除法输出有效标志

reg prod_in_strobe;// 乘积输入有效标志
wire prod_out_strobe;// 乘积输出有效标志

// 旁路信道信号
// for side channel
reg sample_in_strobe_dly;// 输入样本有效延迟
assign csi = {lts_i_out, lts_q_out};// CSI输出
assign csi_valid = ( (num_ofdm_sym == 1 || (pkt_ht==1 && num_ofdm_sym==5)) && state == S_CPE_ESTIMATE && sample_in_strobe_dly == 1 && enable && (~reset) );// CSI有效条件

// 使能延迟逻辑
always @(posedge clock) begin
    if (reset) begin
        enable_delay <= 0;
    end else begin
        enable_delay <= enable;
    end
end

// 长训练序列存储器实例化
ram_2port #(.DWIDTH(32), .AWIDTH(6)) lts_inst (
    .clka(clock),
    .ena(1),
    .wea(lts_in_stb),
    .addra(lts_waddr),
    .dia({lts_i_in, lts_q_in}),
    .doa(),
    .clkb(clock),
    .enb(1),
    .web(1'b0),
    .addrb(lts_raddr[5:0]),
    .dib(32'hFFFF),
    .dob({lts_i_out, lts_q_out})
);

// 计算均值模块实例化（I分量）
calc_mean lts_i_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),
    
    .a(lts_i_out),
    .b(input_i),
    .sign(current_sign),
    .input_strobe(calc_mean_strobe),

    .c(new_lts_i),
    .output_strobe(new_lts_stb)
);

// 计算均值模块实例化（Q分量）
calc_mean lts_q_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),
    
    .a(lts_q_out),
    .b(input_q),
    .sign(current_sign),
    .input_strobe(calc_mean_strobe),

    .c(new_lts_q)
);

// 输入缓冲区实例化
ram_2port  #(.DWIDTH(32), .AWIDTH(6)) in_buf_inst (
    .clka(clock),
    .ena(1),
    .wea(sample_in_strobe),
    .addra(in_waddr),
    .dia(sample_in),
    .doa(),
    .clkb(clock),
    .enb(1),
    .web(1'b0),
    .addrb(in_raddr[5:0]),
    .dib(32'hFFFF),
    .dob({buf_i_out, buf_q_out})
);

// 复数乘法模块实例化（导频处理）
complex_mult pilot_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),
    .a_i(input_i),
    .a_q(input_q),
    .b_i(lts_i_out),
    .b_q(lts_q_out),
    .input_strobe(pilot_in_stb),
    .p_i(pilot_i),
    .p_q(pilot_q),
    .output_strobe(pilot_out_stb)
);

// 旋转模块实例化
rotate rotate_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),

    .in_i(buf_i_out),
    .in_q(buf_q_out),
    // .phase(sym_phase),
    .phase(sym_phase[15:0]),//only taking [15:0] to rotate could have overflow!
    .input_strobe(rot_in_stb),

    .rot_addr(rot_addr),
    .rot_data(rot_data),
    
    .out_i(rot_i),
    .out_q(rot_q),
    .output_strobe(rot_out_stb)
);

// 复数乘法模块实例化（输入与长训练序列乘积）
complex_mult input_lts_prod_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),
    .a_i(rot_i),
    .a_q(rot_q),
    .b_i(lts_i_out),
    .b_q(lts_q_out_neg),
    .input_strobe(rot_out_stb),
    .p_i(prod_i),
    .p_q(prod_q),
    .output_strobe(prod_out_strobe)
);

// 复数乘法模块实例化（长训练序列自乘）
complex_mult lts_lts_prod_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),
    .a_i(lts_i_out),
    .a_q(lts_q_out),
    .b_i(lts_i_out),
    .b_q(lts_q_out_neg),
    .input_strobe(rot_out_stb),
    .p_i(mag_sq)
);

// 除法器模块实例化（I分量归一化）
divider norm_i_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),

    .dividend(dividend_i),
    .divisor(divisor_i),
    .input_strobe(div_in_stb),

    .quotient(quotient_i),
    .output_strobe(div_out_stb)
);

// 除法器模块实例化（Q分量归一化）
divider norm_q_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),

    .dividend(dividend_q),
    .divisor(divisor_q),
    .input_strobe(div_in_stb),

    .quotient(quotient_q)
);

// 线性变化相位误差计算模块实例化
// LVPE calculation to estimate SFO
divider lvpe_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),

    .dividend(lvpe_dividend),
    .divisor(lvpe_divisor),
    .input_strobe(lvpe_in_stb),

    .quotient(lvpe),
    .output_strobe(lvpe_out_stb)
);

// 状态定义
localparam S_FIRST_LTS = 0;// 第一个长训练序列状态
localparam S_SECOND_LTS = 1;// 第二个长训练序列状态
localparam S_SMOOTH_CH_DC = 2;// DC子载波平滑状态
localparam S_SMOOTH_CH_LTS = 3;// 长训练序列平滑状态
localparam S_GET_POLARITY = 4;// 获取极性状态
localparam S_CPE_ESTIMATE = 5;// 公共相位误差估计状态
localparam S_PILOT_PE_CORRECTION = 6;// 导频相位误差校正状态 
localparam S_LVPE_ESTIMATE = 7;// 线性变化相位误差估计状态
localparam S_ALL_SC_PE_CORRECTION = 8;// 所有子载波相位误差校正状态
localparam S_HT_LTS = 9;// HT长训练序列状态

// 主状态机
always @(posedge clock) begin
    if (reset|reset_internal) begin
        // 复位所有寄存器
        sample_out_strobe <= 0;
        lts_raddr <= 0;
        lts_waddr <= 0;
        sample_out <= 0;

        lts_in_stb <= 0;
        lts_i_in <= 0;
        lts_q_in <= 0;

        ht <= 0;
        num_data_carrier <= 48;
        num_ofdm_sym <= 0;

        subcarrier_mask <= SUBCARRIER_MASK;
        data_subcarrier_mask <= DATA_SUBCARRIER_MASK;
        pilot_mask <= PILOT_MASK;
        lts_ref <= LTS_REF;
        ht_lts_ref <= HT_LTS_REF;
        polarity <= POLARITY;

        ht_polarity <= HT_POLARITY;

        current_polarity <= 0;
        pilot_count1 <= 0;
        pilot_count2 <= 0;
        pilot_count3 <= 0; 

        in_waddr <= 0;
        in_raddr <= 0;
        sym_idx <= 0;
        sym_idx2 <= 0; 

        lts_reg1_i <= 0; lts_reg2_i <= 0; lts_reg3_i <= 0; lts_reg4_i <= 0; lts_reg5_i <= 0;
        lts_reg1_q <= 0; lts_reg2_q <= 0; lts_reg3_q <= 0; lts_reg4_q <= 0; lts_reg5_q <= 0;
        lts_sum_i <= 0;
        lts_sum_q <= 0;
        lts_mv_avg_len <= 0;
        lts_div_in_stb <= 0;

        phase_in_stb <= 0;
        pilot_sum_i <= 0;
        pilot_sum_q <= 0;
        pilot_phase_err <= 0;
        cpe <= 0;
        Sxy <= 0;
        lvpe_in_stb <= 0;
        phase_err <= 0;
        pilot_in_stb <= 0;
        pilot_i_reg <= 0;
        pilot_q_reg <= 0;
        pilot_iq_phase[0] <= 0; pilot_iq_phase[1] <= 0; pilot_iq_phase[2] <= 0; pilot_iq_phase[3] <= 0;
        prev_peg <= 0; 
        prev_peg_reg <= 0; 
        peg_pilot_scale <= 0; 

        prod_in_strobe <= 0;

        rot_in_stb <= 0;

        current_sign <= 0;
        input_i <= 0;
        input_q <= 0;
        calc_mean_strobe <= 0;

        num_output <= 0;

        state <= S_FIRST_LTS;
    end else if (enable) begin
        sample_in_strobe_dly <= sample_in_strobe;
        case(state)
            S_FIRST_LTS: begin
                // 存储第一个长训练序列
                // store first LTS as is
                lts_in_stb <= sample_in_strobe;
                {lts_i_in, lts_q_in} <= sample_in;

                if (lts_in_stb) begin
                    if (lts_waddr == 63) begin
                        lts_waddr <= 0;
                        lts_raddr <= 0;
                        state <= S_SECOND_LTS;
                    end else begin
                        lts_waddr <= lts_waddr + 1;
                    end
                end
            end

            S_SECOND_LTS: begin
                // 计算并存储两个长训练序列的均值
                // calculate and store the mean of the two LTS
                if (sample_in_strobe) begin
                    calc_mean_strobe <= sample_in_strobe;
                    {input_i, input_q} <= sample_in;
                    current_sign <= lts_ref[0];
                    lts_ref <= {lts_ref[0], lts_ref[63:1]};
                    lts_raddr <= lts_raddr + 1;
                end else begin
                    calc_mean_strobe <= 0;
                end

                lts_in_stb <= new_lts_stb;
                {lts_i_in, lts_q_in} <= {new_lts_i, new_lts_q};

                if (lts_in_stb) begin
                    if (lts_waddr == 63) begin
                        lts_waddr <= 0;
                        lts_raddr <= 62;
                        lts_in_stb <= 0;
                        lts_div_in_stb <= 0;
                        state <= (disable_all_smoothing?S_GET_POLARITY:S_SMOOTH_CH_DC);
                    end else begin
                        lts_waddr <= lts_waddr + 1;
                    end
                end
            end 
            
            // 信道估计平滑（DC子载波）
            // 802.11-2012.pdf: 20.3.9.4.3 Table 20-11
            // channel estimate smoothing (averaging length = 5)
            S_SMOOTH_CH_DC: begin
                if(lts_div_in_stb == 1) begin
                    lts_div_in_stb <= 0;
                end else if(lts_raddr == 4) begin
                    lts_sum_i <= lts_sum_wo3_i;
                    lts_sum_q <= lts_sum_wo3_q;
                    lts_mv_avg_len <= 4;
                    lts_div_in_stb <= 1;
                    lts_raddr <= 5;
                end else if(lts_raddr != 5) begin
                    // 长训练序列移位寄存器
                    // LTS Shift register
                    lts_reg1_i <= lts_i_out; lts_reg2_i <= lts_reg1_i; lts_reg3_i <= lts_reg2_i; lts_reg4_i <= lts_reg3_i; lts_reg5_i <= lts_reg4_i;
                    lts_reg1_q <= lts_q_out; lts_reg2_q <= lts_reg1_q; lts_reg3_q <= lts_reg2_q; lts_reg4_q <= lts_reg3_q; lts_reg5_q <= lts_reg4_q;
                    lts_raddr[5:0] <= lts_raddr[5:0] + 1;
                end else begin
                    if(lts_in_stb == 1) begin
                        lts_waddr <= 37;
                        lts_raddr <= 38;
                        lts_in_stb <= 0;
                        state <= S_SMOOTH_CH_LTS;
                    end else if(lts_div_out_stb == 1) begin
                        lts_i_in <= lts_div_i[15:0];
                        lts_q_in <= lts_div_q[15:0];
                        lts_in_stb <= 1;
                    end
                end

            end
            
            // 信道估计平滑（长训练序列）
            // 802.11-2012.pdf: 20.3.9.4.3 Table 20-11
            // channel estimate smoothing (averaging length = 5)
            S_SMOOTH_CH_LTS: begin
                if(lts_raddr == 42) begin
                    lts_sum_i <= lts_sum_1_3_i;
                    lts_sum_q <= lts_sum_1_3_q;
                    lts_mv_avg_len <= 3;
                    lts_div_in_stb <= 1;
                end else if(lts_raddr == 43) begin
                    lts_sum_i <= lts_sum_1_4_i;
                    lts_sum_q <= lts_sum_1_4_q;
                    lts_mv_avg_len <= 4;
                    lts_div_in_stb <= 1;
                end else if(lts_raddr > 43 || lts_raddr < 29) begin
                    lts_sum_i <= lts_sum_1_5_i;
                    lts_sum_q <= lts_sum_1_5_q;
                    lts_mv_avg_len <= 5;
                    lts_div_in_stb <= 1;
                end else if(lts_raddr == 29) begin
                    lts_sum_i <= lts_sum_2_5_i;
                    lts_sum_q <= lts_sum_2_5_q;
                    lts_mv_avg_len <= 4;
                    lts_div_in_stb <= 1;
                end else if(lts_raddr == 30) begin
                    lts_sum_i <= lts_sum_3_5_i;
                    lts_sum_q <= lts_sum_3_5_q;
                    lts_mv_avg_len <= 3;
                    lts_div_in_stb <= 1;
                end else if(lts_raddr == 31) begin
                    lts_div_in_stb <= 0;
                end

                if(lts_raddr >= 38 || lts_raddr <= 30) begin
                    // LTS Shift register
                    // 长训练序列移位寄存器
                    lts_reg1_i <= lts_i_out; lts_reg2_i <= lts_reg1_i; lts_reg3_i <= lts_reg2_i; lts_reg4_i <= lts_reg3_i; lts_reg5_i <= lts_reg4_i;
                    lts_reg1_q <= lts_q_out; lts_reg2_q <= lts_reg1_q; lts_reg3_q <= lts_reg2_q; lts_reg4_q <= lts_reg3_q; lts_reg5_q <= lts_reg4_q;
                    lts_raddr[5:0] <= lts_raddr[5:0] + 1;
                end

                if(lts_div_out_stb == 1) begin
                    lts_i_in <= lts_div_i[15:0];
                    lts_q_in <= lts_div_q[15:0];
                    lts_waddr[5:0] <= lts_waddr[5:0] + 1;
                end
                lts_in_stb <= lts_div_out_stb;

                if(lts_waddr == 26) begin
                    state <= S_GET_POLARITY;
                end
            end

            S_GET_POLARITY: begin
                // 获取下一个OFDM符号的导频子载波极性
                // obtain the polarity of pilot sub-carriers for next OFDM symbol
                if (ht) begin
                    current_polarity <= {
                        ht_polarity[1]^polarity[0], // -7
                        ht_polarity[0]^polarity[0], // -21
                        ht_polarity[3]^polarity[0], // 21
                        ht_polarity[2]^polarity[0]  // 7
                        };
                    ht_polarity <= {ht_polarity[0], ht_polarity[3:1]};
                end else begin
                    current_polarity <= {
                        polarity[0],    // -7
                        polarity[0],    // -21
                        ~polarity[0],   // 21
                        polarity[0]     // 7
                        };
                end
                polarity <= {polarity[0], polarity[126:1]};

                // 初始化相关寄存器
                pilot_sum_i <= 0;
                pilot_sum_q <= 0;
                pilot_count1 <= 0;
                pilot_count2 <= 0;
                cpe <= 0;
                in_waddr <= 0;
                in_raddr <= 0;
                input_i <= 0;
                input_q <= 0;
                lts_raddr <= 0;
                num_ofdm_sym <= num_ofdm_sym + 1;
                state <= S_CPE_ESTIMATE;
            end

            S_CPE_ESTIMATE: begin
                // 检测是否切换到HT模式
                if (~ht & ht_next) begin
                    ht <= 1;
                    num_data_carrier <= 52;
                    lts_waddr <= 0;
                    lts_ref <= HT_LTS_REF;
                    subcarrier_mask <= HT_SUBCARRIER_MASK;
                    data_subcarrier_mask <= HT_DATA_SUBCARRIER_MASK;
                    pilot_mask <= PILOT_MASK;
                    // reverse this extra shift// 反转这个额外的移位
                    polarity <= {polarity[125:0], polarity[126]};
                    state <= S_HT_LTS;
                end
                
                // 使用导频子载波计算残余频率偏移
                // calculate residue freq offset using pilot sub carriers
                if (sample_in_strobe) begin
                    in_waddr <= in_waddr + 1;
                    lts_raddr <= lts_raddr + 1;

                    pilot_mask <= {pilot_mask[0], pilot_mask[63:1]};
                    if (pilot_mask[0]) begin
                        pilot_count1 <= pilot_count1 + 1;
                        // 获取当前导频子载波的共轭
                        // obtain the conjugate of current pilot sub carrier
                        if (current_polarity[pilot_count1] == 0) begin
                            input_i <= sample_in[31:16];
                            input_q <= ~sample_in[15:0] + 1;
                        end else begin
                            input_i <= ~sample_in[31:16] + 1;
                            input_q <= sample_in[15:0];
                        end
                        pilot_in_stb <= 1;
                    end else begin
                        pilot_in_stb <= 0;
                    end
                end else begin
                    pilot_in_stb <= 0;
                end

                // 累加导频分量
                if (pilot_out_stb) begin
                    pilot_sum_i <= pilot_sum_i + pilot_i;
                    pilot_sum_q <= pilot_sum_q + pilot_q;
                    pilot_count2 <= pilot_count2 + 1; 
                end else if (pilot_count2 == 4) begin
                    pilot_i_reg <= pilot_sum_i;
                    pilot_q_reg <= pilot_sum_q; 
                    phase_in_stb <= 1;
                    pilot_count2 <= 0; 
                end else begin
                    phase_in_stb <= 0; 
                end

                // 相位输出处理
                if (phase_out_stb) begin
                    cpe <= phase_out; 
                    pilot_count1 <= 0; 
                    pilot_count2 <= 0;
                    pilot_count3 <= 0; 
                    Sxy <= 0;
                    in_raddr <= pilot_loc[0][5:0];  // sample in location, compensate for RAM read delay// 补偿RAM读取延迟
                    lts_raddr <= pilot_loc[0][5:0]; // LTS location, compensate for RAM read delay// 补偿RAM读取延迟
                    peg_pilot_scale <= pilot_idx[0]*prev_peg;
                    state <= S_PILOT_PE_CORRECTION;
                end
            end

            S_PILOT_PE_CORRECTION: begin
                // 使用累积的PEG旋转导频
                // rotate pilots with accumulated PEG up to previous symbol
                if (pilot_count1 < 4) begin
                    if (pilot_count1 < 3) begin
                        in_raddr <= pilot_loc[pilot_count1+1][5:0];
                        peg_pilot_scale <= (pilot_idx[pilot_count1+1])*prev_peg;
                        rot_in_stb <= 1;
                    end
                    phase_err <= {cpe[15], cpe[15], cpe[15:0]} + peg_pilot_scale[17:0];
                    pilot_count1 <= pilot_count1 + 1; 
                end else begin
                    rot_in_stb <= 0;
                end

                // 复数乘法处理
                if (rot_out_stb && pilot_count2 < 4) begin
                    if (pilot_count2 < 3) begin
                        lts_raddr <= pilot_loc[pilot_count2+1][5:0]; 
                    end
                    // 获取当前导频子载波的共轭
                    // obtain the conjugate of current pilot sub carrier
                    if (current_polarity[pilot_count2] == 0) begin
                        input_i <= rot_i;
                        input_q <= -rot_q;
                    end else begin
                        input_i <= -rot_i;
                        input_q <= rot_q;
                    end
                    pilot_in_stb <= 1;  // start complex mult. with LTS pilot// 开始与LTS导频的复数乘法
                    pilot_count2 <= pilot_count2 + 1; 
                end else begin
                    pilot_in_stb <= 0; 
                end

                // 相位输入处理
                if (pilot_out_stb) begin
                    pilot_i_reg <= pilot_i;
                    pilot_q_reg <= pilot_q;
                    phase_in_stb <= 1;
                end else begin
                    phase_in_stb <= 0; 
                end

                // 相位输出处理
                if (phase_out_stb && pilot_count3 < 4) begin
                    pilot_count3 <= pilot_count3 + 1; 
                    pilot_iq_phase[pilot_count3] <= phase_out;
                end

                if (pilot_count3 == 4) begin
                    phase_in_stb <= 0; 
                    pilot_count1 <= 0; 
                    pilot_count2 <= 0; 
                    pilot_count3 <= 0; 
                    state <= S_LVPE_ESTIMATE; 
                end
            end

            S_LVPE_ESTIMATE: begin
                // 计算线性变化相位误差
                if (pilot_count1 < 4) begin
                    // 采样率偏移(SFO)计算为导频相位误差
                    // sampling rate offset (SFO) is calculated as pilot phase error
                    if(pilot_iq_phase[pilot_count1] < -1608) begin
                        pilot_phase_err <= pilot_iq_phase[pilot_count1] + 3217;
                    end else if(pilot_iq_phase[pilot_count1] > 1608) begin
                        pilot_phase_err <= pilot_iq_phase[pilot_count1] - 3217;
                    end else begin
                        pilot_phase_err <= pilot_iq_phase[pilot_count1];
                    end

                    pilot_count1 <= pilot_count1 + 1;
                end

                // 计算Sxy参数
                if(pilot_count1 == 1) begin
                    Sxy <= Sxy + 7*pilot_phase_err;
                end else if(pilot_count1 == 2) begin
                    Sxy <= Sxy + 21*pilot_phase_err;
                end else if(pilot_count1 == 3) begin
                    Sxy <= Sxy + -21*pilot_phase_err;
                end else if(pilot_count1 == 4) begin
                    Sxy <= Sxy + -7*pilot_phase_err;

                    in_raddr <= 0; 
                    sym_idx <= 0;
                    sym_idx2 <= 1; 
                    lvpe_in_stb <= 0;
                    // 补偿RAM读取延迟
                    // compensate for RAM read delay
                    lts_raddr <= 1;
                    rot_in_stb <= 0;
                    num_output <= 0;
                    state <= S_ALL_SC_PE_CORRECTION;
                end
                // Sx虏 = 鈭?(x-x虅)*(x-x虅) = 鈭憍虏 = (7虏 + 21虏 + (-21)虏 + (-7)虏) = 980
                // phase error gradient (PEG) = Sxy/Sx虏
            end

            S_ALL_SC_PE_CORRECTION: begin
                // 计算所有子载波的相位误差
                if (sym_idx < 64) begin
                    sym_idx <= sym_idx + 1;
                    lvpe_in_stb <= 1;
                end else begin
                    lvpe_in_stb <= 0;
                end
                
                // 先旋转，然后通过平均LTS归一化
                // first rotate, then normalize by avg LTS
                if (lvpe_out_stb) begin
                    sym_idx2 <= sym_idx2 + 1; 
                    phase_err <= {cpe[15], cpe[15], cpe[15:0]} + lvpe[17:0] + peg_sym_scale[17:0];
                    rot_in_stb <= 1;
                    in_raddr <= in_raddr + 1;
                    if (sym_idx2 == 32) begin
                        // lvpe output is 32*PEG due to sym_idx// lvpe输出是32*PEG，因为sym_idx
                        prev_peg_reg <= prev_peg_reg + (lvpe >>> 5); 
                    end
                end else begin
                    rot_in_stb <= 0;
                end
                
                // 归一化输出处理
                if (rot_out_stb) begin
                    lts_raddr <= lts_raddr + 1;
                end

                if (norm_out_stb) begin
                    data_subcarrier_mask <= {data_subcarrier_mask[0],
                        data_subcarrier_mask[63:1]};
                    if (data_subcarrier_mask[0]) begin
                        sample_out_strobe <= 1;
                        sample_out <= {norm_i[31], norm_i[14:0],
                            norm_q[31], norm_q[14:0]};
                        num_output <= num_output + 1;
                    end else begin
                        sample_out_strobe <= 0;
                    end
                end else begin
                    sample_out_strobe <= 0;
                end
                // 完成所有子载波处理后切换到获取极性状态
                if (num_output == num_data_carrier) begin
                    prev_peg <= prev_peg_reg; 
                    state <= S_GET_POLARITY;
                end
            end

            S_HT_LTS: begin
                // HT长训练序列处理
                if (sample_in_strobe) begin
                    lts_in_stb <= 1;
                    ht_lts_ref <= {ht_lts_ref[0], ht_lts_ref[63:1]};
                    if (ht_lts_ref[0] == 0) begin
                        {lts_i_in, lts_q_in} <= sample_in;
                    end else begin
                        lts_i_in <= ~sample_in[31:16]+1;
                        lts_q_in <= ~sample_in[15:0]+1;
                    end
                end else begin
                    lts_in_stb <= 0;
                end

                if (lts_in_stb) begin
                    if (lts_waddr == 63) begin
                        lts_waddr <= 0;
                        lts_raddr <= 62;
                        lts_in_stb <= 0;
                        lts_div_in_stb <= 0;
                        // 根据HT-SIG中的平滑位决定是否平滑信道
                        // Depending on smoothing bit in HT-SIG, smooth the channel
                        if(ht_smoothing==1 && disable_all_smoothing==0) begin
                            state <= S_SMOOTH_CH_DC;
                        end else begin
                            state <= S_GET_POLARITY;
                        end
                    end else begin
                        lts_waddr <= lts_waddr + 1;
                    end
                end

            end

            default: begin
                state <= S_FIRST_LTS;
            end
        endcase
    end else begin
        sample_out_strobe <= 0;
    end
end

endmodule

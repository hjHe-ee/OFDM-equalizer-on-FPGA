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

`include "common_defs.v"// ����ͨ�ö����ļ�

module equalizer
(
    input clock,// ʱ���ź�
    input enable,// ʹ���ź�
    input reset,// ��λ�ź�

    input [31:0] sample_in,// 32λ��������
    input sample_in_strobe,// ����������Ч��־
    input ht_next,// HTģʽָʾ
    input pkt_ht,// HT��ָʾ
    input ht_smoothing,// HTƽ��ָʾ
    input wire disable_all_smoothing,// ��������ƽ��

    output [31:0] phase_in_i,// ��λ����I����
    output [31:0] phase_in_q,// ��λ����Q����
    output reg phase_in_stb,// ��λ������Ч��־
    input [15:0] phase_out,// ��λ���
    input phase_out_stb,// ��λ���

    output [`ROTATE_LUT_LEN_SHIFT-1:0] rot_addr,// ��ת���ұ��ַ
    input [31:0] rot_data,// ��ת���ұ�����

    output reg [31:0] sample_out,// 32λ�������
    output reg sample_out_strobe,// ���������Ч��־
    
    output reg [3:0] state,// ״̬��״̬

    // for side channel// ������·�ŵ�
    output wire [31:0] csi,// �ŵ�״̬��Ϣ
    output wire csi_valid// CSI��Ч��־
);


// mask[0] is DC, mask[1:26] -> 1,..., 26
// mask[38:63] -> -26,..., -1
// ���ز����붨��
localparam SUBCARRIER_MASK =
    64'b1111111111111111111111111100000000000111111111111111111111111110;

localparam HT_SUBCARRIER_MASK =
    64'b1111111111111111111111111111000000011111111111111111111111111110;

// -7, -21, 21, 7
// ��Ƶ���ز����붨��
localparam PILOT_MASK =
    64'b0000001000000000000010000000000000000000001000000000000010000000;

// �������ز����붨��
localparam DATA_SUBCARRIER_MASK =
    SUBCARRIER_MASK ^ PILOT_MASK;

localparam HT_DATA_SUBCARRIER_MASK = 
    HT_SUBCARRIER_MASK ^ PILOT_MASK;

// ��ѵ�����вο�ֵ����
// -1,..,-26, 26,..,1
localparam LTS_REF =
    64'b0000101001100000010100110000000000000000010101100111110101001100;

localparam HT_LTS_REF =
    64'b0000101001100000010100110000000000011000010101100111110101001100;

// �������ж���
localparam POLARITY = 
    127'b1111111000111011000101001011111010101000010110111100111001010110011000001101101011101000110010001000000100100110100111101110000;

// 21, 7, -7, -21// HT���Զ���
localparam HT_POLARITY = 4'b1000;

// ���뻺����������λ��
localparam IN_BUF_LEN_SHIFT = 6;

// �ڲ��Ĵ�������
reg enable_delay;
// �ڲ���λ�ź�
wire reset_internal = (enable==0 && enable_delay==1);//reset internal after the module is disabled in case the disable lock the state/stb to a non-end state.

reg ht;// HTģʽ��־
reg [5:0] num_data_carrier;// �������ز�����
reg [7:0] num_ofdm_sym;// OFDM��������

// bit masks// �ο�ֵ������Ĵ���
reg [63:0] lts_ref;// ��ѵ�����вο�ֵ
reg [63:0] ht_lts_ref;// HT��ѵ�����вο�ֵ
reg [63:0] subcarrier_mask;// ���ز�����
reg [63:0] data_subcarrier_mask;// �������ز�����
reg [63:0] pilot_mask;// ��Ƶ���ز�����
reg [5:0] pilot_loc[3:0];// ��Ƶλ������
reg signed [5:0] pilot_idx[3:0];// ��Ƶ��������
localparam pilot_loc1 = 7;
localparam pilot_loc2 = 21;
localparam pilot_loc3 = 43; 
localparam pilot_loc4 = 57; 
localparam signed pilot_idx1 = 8; 
localparam signed pilot_idx2 = 22; 
localparam signed pilot_idx3 = -20;
localparam signed pilot_idx4 = -6; 

// ��Ƶλ�ú�������ʼ��
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

// ������ؼĴ���
reg [126:0] polarity;// ��������
reg [3:0] ht_polarity;// HT����
reg [3:0] current_polarity;// ��ǰ����
reg [3:0] pilot_count1, pilot_count2, pilot_count3;// ��Ƶ������

// �������ݼĴ���
reg signed [15:0] input_i;// ����I����
reg signed [15:0] input_q;// ����Q����

reg current_sign;// ��ǰ����

// ��ѵ����������ź�
wire signed [15:0] new_lts_i;// �³�ѵ������I����
wire signed [15:0] new_lts_q;// �³�ѵ������Q����
wire new_lts_stb;// �³�ѵ��������Ч��־

reg calc_mean_strobe;// �����ֵ��Ч��־

// ��ѵ�����д洢���ӿ�
reg [5:0] lts_waddr;// д��ַ
reg [6:0] lts_raddr; // one bit wider to detect overflow// ����ַ����1λ���������⣩
reg [15:0] lts_i_in;// ����I����
reg [15:0] lts_q_in;// ����Q����
reg lts_in_stb;// ������Ч��־
wire signed [15:0] lts_i_out;// ���I����
wire signed [15:0] lts_q_out;// ���Q����
wire signed [15:0] lts_q_out_neg = ~lts_q_out + 1;// Q����ȡ��

// ���뻺�����ӿ�
reg [5:0] in_waddr;// д��ַ
reg [6:0] in_raddr;// ����ַ
wire [15:0] buf_i_out;// ���I����
wire [15:0] buf_q_out;// ���Q����

// ��Ƶ��������ź�
reg pilot_in_stb;// ��Ƶ������Ч��־
wire signed [31:0] pilot_i;// ��ƵI����
wire signed [31:0] pilot_q;// ��ƵQ����
reg signed [31:0] pilot_i_reg, pilot_q_reg;// ��Ƶ�Ĵ���
reg signed [15:0] pilot_iq_phase[0:3];// ��Ƶ��λ����

// ��Ƶ��ͼĴ���
reg signed [31:0] pilot_sum_i;// ��ƵI������
reg signed [31:0] pilot_sum_q;// ��ƵQ������

// ��λ�������ź�
assign phase_in_i = pilot_i_reg;// ��λ����I����
assign phase_in_q = pilot_q_reg;// ��λ����Q����

//reg signed [15:0] pilot_phase_err;
reg signed [16:0] pilot_phase_err; // 15 --> 16 = 15 + 1, extended from cpe// ��Ƶ��λ���
reg signed [15:0] cpe; // common phase error due to RFO// ������λ���
//reg signed [15:0] Sxy;
reg signed [23:0] Sxy; // 15-->23. to avoid overflow: pilot_phase_err 16 + 5 + 2. 5 for 21* (rounding to 32); 2 for 4 pilots// ��λ�����ز���
localparam Sx2 = 980;// �̶�����

// ���Ա仯��λ������
// linear varying phase error (LVPE) parameters
reg signed [7:0] sym_idx, sym_idx2;// �������� 
reg lvpe_in_stb;// ������λ���������Ч��־
wire lvpe_out_stb;// ������λ��������Ч��־
wire signed [31:0] lvpe_dividend, lvpe, peg_sym_scale;// ������λ�������ź�
wire signed [23:0] lvpe_divisor;// ����
assign lvpe_dividend = (sym_idx <= 33 ? sym_idx*Sxy : (sym_idx-64)*Sxy);// ����������
assign lvpe_divisor = Sx2;// ����
reg signed [31:0] prev_peg, prev_peg_reg, peg_pilot_scale; // ǰ����λ���
assign peg_sym_scale = (sym_idx2 <= 33 ? sym_idx2*prev_peg : (sym_idx2-64)*prev_peg);// ��λ�������

//reg signed [15:0] phase_err;
reg signed  [17:0] phase_err; // 15-->16: phase_err <= cpe + lvpe[17:0]; 16 + 1 = 17 for sym_phase// ��λ���
//wire signed [15:0] sym_phase;
wire signed [17:0] sym_phase;// phase_err 16 + 1// ������λ
assign sym_phase = (phase_err > 1608) ? (phase_err - 3217) : ((phase_err < -1608) ? (phase_err + 3217) : phase_err);//only taking [15:0] to rotate could have overflow!// ������λ����

// ��ת����ź�
reg rot_in_stb;// ��ת������Ч��־
wire signed [15:0] rot_i;// ��ת��I����
wire signed [15:0] rot_q;// ��ת��Q����

// �˻�����ź�
wire [31:0] mag_sq;// ����ƽ��
wire [31:0] prod_i;// �˻�I����
wire [31:0] prod_q;// �˻�Q����
wire [31:0] prod_i_scaled = prod_i<<(`CONS_SCALE_SHIFT+1);// ���ź�I����
wire [31:0] prod_q_scaled = prod_q<<(`CONS_SCALE_SHIFT+1); // +1 to fix the bug threshold for demodulate.v// ���ź�Q����
wire prod_stb;// �˻���Ч��־

// ��ѵ�����мĴ�����
reg signed [15:0] lts_reg1_i, lts_reg2_i, lts_reg3_i, lts_reg4_i, lts_reg5_i;
reg signed [15:0] lts_reg1_q, lts_reg2_q, lts_reg3_q, lts_reg4_q, lts_reg5_q;

// ��ѵ����������ź�
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
reg signed [18:0] lts_sum_i;// I������
reg signed [18:0] lts_sum_q;// Q������

reg [2:0] lts_mv_avg_len;// �ƶ�ƽ������
reg lts_div_in_stb;// ����������Ч��־

// �����������ź�
wire [31:0] dividend_i = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? (lts_sum_i[18] == 0 ? {13'h0,lts_sum_i} : {13'h1FFF,lts_sum_i}) : (state == S_ALL_SC_PE_CORRECTION ? prod_i_scaled : 0);
wire [31:0] dividend_q = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? (lts_sum_q[18] == 0 ? {13'h0,lts_sum_q} : {13'h1FFF,lts_sum_q}) : (state == S_ALL_SC_PE_CORRECTION ? prod_q_scaled : 0);
wire [23:0] divisor_i = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? {21'b0,lts_mv_avg_len} : (state == S_ALL_SC_PE_CORRECTION ? mag_sq[23:0] : 1);
wire [23:0] divisor_q = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? {21'b0,lts_mv_avg_len} : (state == S_ALL_SC_PE_CORRECTION ? mag_sq[23:0] : 1);
wire div_in_stb = (state == S_SMOOTH_CH_DC || state == S_SMOOTH_CH_LTS) ? lts_div_in_stb : (state == S_ALL_SC_PE_CORRECTION ? prod_out_strobe : 0);

reg [15:0] num_output;// ���������
wire [31:0] quotient_i;// ��I����
wire [31:0] quotient_q;// ��Q����
wire [31:0] norm_i = quotient_i;// ��һ��I����
wire [31:0] norm_q = quotient_q;// ��һ��Q����
wire [31:0] lts_div_i = quotient_i;// ��ѵ�����г���I����
wire [31:0] lts_div_q = quotient_q;// ��ѵ�����г���Q����

wire div_out_stb;// ���������Ч��־
wire norm_out_stb = div_out_stb;// ��һ�������Ч��־
wire lts_div_out_stb = div_out_stb;// ��ѵ�����г��������Ч��־

reg prod_in_strobe;// �˻�������Ч��־
wire prod_out_strobe;// �˻������Ч��־

// ��·�ŵ��ź�
// for side channel
reg sample_in_strobe_dly;// ����������Ч�ӳ�
assign csi = {lts_i_out, lts_q_out};// CSI���
assign csi_valid = ( (num_ofdm_sym == 1 || (pkt_ht==1 && num_ofdm_sym==5)) && state == S_CPE_ESTIMATE && sample_in_strobe_dly == 1 && enable && (~reset) );// CSI��Ч����

// ʹ���ӳ��߼�
always @(posedge clock) begin
    if (reset) begin
        enable_delay <= 0;
    end else begin
        enable_delay <= enable;
    end
end

// ��ѵ�����д洢��ʵ����
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

// �����ֵģ��ʵ������I������
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

// �����ֵģ��ʵ������Q������
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

// ���뻺����ʵ����
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

// �����˷�ģ��ʵ��������Ƶ����
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

// ��תģ��ʵ����
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

// �����˷�ģ��ʵ�����������볤ѵ�����г˻���
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

// �����˷�ģ��ʵ��������ѵ�������Գˣ�
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

// ������ģ��ʵ������I������һ����
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

// ������ģ��ʵ������Q������һ����
divider norm_q_inst (
    .clock(clock),
    .enable(enable),
    .reset(reset|reset_internal),

    .dividend(dividend_q),
    .divisor(divisor_q),
    .input_strobe(div_in_stb),

    .quotient(quotient_q)
);

// ���Ա仯��λ������ģ��ʵ����
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

// ״̬����
localparam S_FIRST_LTS = 0;// ��һ����ѵ������״̬
localparam S_SECOND_LTS = 1;// �ڶ�����ѵ������״̬
localparam S_SMOOTH_CH_DC = 2;// DC���ز�ƽ��״̬
localparam S_SMOOTH_CH_LTS = 3;// ��ѵ������ƽ��״̬
localparam S_GET_POLARITY = 4;// ��ȡ����״̬
localparam S_CPE_ESTIMATE = 5;// ������λ������״̬
localparam S_PILOT_PE_CORRECTION = 6;// ��Ƶ��λ���У��״̬ 
localparam S_LVPE_ESTIMATE = 7;// ���Ա仯��λ������״̬
localparam S_ALL_SC_PE_CORRECTION = 8;// �������ز���λ���У��״̬
localparam S_HT_LTS = 9;// HT��ѵ������״̬

// ��״̬��
always @(posedge clock) begin
    if (reset|reset_internal) begin
        // ��λ���мĴ���
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
                // �洢��һ����ѵ������
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
                // ���㲢�洢������ѵ�����еľ�ֵ
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
            
            // �ŵ�����ƽ����DC���ز���
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
                    // ��ѵ��������λ�Ĵ���
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
            
            // �ŵ�����ƽ������ѵ�����У�
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
                    // ��ѵ��������λ�Ĵ���
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
                // ��ȡ��һ��OFDM���ŵĵ�Ƶ���ز�����
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

                // ��ʼ����ؼĴ���
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
                // ����Ƿ��л���HTģʽ
                if (~ht & ht_next) begin
                    ht <= 1;
                    num_data_carrier <= 52;
                    lts_waddr <= 0;
                    lts_ref <= HT_LTS_REF;
                    subcarrier_mask <= HT_SUBCARRIER_MASK;
                    data_subcarrier_mask <= HT_DATA_SUBCARRIER_MASK;
                    pilot_mask <= PILOT_MASK;
                    // reverse this extra shift// ��ת����������λ
                    polarity <= {polarity[125:0], polarity[126]};
                    state <= S_HT_LTS;
                end
                
                // ʹ�õ�Ƶ���ز��������Ƶ��ƫ��
                // calculate residue freq offset using pilot sub carriers
                if (sample_in_strobe) begin
                    in_waddr <= in_waddr + 1;
                    lts_raddr <= lts_raddr + 1;

                    pilot_mask <= {pilot_mask[0], pilot_mask[63:1]};
                    if (pilot_mask[0]) begin
                        pilot_count1 <= pilot_count1 + 1;
                        // ��ȡ��ǰ��Ƶ���ز��Ĺ���
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

                // �ۼӵ�Ƶ����
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

                // ��λ�������
                if (phase_out_stb) begin
                    cpe <= phase_out; 
                    pilot_count1 <= 0; 
                    pilot_count2 <= 0;
                    pilot_count3 <= 0; 
                    Sxy <= 0;
                    in_raddr <= pilot_loc[0][5:0];  // sample in location, compensate for RAM read delay// ����RAM��ȡ�ӳ�
                    lts_raddr <= pilot_loc[0][5:0]; // LTS location, compensate for RAM read delay// ����RAM��ȡ�ӳ�
                    peg_pilot_scale <= pilot_idx[0]*prev_peg;
                    state <= S_PILOT_PE_CORRECTION;
                end
            end

            S_PILOT_PE_CORRECTION: begin
                // ʹ���ۻ���PEG��ת��Ƶ
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

                // �����˷�����
                if (rot_out_stb && pilot_count2 < 4) begin
                    if (pilot_count2 < 3) begin
                        lts_raddr <= pilot_loc[pilot_count2+1][5:0]; 
                    end
                    // ��ȡ��ǰ��Ƶ���ز��Ĺ���
                    // obtain the conjugate of current pilot sub carrier
                    if (current_polarity[pilot_count2] == 0) begin
                        input_i <= rot_i;
                        input_q <= -rot_q;
                    end else begin
                        input_i <= -rot_i;
                        input_q <= rot_q;
                    end
                    pilot_in_stb <= 1;  // start complex mult. with LTS pilot// ��ʼ��LTS��Ƶ�ĸ����˷�
                    pilot_count2 <= pilot_count2 + 1; 
                end else begin
                    pilot_in_stb <= 0; 
                end

                // ��λ���봦��
                if (pilot_out_stb) begin
                    pilot_i_reg <= pilot_i;
                    pilot_q_reg <= pilot_q;
                    phase_in_stb <= 1;
                end else begin
                    phase_in_stb <= 0; 
                end

                // ��λ�������
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
                // �������Ա仯��λ���
                if (pilot_count1 < 4) begin
                    // ������ƫ��(SFO)����Ϊ��Ƶ��λ���
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

                // ����Sxy����
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
                    // ����RAM��ȡ�ӳ�
                    // compensate for RAM read delay
                    lts_raddr <= 1;
                    rot_in_stb <= 0;
                    num_output <= 0;
                    state <= S_ALL_SC_PE_CORRECTION;
                end
                // Sx² = �?(x-x̄)*(x-x̄) = ∑x² = (7² + 21² + (-21)² + (-7)²) = 980
                // phase error gradient (PEG) = Sxy/Sx²
            end

            S_ALL_SC_PE_CORRECTION: begin
                // �����������ز�����λ���
                if (sym_idx < 64) begin
                    sym_idx <= sym_idx + 1;
                    lvpe_in_stb <= 1;
                end else begin
                    lvpe_in_stb <= 0;
                end
                
                // ����ת��Ȼ��ͨ��ƽ��LTS��һ��
                // first rotate, then normalize by avg LTS
                if (lvpe_out_stb) begin
                    sym_idx2 <= sym_idx2 + 1; 
                    phase_err <= {cpe[15], cpe[15], cpe[15:0]} + lvpe[17:0] + peg_sym_scale[17:0];
                    rot_in_stb <= 1;
                    in_raddr <= in_raddr + 1;
                    if (sym_idx2 == 32) begin
                        // lvpe output is 32*PEG due to sym_idx// lvpe�����32*PEG����Ϊsym_idx
                        prev_peg_reg <= prev_peg_reg + (lvpe >>> 5); 
                    end
                end else begin
                    rot_in_stb <= 0;
                end
                
                // ��һ���������
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
                // ����������ز�������л�����ȡ����״̬
                if (num_output == num_data_carrier) begin
                    prev_peg <= prev_peg_reg; 
                    state <= S_GET_POLARITY;
                end
            end

            S_HT_LTS: begin
                // HT��ѵ�����д���
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
                        // ����HT-SIG�е�ƽ��λ�����Ƿ�ƽ���ŵ�
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

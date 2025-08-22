//`timescale 1ns / 1ps

//module equalizer_tb;

//// ��������
//localparam CLK_PERIOD = 10; // 100MHzʱ������(10ns)

//// �����ź�
//reg clock;                  // ϵͳʱ��
//reg enable;                 // ģ��ʹ���ź�
//reg reset;                  // ��λ�ź�
//reg [31:0] sample_in;       // �����������(I/Q��16λ)
//reg sample_in_strobe;       // ����������Ч�ź�
//reg ht_next;                // ָʾ��һ��������HTģʽ
//reg pkt_ht;                 // ָʾ��������HTģʽ
//reg ht_smoothing;           // HTģʽ�µ��ŵ�ƽ��ʹ��
//reg disable_all_smoothing;  // ��������ƽ������
//reg [15:0] phase_out;       // ��λУ�����
//reg phase_out_stb;          // ��λУ����Ч�ź�
//reg [31:0] rot_data;        // ��ת���ұ�����

//// ����ź�
//wire [31:0] phase_in_i;     // ��λ����I����
//wire [31:0] phase_in_q;     // ��λ����Q����
//wire phase_in_stb;          // ��λ������Ч�ź�
//wire [`ROTATE_LUT_LEN_SHIFT-1:0] rot_addr; // ��ת���ұ��ַ
//wire [31:0] sample_out;     // ������������
//wire sample_out_strobe;     // ���������Ч�ź�
//wire [3:0] state;           // ״̬��״̬
//wire [31:0] csi;            // �ŵ�״̬��Ϣ
//wire csi_valid;             // CSI��Ч�ź�

//// ʵ��������ģ��
//equalizer uut (
//    .clock(clock),
//    .enable(enable),
//    .reset(reset),
//    .sample_in(sample_in),
//    .sample_in_strobe(sample_in_strobe),
//    .ht_next(ht_next),
//    .pkt_ht(pkt_ht),
//    .ht_smoothing(ht_smoothing),
//    .disable_all_smoothing(disable_all_smoothing),
//    .phase_in_i(phase_in_i),
//    .phase_in_q(phase_in_q),
//    .phase_in_stb(phase_in_stb),
//    .phase_out(phase_out),
//    .phase_out_stb(phase_out_stb),
//    .rot_addr(rot_addr),
//    .rot_data(rot_data),
//    .sample_out(sample_out),
//    .sample_out_strobe(sample_out_strobe),
//    .state(state),
//    .csi(csi),
//    .csi_valid(csi_valid)
//);

//// ʱ������
//always begin
//    #(CLK_PERIOD/2) clock = ~clock;
//end

//// ���Լ���
//initial begin
//    // ��ʼ������
//    clock = 0;
//    enable = 0;
//    reset = 1;
//    sample_in = 0;
//    sample_in_strobe = 0;
//    ht_next = 0;
//    pkt_ht = 0;
//    ht_smoothing = 0;
//    disable_all_smoothing = 0;
//    phase_out = 0;
//    phase_out_stb = 0;
//    rot_data = 0;
    
//    // �ȴ�ȫ�ָ�λ���
//    #100;
//    reset = 0;
//    enable = 1;
    
//    // ��������1: ��HTģʽ(802.11a/g)
//    $display("��ʼ��HTģʽ����");
//    test_non_ht_mode();
    
//    // ��������2: HTģʽ(802.11n)
//    $display("��ʼHTģʽ����");
//    test_ht_mode();
    
//    // ��������3: ����ƽ������
//    $display("��ʼ����ƽ�����ܲ���");
//    test_with_smoothing_disabled();
    
//    $display("���в������");
//    $finish;
//end

//// ��HTģʽ��������
//task test_non_ht_mode;
//begin
//    // ���͵�һ��LTS(��ѵ������)
//    send_lts(0); // 0��ʾ��HT LTS
    
//    // ���͵ڶ���LTS
//    send_lts(0); // 0��ʾ��HT LTS
    
//    // �������ݷ���
//    for (integer i = 0; i < 10; i = i + 1) begin
//        // ����OFDM����
//        send_ofdm_symbol(0, i); // 0��ʾ��HTģʽ
        
//        // ������λ���
//        #20;
//        phase_out = $random; // ���������λУ��ֵ
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// HTģʽ��������
//task test_ht_mode;
//begin
//    pkt_ht = 1;      // ��������HTģʽ
//    ht_next = 1;     // ��һ��������HTģʽ
//    ht_smoothing = 1; // ����HTƽ��
    
//    // ���͵�һ��LTS(��HT)
//    send_lts(0);
    
//    // ���͵ڶ���LTS(��HT)
//    send_lts(0);
    
//    // ����HT-LTS
//    send_lts(1); // 1��ʾHT-LTS
    
//    // �������ݷ���
//    for (integer i = 0; i < 10; i = i + 1) begin
//        // ����OFDM����
//        send_ofdm_symbol(1, i); // 1��ʾHTģʽ
        
//        // ������λ���
//        #20;
//        phase_out = $random;
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// ����ƽ�����ܲ�������
//task test_with_smoothing_disabled;
//begin
//    disable_all_smoothing = 1; // ��������ƽ������
    
//    // ���͵�һ��LTS
//    send_lts(0);
    
//    // ���͵ڶ���LTS
//    send_lts(0);
    
//    // �������ݷ���
//    for (integer i = 0; i < 5; i = i + 1) begin
//        // ����OFDM����
//        send_ofdm_symbol(0, i);
        
//        // ������λ���
//        #20;
//        phase_out = $random;
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// ����LTS����
//task send_lts;
//input is_ht; // �Ƿ�ΪHTģʽ
//begin
//    // ����64��������(FFT���)
//    for (integer i = 0; i < 64; i = i + 1) begin
//        #10;
//        sample_in = {$random, $random}; // �������I/Q����
//        sample_in_strobe = 1;
//        #10;
//        sample_in_strobe = 0;
//    end
//end
//endtask

//// ����OFDM��������
//task send_ofdm_symbol;
//input is_ht;          // �Ƿ�ΪHTģʽ
//input integer sym_num; // �������
//begin
//    // ����64��������(FFT���)
//    for (integer i = 0; i < 64; i = i + 1) begin
//        #10;
//        // ���ɴ�����֪��Ƶֵ���������
//        if (i == 7 || i == 21 || i == 43 || i == 57) begin
//            // ��Ƶ���ز�(-21, -7, 7, 21)
//            if (is_ht) begin
//                // HT��Ƶ����ģʽ
//                case (sym_num % 4)
//                    0: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    1: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    2: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    3: sample_in = (i == 57) ? 32'hFFFF0000 : 32'h00010000;
//                endcase
//            end else begin
//                // ��HT��Ƶ����
//                if (sym_num % 2) begin
//                    sample_in = (i == 43 || i == 57) ? 32'hFFFF0000 : 32'h00010000;
//                end else begin
//                    sample_in = 32'h00010000;
//                end
//            end
//        end else begin
//            // �������ز�
//            sample_in = {$random, $random};
//        end
//        sample_in_strobe = 1;
//        #10;
//        sample_in_strobe = 0;
//    end
//end
//endtask

//// ������
//initial begin
//    // ���״̬��״̬���������
//    $monitor("ʱ�� %t: ״̬=%d, �����Ч=%b, �������=%h", 
//             $time, state, sample_out_strobe, sample_out);
//end

//endmodule
`timescale 1ns / 1ps

module equalizer_tb;

// Parameters
parameter CLK_PERIOD = 10; // 100 MHz clock

// Inputs
reg clock;
reg enable;
reg reset;
reg [31:0] sample_in;
reg sample_in_strobe;
reg ht_next;
reg pkt_ht;
reg ht_smoothing;
reg disable_all_smoothing;

// Outputs
wire [31:0] phase_in_i;
wire [31:0] phase_in_q;
wire phase_in_stb;
wire [15:0] phase_out;
wire phase_out_stb;
wire [`ROTATE_LUT_LEN_SHIFT-1:0] rot_addr;
wire [31:0] rot_data;
wire [31:0] sample_out;
wire sample_out_strobe;
wire [3:0] state;
wire [31:0] csi;
wire csi_valid;

// Testbench variables
integer i, j;
integer symbol_count;
integer sample_count;
integer file;

// Instantiate the Unit Under Test (UUT)
equalizer uut (
    .clock(clock),
    .enable(enable),
    .reset(reset),
    .sample_in(sample_in),
    .sample_in_strobe(sample_in_strobe),
    .ht_next(ht_next),
    .pkt_ht(pkt_ht),
    .ht_smoothing(ht_smoothing),
    .disable_all_smoothing(disable_all_smoothing),
    .phase_in_i(phase_in_i),
    .phase_in_q(phase_in_q),
    .phase_in_stb(phase_in_stb),
    .phase_out(phase_out),
    .phase_out_stb(phase_out_stb),
    .rot_addr(rot_addr),
    .rot_data(rot_data),
    .sample_out(sample_out),
    .sample_out_strobe(sample_out_strobe),
    .state(state),
    .csi(csi),
    .csi_valid(csi_valid)
);

// Clock generator
initial begin
    clock = 0;
    forever #(CLK_PERIOD/2) clock = ~clock;
end

// Phase output simulation
assign phase_out = 16'h0000; // Simulate zero phase error for testing
assign phase_out_stb = phase_in_stb; // Respond immediately to phase input strobe

// Rotation LUT simulation (identity rotation for testing)
assign rot_data = 32'h00010000; // cos(0) = 1, sin(0) = 0

// Test sequence
initial begin
    // Initialize inputs
    enable = 0;
    reset = 1;
    sample_in = 0;
    sample_in_strobe = 0;
    ht_next = 0;
    pkt_ht = 0;
    ht_smoothing = 0;
    disable_all_smoothing = 0;
    
    // Open output file
    file = $fopen("equalizer_output.txt", "w");
    
    // Reset sequence
    #100;
    reset = 0;
    enable = 1;
    
    // Generate 10 OFDM symbols (2 LTS + 8 data symbols)
    for (symbol_count = 0; symbol_count < 10; symbol_count = symbol_count + 1) begin
        // Generate 64 samples per symbol
        for (sample_count = 0; sample_count < 64; sample_count = sample_count + 1) begin
            // Simulate input samples (simplified - real implementation would have proper values)
            sample_in = {16'h1000 + symbol_count*256 + sample_count, 
                         16'h0800 + symbol_count*128 + sample_count};
            
            // Pulse strobe
            sample_in_strobe = 1;
            #(CLK_PERIOD);
            sample_in_strobe = 0;
            
            // Wait for next sample
            #(CLK_PERIOD*3);
        end
        
        // Extra delay between symbols
        #(CLK_PERIOD*10);
    end
    
    // Finish simulation
    $fclose(file);
    $display("Simulation completed");
    $finish;
end

// Monitor outputs
always @(posedge clock) begin
    if (sample_out_strobe) begin
        $fwrite(file, "Symbol: %0d, Sample: %0d, I: %0d, Q: %0d\n", 
                uut.num_ofdm_sym, uut.num_output, 
                $signed(sample_out[31:16]), $signed(sample_out[15:0]));
    end
    
    if (csi_valid) begin
        $display("CSI updated: I=%0d, Q=%0d", $signed(csi[31:16]), $signed(csi[15:0]));
    end
end

endmodule
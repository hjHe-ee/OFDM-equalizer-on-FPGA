//`timescale 1ns / 1ps

//module equalizer_tb;

//// 参数定义
//localparam CLK_PERIOD = 10; // 100MHz时钟周期(10ns)

//// 输入信号
//reg clock;                  // 系统时钟
//reg enable;                 // 模块使能信号
//reg reset;                  // 复位信号
//reg [31:0] sample_in;       // 输入采样数据(I/Q各16位)
//reg sample_in_strobe;       // 采样数据有效信号
//reg ht_next;                // 指示下一个符号是HT模式
//reg pkt_ht;                 // 指示整个包是HT模式
//reg ht_smoothing;           // HT模式下的信道平滑使能
//reg disable_all_smoothing;  // 禁用所有平滑功能
//reg [15:0] phase_out;       // 相位校正输出
//reg phase_out_stb;          // 相位校正有效信号
//reg [31:0] rot_data;        // 旋转查找表数据

//// 输出信号
//wire [31:0] phase_in_i;     // 相位估计I输入
//wire [31:0] phase_in_q;     // 相位估计Q输入
//wire phase_in_stb;          // 相位估计有效信号
//wire [`ROTATE_LUT_LEN_SHIFT-1:0] rot_addr; // 旋转查找表地址
//wire [31:0] sample_out;     // 均衡后输出数据
//wire sample_out_strobe;     // 输出数据有效信号
//wire [3:0] state;           // 状态机状态
//wire [31:0] csi;            // 信道状态信息
//wire csi_valid;             // CSI有效信号

//// 实例化被测模块
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

//// 时钟生成
//always begin
//    #(CLK_PERIOD/2) clock = ~clock;
//end

//// 测试激励
//initial begin
//    // 初始化输入
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
    
//    // 等待全局复位完成
//    #100;
//    reset = 0;
//    enable = 1;
    
//    // 测试用例1: 非HT模式(802.11a/g)
//    $display("开始非HT模式测试");
//    test_non_ht_mode();
    
//    // 测试用例2: HT模式(802.11n)
//    $display("开始HT模式测试");
//    test_ht_mode();
    
//    // 测试用例3: 禁用平滑功能
//    $display("开始禁用平滑功能测试");
//    test_with_smoothing_disabled();
    
//    $display("所有测试完成");
//    $finish;
//end

//// 非HT模式测试任务
//task test_non_ht_mode;
//begin
//    // 发送第一个LTS(长训练序列)
//    send_lts(0); // 0表示非HT LTS
    
//    // 发送第二个LTS
//    send_lts(0); // 0表示非HT LTS
    
//    // 处理数据符号
//    for (integer i = 0; i < 10; i = i + 1) begin
//        // 发送OFDM符号
//        send_ofdm_symbol(0, i); // 0表示非HT模式
        
//        // 处理相位输出
//        #20;
//        phase_out = $random; // 随机生成相位校正值
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// HT模式测试任务
//task test_ht_mode;
//begin
//    pkt_ht = 1;      // 整个包是HT模式
//    ht_next = 1;     // 下一个符号是HT模式
//    ht_smoothing = 1; // 启用HT平滑
    
//    // 发送第一个LTS(非HT)
//    send_lts(0);
    
//    // 发送第二个LTS(非HT)
//    send_lts(0);
    
//    // 发送HT-LTS
//    send_lts(1); // 1表示HT-LTS
    
//    // 处理数据符号
//    for (integer i = 0; i < 10; i = i + 1) begin
//        // 发送OFDM符号
//        send_ofdm_symbol(1, i); // 1表示HT模式
        
//        // 处理相位输出
//        #20;
//        phase_out = $random;
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// 禁用平滑功能测试任务
//task test_with_smoothing_disabled;
//begin
//    disable_all_smoothing = 1; // 禁用所有平滑功能
    
//    // 发送第一个LTS
//    send_lts(0);
    
//    // 发送第二个LTS
//    send_lts(0);
    
//    // 处理数据符号
//    for (integer i = 0; i < 5; i = i + 1) begin
//        // 发送OFDM符号
//        send_ofdm_symbol(0, i);
        
//        // 处理相位输出
//        #20;
//        phase_out = $random;
//        phase_out_stb = 1;
//        #10;
//        phase_out_stb = 0;
//    end
//end
//endtask

//// 发送LTS任务
//task send_lts;
//input is_ht; // 是否为HT模式
//begin
//    // 发送64个采样点(FFT输出)
//    for (integer i = 0; i < 64; i = i + 1) begin
//        #10;
//        sample_in = {$random, $random}; // 随机生成I/Q数据
//        sample_in_strobe = 1;
//        #10;
//        sample_in_strobe = 0;
//    end
//end
//endtask

//// 发送OFDM符号任务
//task send_ofdm_symbol;
//input is_ht;          // 是否为HT模式
//input integer sym_num; // 符号序号
//begin
//    // 发送64个采样点(FFT输出)
//    for (integer i = 0; i < 64; i = i + 1) begin
//        #10;
//        // 生成带有已知导频值的随机数据
//        if (i == 7 || i == 21 || i == 43 || i == 57) begin
//            // 导频子载波(-21, -7, 7, 21)
//            if (is_ht) begin
//                // HT导频极性模式
//                case (sym_num % 4)
//                    0: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    1: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    2: sample_in = (i == 57) ? 32'h00010000 : 32'h00010000;
//                    3: sample_in = (i == 57) ? 32'hFFFF0000 : 32'h00010000;
//                endcase
//            end else begin
//                // 非HT导频极性
//                if (sym_num % 2) begin
//                    sample_in = (i == 43 || i == 57) ? 32'hFFFF0000 : 32'h00010000;
//                end else begin
//                    sample_in = 32'h00010000;
//                end
//            end
//        end else begin
//            // 数据子载波
//            sample_in = {$random, $random};
//        end
//        sample_in_strobe = 1;
//        #10;
//        sample_in_strobe = 0;
//    end
//end
//endtask

//// 监控输出
//initial begin
//    // 监控状态机状态和输出数据
//    $monitor("时间 %t: 状态=%d, 输出有效=%b, 输出数据=%h", 
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
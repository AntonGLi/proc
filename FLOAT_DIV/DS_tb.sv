`timescale 1ns/1ps

module tb #(parameter T=10);
    // Clock and reset
    reg clk;
    reg rst;
    
    // Test vectors (15.0 / 3.0)
    wire [31:0] a = 32'b01000001011100000000000000000000;  // 15.0
    wire [31:0] b = 32'b01000000010000000000000000000000;  // 3.0
    // Ожидаемый результат: 5.0 = 32'b01000000101000000000000000000000
    
    // Outputs
    logic [31:0] c;
    logic busy;
    logic res_vld;
    
    // Instance
    fp_div DUT (
        .clk(clk),
        .rst(rst),
        .arg_vld('1),
        .busy(busy),
        .res_vld(res_vld),
        .a(a),
        .b(b),
        .c(c)
    );
    
    // Параметры для отображения
    real real_a, real_b, real_c, expected_c;
    
    // Initialization
    initial begin
        // Initialize
        clk = 0;
        rst = 0;
        
        // Convert to real for display
        real_a = $bitstoshortreal(a);
        real_b = $bitstoshortreal(b);
        expected_c = real_a / real_b;
        
        $display("========================================");
        $display("Starting test for fp_div module");
        $display("Input: a = %f (0x%8h)", real_a, a);
        $display("Input: b = %f (0x%8h)", real_b, b);
        $display("Expected result: %f", expected_c);
        $display("Expected hex: 0x%8h", $shortrealtobits(expected_c));
        $display("========================================\n");
        
        // Reset sequence
        #200 rst = 1;
        #200 rst = 0;
        
        // Wait for result
        wait(res_vld == 1);
        
        // Convert result to real
        real_c = $bitstoshortreal(c);
        
        // Check result
        #10; // Small delay after valid
        
        $display("\n========================================");
        $display("Test Results:");
        $display("Got result: %f (0x%8h)", real_c, c);
        $display("Expected:   %f (0x%8h)", expected_c, $shortrealtobits(expected_c));
        
        // Precision comparison
        if (c === $shortrealtobits(expected_c)) begin
            $display("SUCCESS: Exact match!");
        end else begin
            real error = (real_c - expected_c) / expected_c;
            if ($abs(error) < 1e-6) begin
                $display("SUCCESS: Within tolerance (error = %e)", error);
            end else begin
                $display("FAIL: Error too large (error = %e)", error);
                $display("Difference: actual vs expected = %f", real_c - expected_c);
            end
        end
        
        $display("========================================");
        
        // Additional checks
        $display("\nAdditional checks:");
        $display("Busy signal was high for %0d cycles", count_busy_cycles());
        $display("Result valid latency: %0d cycles", get_latency());
        
        // Wait a bit more and finish
        #100;
        $finish;
    end
    
    // Clock generator
    always #50 clk = ~clk;
    
    // Monitor to track signals
    initial begin
        $monitor("Time %0t: rst=%b, busy=%b, res_vld=%b, c=0x%8h",
                 $time, rst, busy, res_vld, c);
    end
    
    // Task to count busy cycles
    function int count_busy_cycles();
        int count = 0;
        for (int i = 0; i < 1000; i++) begin
            @(posedge clk);
            if (busy) count++;
            if (res_vld) break;
        end
        return count;
    endfunction
    
    // Task to measure latency
    function int get_latency();
        int cycles = 0;
        wait(busy == 1);  // Wait for start
        @(posedge clk);
        while(busy && !res_vld) begin
            cycles++;
            @(posedge clk);
        end
        return cycles;
    endfunction
    
    // Check for protocol violations
    always @(posedge clk) begin
        if (rst) begin
            if (busy !== 0 || res_vld !== 0) begin
                $warning("Reset assertion: busy or res_vld should be 0");
            end
        end
        
        // Check valid handshake
        if (res_vld && busy) begin
            $warning("res_vld and busy both high simultaneously");
        end
    end
    
    // Waveform dump
    initial begin
        $dumpfile("fp_div_tb.vcd");
        $dumpvars(0, tb);
    end
endmodule
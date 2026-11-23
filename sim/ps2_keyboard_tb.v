`timescale 1ns / 1ps

module ps2_keyboard_tb;

    reg        clk;
    reg        resetn;
    reg        ps2_clk;
    reg        ps2_dat;
    wire [7:0] scan_code;
    wire       key_valid;

    // Instantiate your ps2_keyboard module
    ps2_keyboard dut (
        .clk       (clk),
        .resetn    (resetn),
        .ps2_clk   (ps2_clk),
        .ps2_dat   (ps2_dat),
        .scan_code (scan_code),
        .key_valid (key_valid)
    );

    // 50 MHz clock (20 ns period)
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // Task to send one 11-bit PS/2 frame (Start=0, 8 data bits LSB-first, Odd Parity, Stop=1)
    task send_ps2_byte;
        input [7:0] code;
        reg   [10:0] frame;
        integer i;
        begin
            frame[0]   = 1'b0;
            frame[8:1] = code;
            frame[9]   = ~(^code);
            frame[10]  = 1'b1;

            for (i = 0; i < 11; i = i + 1) begin
                ps2_dat = frame[i];
                #20000;
                ps2_clk = 1'b0; // Falling edge: dut samples clean_dat here
                #40000;
                ps2_clk = 1'b1;
                #20000;
            end

            ps2_dat = 1'b1;
            #100000;
        end
    endtask

    // Print a message in the ModelSim transcript every time key_valid pulses
    always @(posedge clk) begin
        if (key_valid) begin
            $display("[%0t ns] key_valid pulsed! scan_code = 8'h%h", $time, scan_code);
        end
    end

    initial begin
        resetn  = 1'b0;
        ps2_clk = 1'b1;
        ps2_dat = 1'b1;

        #100;
        resetn = 1'b1;
        #50000;

        // 1. Press 'W' (8'h1D) -> should trigger key_valid once
        send_ps2_byte(8'h1D);

        // 2. Release 'W' (8'hF0 then 8'h1D) -> should NOT trigger key_valid
        send_ps2_byte(8'hF0);
        send_ps2_byte(8'h1D);

        // 3. Press 'S' (8'h1B) -> should trigger key_valid once
        send_ps2_byte(8'h1B);

        // 4. Press '4' (8'h25) -> should trigger key_valid once
        send_ps2_byte(8'h25);

        #100000;
        $stop;
    end

endmodule
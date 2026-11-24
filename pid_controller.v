module pid_controller #(
    parameter signed [15:0] KP = 16'sd128
)(
    input wire clk,
    input wire resetn,
    input wire tick,
    input wire [8:0] target_angle,
    input wire signed [15:0] current_angle_q,
    output reg signed [15:0] control_out
);
    // Angle constants fix point
    wire signed [15:0] DEG_180_Q = 16'sd11520; // 180 * 64
    wire signed [15:0] DEG_360_Q = 16'sd23040; // 360 * 64

    // Converting 9 bit unsigned target angle to signed 16 bit
    wire signed [15:0] target_extended = target_angle;         // Widening 9-bit to 16-bit by padding 7 bits on left
    wire signed [15:0] target_q        = target_extended << 6; // Step 2: Shift left by 6 (multiplies by 64)

    // Finding raw error (-359.98 to +359.98 deg) and wrap to shortest path [-180, +180]
    wire signed [15:0] raw_error = target_q - current_angle_q;
    reg  signed [15:0] error;

    always @(*) begin
        if (raw_error > DEG_180_Q)
            error = raw_error - DEG_360_Q;
        else if (raw_error < -DEG_180_Q)
            error = raw_error + DEG_360_Q;
        else
            error = raw_error;
    end

    // 16 bit * 16 bit turns to 32-bit then arithmetic right-shift by 6 -> Q26.6
    wire signed [31:0] p_mult = KP * error;
    wire signed [31:0] p_term = p_mult >>> 6; // Dividing by 2^6 to account for it being multiplied in as extra in the process (>>> keeps signed)

    // Each 60hz sample tick
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            control_out <= 16'sd0;
        end else if (tick) begin
            // Temp
            control_out <= p_term[15:0];
        end
    end
endmodule





module pid_tick_gen #(
    parameter [19:0] MAX_COUNT = 20'd833_332 // 50 Mhz/ 60 Hz
)(
    input wire clk,
    input wire resetn,
    output reg tick

);

    reg [19:0] cycle_count;

    always @(posedge clk or negedge resetn) begin 
        if (!resetn) begin 
            cycle_count <= 20'd0;
            tick <= 1'd0;
        end else begin 
            tick <= 1'd0;
            if (cycle_count == MAX_COUNT) begin
                cycle_count <= 20'd0;
                tick <= 1'd1;
            end else if (cycle_count < MAX_COUNT) begin     
                cycle_count <= cycle_count + 20'd1;
            end
        end
    end

endmodule




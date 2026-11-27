module pid_controller #(
    parameter signed [15:0] KP = 16'sd128, // 2.0 in Q10.6 (2.0 * 64)
    parameter signed [15:0] KI = 16'sd32,  // 0.5 in Q10.6 (0.5 * 64)
    parameter signed [15:0] KD = 16'sd32   // 0.5 in Q10.6 (0.5 * 64)
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
    // Anti windup clamp
    wire signed [31:0] INT_MAX   = 32'sd524288; // Clamps integral at +/-128 deg*s
    // Output saturation constant
    localparam signed [31:0] OUT_MAX   = 32'sd32767;  // +511.98 in Q10.6
    localparam signed [31:0] OUT_MIN   = -32'sd32767; // -511.98 in Q10.6

    // Converting 9 bit unsigned target angle to signed 16 bit
    wire signed [15:0] target_extended = target_angle;         // Widening 9-bit to 16-bit by padding 7 bits on left
    wire signed [15:0] target_q        = target_extended << 6; // Step 2: Shift left by 6 (multiplies by 64)

    // Finding raw error (-360 to +360 deg) and wrap to shortest path [-180, +180]
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

    // Proportional Term: P = Kp * error
    // 16 bit * 16 bit turns to 32-bit then arithmetic right-shift by 6 -> Q26.6
    wire signed [31:0] p_mult = KP * error;
    wire signed [31:0] p_term = p_mult >>> 6; // Dividing by 2^6 to account for it being multiplied in as extra in the process (>>> keeps signed)

    
    // Integral Term I = 
    reg  signed [31:0] integral_sum;
    wire signed [31:0] integral_next   = integral_sum + error;
    wire signed [31:0] integral_scaled = integral_sum >>> 6; // Apply dt ~= 1/64 s
    wire signed [31:0] i_mult          = KI * integral_scaled;
    wire signed [31:0] i_term          = i_mult >>> 6;       // Back to Q26.6

    // Derivative Term: D = Kd * (error - prev_error) / dt
    reg  signed [15:0] prev_error;
    wire signed [31:0] delta_error = error - prev_error;
    wire signed [31:0] d_term      = KD * delta_error; // The division by time and shifting cancel eachother out

    // Total unclamped PID output (Q26.6)
    wire signed [31:0] pid_sum = p_term + i_term + d_term;

    // Sequential updates on each 60 Hz sample tick
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            integral_sum <= 32'sd0;
            control_out  <= 16'sd0;
            prev_error <= 16'sd0;
        end else if (tick) begin
            // Anti-windup clamping for integral_sum
            if (integral_next > INT_MAX)
                integral_sum <= INT_MAX;
            else if (integral_next < -INT_MAX)
                integral_sum <= -INT_MAX;
            else
                integral_sum <= integral_next;
            
            // Save current error for next tick's derivative
            prev_error <= error

            // Output saturation to prevent 16-bit signed wrap-around
            if (pid_sum > OUT_MAX)
                control_out <= 16'sd32767;
            else if (pid_sum < OUT_MIN)
                control_out <= -16'sd32767;
            else
                control_out <= pid_sum[15:0];
        end
    end


endmodule










module arm_plant (
    input  wire               clk,
    input  wire               resetn,
    input  wire               tick,            // 60 Hz 1-cycle pulse
    input  wire signed [15:0] control_in,      // Q10.6 torque from pid_controller
    output wire signed [15:0] current_angle_q, // Q10.6 angle (0..359.98) for PID
    output wire        [8:0]  current_angle    // 9-bit integer (0..359) for VGA/LEDR
);

    // 360 degrees in Q20.12 format (360 * 4096 = 1,474,560)
    localparam signed [31:0] DEG_360_Q12 = 32'sd1474560;

    reg signed [31:0] velocity_q12; // Angular velocity (deg/s) in Q20.12
    reg signed [31:0] angle_q12;    // Angular position (deg)   in Q20.12

    // Scale velocity to Q26.6 (also equals velocity_q12 * dt where dt = 1/64)
    wire signed [31:0] vel_q6 = velocity_q12 >>> 6;

    // Dynamics: accel = control_in - b * velocity (with J = 1, b = 1)
    wire signed [31:0] accel_q6   = control_in - vel_q6;

    // Candidate next angle: angle + velocity * dt
    wire signed [31:0] angle_next = angle_q12 + vel_q6;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            velocity_q12 <= 32'sd0;
            angle_q12    <= 32'sd0;
        end else if (tick) begin
            // Adding Q10.6 accel to Q20.12 velocity implicitly multiplies by dt = 1/64
            velocity_q12 <= velocity_q12 + accel_q6;

            // Wrap angle continuously within [0, 360) degrees
            if (angle_next >= DEG_360_Q12)
                angle_q12 <= angle_next - DEG_360_Q12;
            else if (angle_next < 32'sd0)
                angle_q12 <= angle_next + DEG_360_Q12;
            else
                angle_q12 <= angle_next;
        end
    end

    // Slice Q20.12 -> Q10.6 for PID, and Q20.12 -> 9-bit integer for VGA/LEDR
    assign current_angle_q = angle_q12[21:6];
    assign current_angle   = angle_q12[20:12];

endmodule
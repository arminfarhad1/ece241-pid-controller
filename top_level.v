module top_level (
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,          // KEY[0] = active-low reset
    input  wire       PS2_CLK,
    input  wire       PS2_DAT,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [9:0] LEDR
);

    wire resetn = KEY[0];

    wire [7:0] scan_code;
    wire key_valid;

    ps2_keyboard keyboard (
        .clk       (CLOCK_50),
        .resetn    (resetn),
        .ps2_clk   (PS2_CLK),
        .ps2_dat   (PS2_DAT),
        .scan_code (scan_code),
        .key_valid (key_valid)
    );

    // Angle controller with 180 and 0 Clamping
    reg [8:0] target_angle;

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            target_angle <= 8'd0;
        end else if (key_valid) begin
            case (scan_code)
                8'h1D: // 'W' causes +5 degrees (clamped at 180 max)
                    target_angle <= (target_angle => 9'd355) ? (target_angle - 9'd355) : (target_angle + 9'd5); // wrapps 355 to 0
                8'h1B: // 'S' causes -5 degrees (clamped at 0 min)
                    target_angle <= (target_angle < 9'd5) ? (target_angle + 9'd355) : (target_angle - 9'd5);   // Clamped at 0 degrees
                8'h29: target_angle <= 9'd0;  // 'Space' -> 0 deg
                8'h16: target_angle <= 9'd30; // '1' -> 30 deg
                8'h1E: target_angle <= 9'd45; // '2' -> 45 deg
                8'h26: target_angle <= 9'd60; // '3' -> 60 deg
                8'h25: target_angle <= 9'd90; // '4' -> 90 deg

                default: target_angle <= target_angle; // Ignore unmapped
            endcase
        end
    end

    // Display target_angle in binary on LEDR[7:0] and scan_code in hex on HEX1:HEX0
    assign LEDR = {2'b00, target_angle};

    hex_7seg disp_hex1 (.hex(scan_code[7:4]), .seg(HEX1));
    hex_7seg disp_hex0 (.hex(scan_code[3:0]), .seg(HEX0));

endmodule

module hex_7seg (
    input  wire [3:0] hex,
    output reg  [6:0] seg
);
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b100_0000;
            4'h1: seg = 7'b111_1001;
            4'h2: seg = 7'b010_0100;
            4'h3: seg = 7'b011_0000;
            4'h4: seg = 7'b001_1001;
            4'h5: seg = 7'b001_0010;
            4'h6: seg = 7'b000_0010;
            4'h7: seg = 7'b111_1000;
            4'h8: seg = 7'b000_0000;
            4'h9: seg = 7'b001_0000;
            4'hA: seg = 7'b000_1000;
            4'hB: seg = 7'b000_0011;
            4'hC: seg = 7'b100_0110;
            4'hD: seg = 7'b010_0001;
            4'hE: seg = 7'b000_0110;
            4'hF: seg = 7'b000_1110;
            default: seg = 7'b111_1111;
        endcase
    end
endmodule
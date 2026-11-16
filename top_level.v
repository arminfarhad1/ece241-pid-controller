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

ps2_keyboard  keyboard(
        .clk       (CLOCK_50),
        .resetn    (resetn),
        .ps2_clk   (PS2_CLK),
        .ps2_dat   (PS2_DAT),
        .scan_code (scan_code),
        .key_valid (key_valid)
    );


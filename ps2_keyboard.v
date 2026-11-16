module ps2_keyboard(
    input wire clk,
    input wire resetn,
    input wire ps2_clk,
    input wire ps2_dat,
    output reg [7:0] scan_code,
    output reg key_valid,
)

// Part 1: Synchronizing PS2 Clk and Global Clk

reg [2:0] ps2_clk_sync;
reg [1:0] ps2_dat_sync;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        ps2_clk_sync <= 3'b111;
        ps2_dat_sync <= 3'b11
    end else begin
        ps2_clk_sync[0] <= ps2_clk; // Direct access to ps2_clk (acts as buffer)
        ps2_clk_sync[1] <= ps2_clk_sync[0]; // Current (Buffer after 1 clock edge)
        ps2_clk_sync[2] <= ps2_clk_sync[1]; // Previous (Current after 1 clock edge)
        ps2_dat_sync[0] <= ps2_dat; // Direct access to dat (buffer)
        ps2_dat_sync[1] <= ps2_dat_sync;
    end
end

wire ps2_negedge = (ps2_clk_sync[2:1] == 2'b10) //High for one Clock50 cycle, 
wire clean_dat = ps2_dat_sync[1];

// Part 2: Accessing 11 bit data

reg [3:0] bit_count;
reg [10:0] dat_shift_reg;
reg frame_done; //To wait 1 clock cycle after the shift register is finished loading

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        bit_count <= 4'd0;
        dat_shift_reg <= 11'd0;
    end else begin
        frame_done <= 1'b0;

        if (ps2_negedge) begin
            //Full shift
            dat_shift_reg[0] <= dat_clean;
            dat_shift_reg[10:1] <= dat_shift_reg[9:0];
            
            if (bit_count == 4'd10) begin
                bit_count <= 4'd0; // Reset counter to 0
                frame_done <= 1'b1; // Full 11 bit frame is ready
            end else begin
                bit_count <= bit_count + 4'd1;
            end
        end
    end
end

// Breaking up the data into its bit groups
wire start_bit = shift_reg[0];
wire [7:0] byte_val = shift_reg[8:1];
wire parity_bit = shift_reg[9];
wire stop_bit = shift_reg[10];

wire odd_valid = ^(shift_reg[9:1]);
wire frame_valid = (start_bit == 1'b0) && (stop_bit == 1'b1) && (odd_valid == 1'b1);

// Part 3: Parsing through bytes

reg break_flag;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        scan_code <= 8'd0;
        key_valid <= 1'b0
        break_flag <= 1'b0
    end else begin
        if (frame_valid && frame_done) begin
            if (byte_val == 8'hF0) begin
                break_flag <= 1'b1 //Break prefix recieved
            end else if (byte_val == 8'hE0) begin
                break_flag <= break_flag; //Extended key prefix, keep break as it is
            end else if (break_flag) begin
                break_flag <= 1'b0 //The byte is coming after key being released, so reset the break after ignoring
            end else begin
                scan_code <= byte_val; //Key press
                key_valid = 1'b1; //To make sure that the byte is activated once
            end
        end
    end
end
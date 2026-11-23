module vga_demo (CLOCK_50, SW, KEY, LEDR, HEX2, HEX1, HEX0, VGA_X, VGA_Y, VGA_COLOR, plot);


   parameter RESOLUTION = "160x120";
   parameter COLOR_DEPTH = 3;


  input CLOCK_50;
   input [9:0] SW;
   input [3:0] KEY;
   output [9:0] LEDR;
   output [6:0] HEX2, HEX1, HEX0;
   output [7:0] VGA_X;
   output [6:0] VGA_Y;
   output [23:0] VGA_COLOR;
   output plot;


   wire VGA_SYNC;


assign LEDR[9] = VGA_SYNC;
   assign LEDR[8:0] = 9'b0;
   assign HEX2 = 7'b1111111;
   assign HEX1 = 7'b1111111;
   assign HEX0 = 7'b1111111;








parameter IDLE = 2'd0, DRAW = 2'd1, FINISH = 2'd2;


reg [1:0] state;
reg [7:0] xc;
wire start;


assign start = ~KEY[3];




always @(posedge CLOCK_50)
begin
   if (!KEY[0])
   begin
       state <= IDLE;
       xc <= 8'd40;
   end
   else
   begin
       case (state)
           IDLE:
           begin
               xc <= 8'd80;
               if (start)
                   state <= DRAW;
           end


           DRAW:
           begin
               if (xc == 8'd130)
                   state <= FINISH;
               else
                   xc <= xc + 1'b1;
           end


           FINISH:
           begin
               if (!start)
                   state <= IDLE;
           end


           default: state <= IDLE;
       endcase
   end
end




   `define VGA_MEMORY
   vga_adapter VGA (
       .resetn(KEY[0]),
       .clock(CLOCK_50),
       .color(3'b111),
       .x(xc),
       .y(7'd60),
       .write(state == DRAW),
       .VGA_X(VGA_X),
       .VGA_Y(VGA_Y),
       .VGA_COLOR(VGA_COLOR),
       .VGA_SYNC(VGA_SYNC),
       .plot(plot));
       defparam VGA.RESOLUTION = RESOLUTION;
       defparam VGA.COLOR_DEPTH = COLOR_DEPTH;
       defparam VGA.BACKGROUND_IMAGE = "./MIF/black.mif";

endmodule

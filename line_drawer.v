module line_drawer (clock, resetn, start, x0, y0, x1, y1, x, y, write, done);

    input clock, resetn, start;
    input [7:0] x0, x1;            
    input [6:0] y0, y1;            
    output reg [7:0] x;             
    output reg [6:0] y;           
    output reg write;              
    output reg done;                

   
    parameter IDLE = 3'b001, DRAW = 3'b010, FINISH = 3'b100;

    reg [2:0] state;
    reg [7:0] x_end;                
    reg [6:0] y_end;                
    reg sx, sy;                     
    reg signed [9:0] dx, dy, err;  

   
    reg [7:0] abs_dx;
    reg [6:0] abs_dy;

    always @(*)
    begin
        if (x1 >= x0)
            abs_dx = x1 - x0;
        else
            abs_dx = x0 - x1;

        if (y1 >= y0)
            abs_dy = y1 - y0;
        else
            abs_dy = y0 - y1;
    end

   
    wire signed [9:0] dx_in, dy_in;
    assign dx_in = abs_dx;
    assign dy_in = -abs_dy;

   
    wire signed [10:0] e2;
    wire step_x, step_y, at_end;

    assign e2     = err * 2;
    assign step_x = (e2 >= dy);    
    assign step_y = (e2 <= dx);    
    assign at_end = (x == x_end) && (y == y_end);

    always @(posedge clock)
    begin
        if (!resetn)
        begin
            state <= IDLE;
            x <= 8'd0;
            y <= 7'd0;
            x_end <= 8'd0;
            y_end <= 7'd0;
            sx <= 1'b0;
            sy <= 1'b0;
            dx <= 10'sd0;
            dy <= 10'sd0;
            err <= 10'sd0;
        end
        else
        begin
            case (state)
                IDLE:
                begin
                    if (start)
                    begin
                        x <= x0;
                        y <= y0;
                        x_end <= x1;
                        y_end <= y1;
                        sx <= (x0 < x1);
                        sy <= (y0 < y1);
                        dx <= dx_in;
                        dy <= dy_in;
                        err <= dx_in + dy_in;
                        state <= DRAW;
                    end
                end

                DRAW:
                begin
                    if (at_end)
                        state <= FINISH;
                    else
                    begin
                        if (step_x && step_y)
                            err <= err + dy + dx;
                        else if (step_x)
                            err <= err + dy;
                        else if (step_y)
                            err <= err + dx;

                        if (step_x)
                        begin
                            if (sx)
                                x <= x + 1'b1;
                            else
                                x <= x - 1'b1;
                        end

                        if (step_y)
                        begin
                            if (sy)
                                y <= y + 1'b1;
                            else
                                y <= y - 1'b1;
                        end
                    end
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

    always @(*)
    begin
        write = (state == DRAW);
        done  = (state == FINISH);
    end

endmodule

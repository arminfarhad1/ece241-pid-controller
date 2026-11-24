module angle_counter (clock, resetn, step, angle, ones, tens, hundreds);

    input clock, resetn, step;
    output reg [8:0] angle;                
    output reg [3:0] ones, tens, hundreds; 

    always @(posedge clock)
    begin
        if (!resetn)
        begin
            angle <= 9'd0;
            ones <= 4'd0;
            tens <= 4'd0;
            hundreds <= 4'd0;
        end
        else if (step)
        begin
            if (angle == 9'd359)
            begin
                angle <= 9'd0;
                ones <= 4'd0;
                tens <= 4'd0;
                hundreds <= 4'd0;
            end
            else
            begin
                angle <= angle + 1'b1;
                if (ones == 4'd9)
                begin
                    ones <= 4'd0;
                    if (tens == 4'd9)
                    begin
                        tens <= 4'd0;
                        hundreds <= hundreds + 1'b1;
                    end
                    else
                        tens <= tens + 1'b1;
                end
                else
                    ones <= ones + 1'b1;
            end
        end
    end

endmodule

module tick_gen (clock, resetn, tick);

    parameter MAX = 833333;       

    input clock, resetn;
    output reg tick;

    reg [25:0] count;     

    always @(posedge clock)
    begin
        if (!resetn)
        begin
            count <= 26'd0;
            tick <= 1'b0;
        end
        else
        begin
            if (count == MAX - 1)
            begin
                count <= 26'd0;
                tick <= 1'b1;
            end
            else
            begin
                count <= count + 1'b1;
                tick <= 1'b0;
            end
        end
    end

endmodule

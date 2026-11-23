module pid_controller #(
    parameter signed [15:0] = 16'sd
);
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




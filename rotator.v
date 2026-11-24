module rotator (clock, resetn, ready, tick, ld_done, ld_start, step, erase);

    input clock, resetn;
    input ready;        
    input tick;       
    input ld_done;      
    output ld_start;   
    output step;       
    output erase;      

    
    parameter S_INIT = 5'b00001, S_WAIT = 5'b00010, S_ERASE = 5'b00100, S_UPDATE = 5'b01000, S_DRAW = 5'b10000;

    reg [4:0] state;

    always @(posedge clock)
    begin
        if (!resetn)
            state <= S_INIT;
        else
        begin
            case (state)
                S_INIT:   if (ready) state <= S_DRAW;
                S_WAIT:   if (tick) state <= S_ERASE;
                S_ERASE:  if (ld_done) state <= S_UPDATE;
                S_UPDATE: state <= S_DRAW;
                S_DRAW:   if (ld_done) state <= S_WAIT;
                default:  state <= S_INIT;
            endcase
        end
    end

    assign ld_start = (state == S_ERASE) || (state == S_DRAW);
    assign step = (state == S_UPDATE);
    assign erase = (state == S_ERASE);

endmodule

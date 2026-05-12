module ping (
    input           i_clk,
    input           i_start,
    input           i_rst,
    output          o_trigger,
    input           i_echo,
    output [15:0]   o_echo_time,
    output          o_new
);

wire w_echo_clk;

clk_div #(
    .p_input_freq(50000000),
    .p_output_freq(2000000)
) baud_clk (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_clk(w_echo_clk)
);

reg [2:0] r_echo_sync;
wire w_echo;

always @(posedge w_echo_clk )begin
    r_echo_sync = {r_echo_sync[1:0], i_echo};
end

assign w_echo = r_echo_sync[2];

reg r_prev_start;
wire w_start_rising = ~r_prev_start && i_start;

always @(posedge w_echo_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_prev_start = 1'b0;
    end
    else begin
        r_prev_start = i_start;
    end
end

localparam 
    s_idle = 3'd0,
    s_start = 3'd1,
    s_wait = 3'd2,
    s_echo = 3'd3,
    s_done = 3'd4;
    
reg [15:0] r_echo_time;
    
reg [2:0] r_state = s_idle;

reg r_trigger;
reg [15:0] r_echo_count;
reg [15:0] r_count;
reg        r_new;

always @(posedge w_echo_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_state = s_idle;
        r_echo_count = 0;
        r_count = 0;
        r_trigger = 1'b0;
        r_new     = 1'b0;
    end
    else begin
        case(r_state)
            s_idle: begin
                if (w_start_rising) begin
                    r_state = s_start;
                    r_new = 1'b0;
                    r_trigger = 1'b1;
                    r_count = 16'd0;
                end
            end
            s_start: begin
                if (r_count > 20) begin
                    r_state = s_wait;
                    r_trigger = 1'b0;
                end 
                else begin
                    r_count = r_count + 1;
                end
            end
            s_wait: begin
                if (w_echo) begin
                    r_state = s_echo;
                    r_echo_count = 16'd0;
                end
                if (r_count > 60000) begin
                    r_state = s_idle;
                    r_count = 16'd0;
                    r_echo_count = 16'd0;
                end 
                else begin
                    r_count = r_count + 1;
                end
                
            end
            s_echo: begin
                if (~w_echo) begin
                    r_state = s_done;
                    r_new = 1'b1;
                    r_echo_time = r_echo_count;
                    r_count = 16'd0;
                end
                else begin
                    r_echo_count <= r_echo_count + 1;
                end
            end
            s_done: begin
                r_state <= s_idle;
                r_count <= 16'd0;
            end
            
            default: begin
                r_state <= s_idle;
                r_echo_count <= 0;
                r_count <= 0;
                r_trigger <= 1'b0;
            end
        endcase
    end
end

assign o_trigger = r_trigger;
assign o_echo_time = r_echo_time;
assign o_new = r_new;

endmodule
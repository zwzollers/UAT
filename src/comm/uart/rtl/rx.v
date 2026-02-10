module rx #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
) (
    input           i_clk,
    input           i_rst,

    input           i_rx,
    output          o_new,
    output          o_err,
    output [7:0]    o_data
);

wire w_baud_clk;
wire w_sync_baud_clk;

// hold reset if rx is high and state is IDLE
assign w_sync_baud_clk = ~(i_rx & (r_state == s_IDLE));

clk_div #(
    .p_input_freq(p_clk_freq),
    .p_output_freq(p_baud_freq)
) baud_clk (
    .i_clk(i_clk),
    .i_rst(w_sync_baud_clk & i_rst),
    .o_clk(w_baud_clk)
);

parameter 
    s_IDLE      = 3'd0,
    s_RECV      = 3'd1,
    s_PARITY    = 3'd2,
    s_STOP1     = 3'd3,
    s_STOP2     = 3'd4;

reg [2:0] r_state  = s_IDLE;
reg [7:0] r_data   = 8'd0;
reg [2:0] r_bit    = 3'd0;
reg       r_new    = 1'b0;
reg       r_parity = 1'b0;

always @(posedge w_baud_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_state  = s_IDLE;
        r_data   = 8'd0;
        r_bit    = 3'd0;
        r_new    = 1'b0;
        r_parity = 1'b0;
    end
    else begin
        case (r_state) 
            s_IDLE: begin
                r_state <= s_RECV;
                r_bit <= 3'd0;
                r_new <= 1'b0;
            end

            s_RECV: begin
                r_data[r_bit] <= i_rx;
                r_bit <= r_bit + 1'b1;

                if (r_bit == 3'd7) 
                    r_state <= s_PARITY;
            end

            s_PARITY: begin
                r_state <= s_STOP1;
                r_parity <= i_rx;
                r_new <= 1'b1;
            end

            s_STOP1: begin
                r_state <= s_STOP2; 
            end

            s_STOP2: begin
                r_state <= s_IDLE;
            end
        endcase
    end
end

assign o_data = r_data;
assign o_new  = r_new;
assign o_err  = r_new & (^r_data ^ r_parity);

endmodule
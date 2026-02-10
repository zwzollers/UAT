module tx #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
) (
    input           i_clk,
    input           i_rst,

    output          o_tx,
    output          o_done,
    input           i_start,
    input [7:0]     i_data
);

wire w_baud_clk;

clk_div #(
    .p_input_freq(p_clk_freq),
    .p_output_freq(p_baud_freq)
) baud_clk (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_clk(w_baud_clk)
);

reg r_start_prev = 1'b0;
wire w_start_rising = ~r_start_prev & i_start;

always @(posedge w_baud_clk) begin
    r_start_prev <= i_start;
end

parameter 
    s_IDLE      = 2'd0,
    s_SEND      = 2'd1,
    s_PARITY    = 2'd2,
    s_STOP      = 2'd3;

reg [1:0] r_state  = s_IDLE;
reg [7:0] r_data   = 8'd0;
reg [2:0] r_bit    = 3'd0;
reg       r_tx     = 1'b1;
reg       r_done   = 1'b1;

wire w_parity = ^r_data;

always @(posedge w_baud_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_state  = s_IDLE;
        r_data   = 8'd0;
        r_bit    = 3'd0;
        r_tx     = 1'b1;
        r_done   = 1'b0;
    end
    else begin
        case (r_state) 
            s_IDLE: begin
                if (w_start_rising == 1'b1) begin
                    r_state <= s_SEND;
                    r_tx    <= 1'b0;
                    r_data  <= i_data;
                    r_done  <= 1'b0;
                    r_bit   <= 3'd0;
                end
                else begin
                    r_done  <= 1'b1;
                end
            end

            s_SEND: begin
                r_tx <= r_data[r_bit];
                r_bit <= r_bit + 1'b1;
                if (r_bit == 3'd7) 
                    r_state <= s_PARITY;
            end

            s_PARITY: begin
                r_tx <= w_parity;
                r_state <= s_STOP;
            end

            s_STOP: begin
                r_tx <= 1'b1;
                r_state <= s_IDLE; 
            end
        endcase
    end
end

assign o_tx = r_tx;
assign o_done = r_done;

endmodule
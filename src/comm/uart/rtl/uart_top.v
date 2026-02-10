module uart_top #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
) (
    input           i_clk,
    input           i_rst,

    output          o_tx,
    output          o_tx_done,
    
    input           i_rx,
    output          o_rx_new,
    output          o_rx_err,
    
    output [7:0]    o_rx_data,
    output [6:0]    o_rx_sevseg_1,
    output [6:0]    o_rx_sevseg_2
);

wire [7:0] w_data;
wire       w_new;

assign o_rx_new = w_new;
assign o_rx_data = w_data;

uart #(
    .p_clk_freq(p_clk_freq),
    .p_baud_freq(p_baud_freq)
) controller (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_tx(o_tx),
    .o_tx_done(o_tx_done),
    .i_tx_start(w_new),
    .i_tx_data(w_data),
    .i_rx(i_rx),
    .o_rx_new(w_new),
    .o_rx_err(o_rx_err),
    .o_rx_data(w_data)
);

sev_seg #(
    .p_active(0)
) digit1 (
    .i_char(w_data[3:0]),
    .o_segs(o_rx_sevseg_1)
);

sev_seg #(
    .p_active(0)
) digit2 (
    .i_char(w_data[7:4]),
    .o_segs(o_rx_sevseg_2)
);

endmodule
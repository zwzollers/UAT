module uart #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
) (
    input           i_clk,
    input           i_rst,

    output          o_tx,
    output          o_tx_done,
    input           i_tx_start,
    input [7:0]     i_tx_data,
    
    input           i_rx,
    output          o_rx_new,
    output          o_rx_err,
    output [7:0]    o_rx_data
);

rx #(
    .p_clk_freq(p_clk_freq),
    .p_baud_freq(p_baud_freq)
) recvier (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_rx(i_rx),
    .o_new(o_rx_new),
    .o_err(o_rx_err),
    .o_data(o_rx_data)
);

tx #(
    .p_clk_freq(p_clk_freq),
    .p_baud_freq(p_baud_freq)
) transmitter (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_tx(o_tx),
    .o_done(o_tx_done),
    .i_start(i_tx_start),
    .i_data(i_tx_data)
);

endmodule
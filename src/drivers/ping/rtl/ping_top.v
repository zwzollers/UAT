module ping_top (
    input           i_clk,
    input           i_rst,
    
    output          o_trigger,
    input           i_echo,
    output [7:0]    o_echo_time

    // output          o_tx
);

// uart #(
//     .p_clk_freq(p_clk_freq),
//     .p_baud_freq(p_baud_freq)
// ) controller (
//     .i_clk(i_clk),
//     .i_rst(i_rst),
//     .o_tx(o_tx),
//     .o_tx_done(o_tx_done),
//     .i_tx_start(w_new),
//     .i_tx_data(w_data),
//     .i_rx(i_rx),
//     .o_rx_new(w_new),
//     .o_rx_err(o_rx_err),
//     .o_rx_data(w_data)
// );

wire [15:0] w_echo_time;
assign o_echo_time = w_echo_time[7:0];

ping driver(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .o_trigger(o_trigger), 
    .i_echo(i_echo), 
    .o_echo_time(w_echo_time)
);

endmodule
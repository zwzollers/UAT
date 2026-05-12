module cmd_ctrl_top #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
) (
    input           i_clk,
    input           i_rst,

    output          o_tx,
    input           i_rx
);

wire [7:0]  w_cmd;
wire [63:0] w_cmd_data;
wire [63:0] w_resp_data;
wire        w_cmd_new;
wire        w_loopback;

assign w_resp_data = 
    (w_cmd == 8'h70) ? w_cmd_data     :
    (w_cmd == 8'h72) ? {56'd0, r_reg} :
    (w_cmd == 8'h77) ? 64'd0          :
                       64'd0          ;

reg [7:0] r_reg;

always @(posedge w_cmd_new) begin
    if (w_cmd == 8'h77) begin
        r_reg <= w_cmd_data[7:0];
    end
end

cmd_controller ctrl (
    .i_clk(i_clk),
    .i_rst(i_rst),
    
    .i_resp_ready(1'b1),
    .i_resp_data(w_resp_data),
    
    .o_cmd(w_cmd),
    .o_cmd_data(w_cmd_data),
    .o_cmd_new(w_cmd_new),
    
    .i_rx_data(w_rx_data),
    .i_rx_new(w_rx_new),
    .i_rx_err(w_rx_err),
    
    .i_tx_done(w_tx_done),
    .o_tx_start(w_tx_start),
    .o_tx_data(w_tx_data),
    
    .o_loopback(w_loopback)
);

wire [7:0] w_rx_data;
wire       w_rx_new;
wire       w_rx_err;

wire       w_tx_done;
wire       w_tx_start;
wire [7:0] w_tx_data;


uart #(
    .p_clk_freq(p_clk_freq),
    .p_baud_freq(p_baud_freq)
) controller (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_loopback(w_loopback),
    .o_tx(o_tx),
    .o_tx_done(w_tx_done),
    .i_tx_start(w_tx_start),
    .i_tx_data(w_tx_data),
    .i_rx(i_rx),
    .o_rx_new(w_rx_new),
    .o_rx_err(o_rx_err),
    .o_rx_data(w_rx_data)
);

endmodule
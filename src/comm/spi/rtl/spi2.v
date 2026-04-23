module spi (
    input           i_clk,
    input           i_rst,
    
    input           i_mosi,
    input           i_sclk,
    input           i_cs,
    output          o_miso,
    
    input  [7:0]    i_tx_data,
    input           i_tx_start,          
    output          o_tx_done,
    
    output [7:0]    o_rx_data,
    output          o_rx_new,
    output          o_rx_err
);

wire w_sclk;
fifo #(
    .p_depth(3)
) clk_stable (
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_sgnl(i_sclk), 
    .o_sgnl(w_sclk)
); 

wire w_mosi;
fifo #(
    .p_depth(3)
) mosi_stable (
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_sgnl(i_mosi), 
    .o_sgnl(w_mosi)
);

wire w_cs;
fifo #(
    .p_depth(3)
) mosi_stable (
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_sgnl(i_cs), 
    .o_sgnl(w_cs)
);

reg r_tx_start_prev = 1'b0;
wire w_tx_start_rising = ~r_tx_start_prev & i_tx_start;

always @(posedge i_clk) begin
    r_tx_start_prev <= i_tx_start;
end
      
reg r_miso = 1'b0;
reg [7:0] r_tx_data = 8'd0;
reg [7:0] r_rx_data = 8'd0;
reg [2:0] r_bit = 3'd0;

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_tx_data <= 8'd0;
        r_miso    <= 1'b0;
        r_bit     <= 3'd0;
    end
    else begin
        if (w_tx_start_rising) begin
            r_tx_data <= i_tx_data;
        end
    end
end

assign o_tx_done = (bit == 3'd0);
assign i_rx_new  = (bit == 3'd0);

always @(posedge w_sclk) begin
    if (~w_cs) begin
        bit <= bit - 1;
        r_miso <= r_tx_data[bit - 1];
        r_rx_data[bit - 1] <= w_mosi;
    end
end

assign o_rx_err = 1'b0;
assign o_miso = r_miso;
assign o_rx_data = r_rx_data;

endmodule
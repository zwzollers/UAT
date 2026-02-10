`timescale 1ns / 1ns

module uart_tb;
  
parameter p_clk_freq = 50_000_000;
parameter p_baud_freq = 115_200;

localparam p_clk_half_period = 1_000_000_000 / p_clk_freq / 2;
localparam p_count = (p_clk_freq + (p_baud_freq / 2)) / p_baud_freq;

uart #(
    .p_clk_freq(p_clk_freq),
    .p_baud_freq(p_baud_freq)
) uart_controller (
    .i_clk(r_clk),
    .i_rst(r_rst),
    .o_tx(w_tx),
    .o_tx_done(w_tx_done),
    .i_tx_start(r_tx_start),
    .i_tx_data(r_tx_data),
    .i_rx(r_rx),
    .o_rx_new(w_rx_new),
    .o_rx_err(w_rx_err),
    .o_rx_data(w_rx_data)
);

reg r_clk = 1'b0;
always #p_clk_half_period r_clk <= ~r_clk;

reg r_rst = 1'b1;
wire w_tx;
wire w_tx_done;
reg r_tx_start = 1'b0;
reg [7:0] r_tx_data = 8'd0;
reg r_rx = 1'b1;
wire w_rx_new;
wire w_rx_err;
wire [7:0] w_rx_data;


time last_edge = 0;

reg[10:0] r_test_data = 11'b10110011000;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,uart_tb);

    r_rst = 1'b0;
    @(posedge r_clk);
    @(posedge r_clk);
    r_rst = 1'b1;
    @(posedge r_clk);
    @(posedge r_clk);
    

    for (int i = 0; i < 11; i = i + 1) begin
        
        r_rx = r_test_data[i];
        for (int i = 0; i < p_count; i = i + 1) begin
            @(r_clk);
        end  
    end
    
    if (w_rx_data != r_test_data[8:1])
        $error("%d != %d", w_rx_data, r_test_data[8:1]);

    $display("Testbench finished OK");
    $finish;
end

endmodule

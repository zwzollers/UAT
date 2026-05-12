`timescale 1ns / 1ns

module cmd_ctrl_tb;
  
parameter p_clk_freq = 50_000_000;
parameter p_baud_freq = 115_200;

localparam p_clk_half_period = 1_000_000_000 / p_clk_freq / 2;
localparam p_count = (p_clk_freq + (p_baud_freq / 2)) / p_baud_freq;



wire [7:0]  w_cmd;
wire [63:0] w_cmd_data;
wire        w_cmd_new;
wire        w_loopback;
wire        w_tx;
reg         r_rx = 1'b1;

reg [63:0]  r_resp_data = 64'd0;
reg         r_resp_ready = 1'b0;

cmd_controller ctrl (
    .i_clk(r_clk),
    .i_rst(r_rst),
    
    .i_resp_ready(1'b1),
    .i_resp_data(64'h3837363534333231),
    
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
    .i_clk(r_clk),
    .i_rst(r_rst),
    .i_loopback(w_loopback),
    .o_tx(w_tx),
    .o_tx_done(w_tx_done),
    .i_tx_start(w_tx_start),
    .i_tx_data(w_tx_data),
    .i_rx(r_rx),
    .o_rx_new(w_rx_new),
    .o_rx_err(o_rx_err),
    .o_rx_data(w_rx_data)
);

reg r_rst = 1'b1;
reg r_clk = 1'b0;
always #p_clk_half_period r_clk <= ~r_clk;

task clk;
    for (int i = 0; i < p_count; i = i + 1) begin
        @(posedge r_clk);
    end
endtask

//Task to send data over MOSI
task send_data(input [7:0] data);
	integer i;
	r_rx = 1'b0;
	clk();
	for(i = 0; i < 8; i = i + 1) begin
		r_rx = data[i];
		clk();
	end
	r_rx = ^data;
	clk();
	r_rx = 1'b1;
	clk();
	clk();
endtask	

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,cmd_ctrl_tb);

    r_rst = 1'b0;
    @(posedge r_clk);
    r_rst = 1'b1;
    @(posedge r_clk);
    
    send_data(8'h70);
    #(p_clk_half_period * 50000);
    send_data(8'h31);
    #(p_clk_half_period * 50000);
    send_data(8'h32);
    
    
    #(p_clk_half_period * 100000);

    $finish;
end

endmodule

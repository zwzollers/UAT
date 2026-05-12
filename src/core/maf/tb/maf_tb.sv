`timescale 1ns / 1ns

module maf_tb;

parameter p_filter_len = 5;
  
reg r_rst   = 1'b1;

reg r_new_data = 1'b0;
reg [7:0] r_data = 8'd0;
wire [7:0] w_avg;

reg r_clk = 1'b0;

maf #(
    .p_data_size(8),
    .p_filter_len(p_filter_len)
) test (
    .i_data(r_data),
    .o_avg(w_avg),
    
    .i_new_data(r_new_data),
    .i_rst(r_rst),
    .i_clk(r_clk)
);

always #1 r_clk <= ~r_clk;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,maf_tb);

    r_rst = 1'b0;
    #10
    r_rst = 1'b1;
    #10

    for (int i = 0; i < p_filter_len*20; i = i + 1) begin

        // if (i >= p_filter_len)
        //     r_data = 0;
        // else
        //     r_data = i;
        r_data = 155;
        #1
        r_new_data = 1'b1;
        #25
        r_new_data = 1'b0;
        #25

        $display("current avg: %d", w_avg);
    end

    $display("Testbench finished OK");
    $finish;
end

endmodule

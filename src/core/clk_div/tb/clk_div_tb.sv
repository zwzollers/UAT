`timescale 1ns / 1ns

module clk_div_tb;
  
parameter p_input_freq = 50_000_000;
parameter p_output_freq = 115_200;
parameter p_pulses = 10;

localparam p_input_clk_half_period = 1_000_000_000 / p_input_freq / 2;
localparam p_output_clk_half_period = 1_000_000_000 / p_output_freq / 2;

reg     r_input_clk = 1'b0;
reg     r_rst   = 1'b1;
wire    w_output_clk;


clk_div #(
    .p_input_freq(p_input_freq),
    .p_output_freq(p_output_freq)
) clk (
    .i_clk (r_input_clk),
    .i_rst (r_rst),
    .o_clk (w_output_clk)
);

always #p_input_clk_half_period r_input_clk <= ~r_input_clk;

time last_edge = 0;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,clk_div_tb);

    r_rst = 1'b0;
    @(posedge r_input_clk);
    @(posedge r_input_clk);
    r_rst = 1'b1;
    
    $display("expected frequency: %d", p_output_freq);

    for (int i = 0; i < p_pulses; i = i + 1) begin

        @(w_output_clk);
        last_edge = $time;
        @(w_output_clk);

        $display("pulse %d: frequency: %dHz", i, 1_000_000_000 / (($time - last_edge) * 2));
    end

    $display("Testbench finished OK");
    $finish;
end

endmodule

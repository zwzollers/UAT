// p_output_freq must be less than half of p_input_freq
// will find the nearest integer division of p_input_freq 
module clk_div #(
    parameter       p_input_freq,
    parameter       p_output_freq
) (
    input           i_clk,
    input           i_rst,
    output          o_clk
);

// rounds to the nearest clock count 
// multiply p_output_freq by 2 so that it goes through a full cycle instead of hal a cycle
localparam p_count =        (p_input_freq + p_output_freq) / (p_output_freq * 2);
localparam p_count_size =   $clog2(p_count);

reg [p_count_size-1:0]  r_count = {p_count{1'b0}};
reg                     r_clk   = 1'b0;

always @(posedge i_clk) begin
    if (~i_rst) begin
        r_count <= {p_count{1'b0}};
        r_clk   <= 1'b0;
    end
    else begin
        if (r_count >= p_count-1) begin
            r_count <= {p_count{1'b0}};
            r_clk   <= ~r_clk;
        end
        else begin
            r_count <= r_count + 1'b1;
        end
    end
end

assign o_clk = r_clk;

endmodule
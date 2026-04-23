module fifo #(
    parameter       p_depth
) (
    input           i_clk,
    input           i_rst,
    input           i_sgnl,
    output          o_sgnl
);

reg [p_depth-1:0] fifo = {p_depth{1'b0}};

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        fifo = {p_depth{1'b0}};
    end
    else begin
        fifo = {i_sgnl, fifo[p_depth-2:0]};
    end
end

assign o_sgnl = fifo[0];

endmodule
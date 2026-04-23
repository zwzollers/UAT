module maf #(
    parameter       p_data_size,
    parameter       p_filter_len
) (
    input [p_data_size-1:0]  i_data,
    output [p_data_size-1:0] o_avg,
    
    input           i_new_data,
    input           i_rst
);

localparam p_filter_len_size = $clog2(p_filter_len);

localparam p_data_max = (2 ** p_data_size) - 1;
localparam p_sum_size = $clog2(p_data_max * p_filter_len);

reg [p_filter_len-1:0] [p_data_size-1:0] r_array;
reg [p_filter_len_size-1:0] r_idx;
reg [p_sum_size-1:0] r_sum;
reg [p_data_size-1:0] r_avg;


always @(posedge i_new_data or negedge i_rst) begin
    if (~i_rst) begin
        r_array = {(p_data_size*p_filter_len){1'b0}};
        r_idx = {p_filter_len_size{1'b0}};
        r_sum = {p_sum_size{1'b0}};
        r_avg = {p_data_size{1'b0}};
    end
    else begin
        r_sum = r_sum + i_data - r_array[r_idx];
        r_avg = r_sum / p_filter_len;
        
        r_array[r_idx] = i_data;
        
        if (r_idx >= p_filter_len-1) 
            r_idx = {p_filter_len_size{1'b0}};
        else 
            r_idx = r_idx + 1;
    end
end

assign o_avg = r_avg;

endmodule
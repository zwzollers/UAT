module sev_seg #(
    parameter       p_active
) (
    input [3:0]     i_char,
    output [6:0]    o_segs
);

wire [6:0] w_segs = 
    (i_char == 4'h0) ? 7'b1000000 :
    (i_char == 4'h1) ? 7'b1111001 :
    (i_char == 4'h2) ? 7'b0100100 :
    (i_char == 4'h3) ? 7'b0110000 :
    (i_char == 4'h4) ? 7'b0011001 :
    (i_char == 4'h5) ? 7'b0010010 :
    (i_char == 4'h6) ? 7'b0000010 :
    (i_char == 4'h7) ? 7'b1111000 :
    (i_char == 4'h8) ? 7'b0000000 :
    (i_char == 4'h9) ? 7'b0010000 :
    (i_char == 4'ha) ? 7'b0001000 :
    (i_char == 4'hb) ? 7'b0000011 :
    (i_char == 4'hc) ? 7'b1000110 :
    (i_char == 4'hd) ? 7'b0100001 :
    (i_char == 4'he) ? 7'b0000110 :
                       7'b0001110 ;
                     
assign o_segs = (p_active == 1) ? ~w_segs : w_segs;

endmodule
module cmd_controller (
    input           i_clk,
    input           i_rst,
    
    input           i_resp_ready,
    input  [63:0]   i_resp_data,
    
    output [7:0]    o_cmd,
    output [63:0]   o_cmd_data,
    output          o_cmd_new,
    
    input  [7:0]    i_rx_data,
    input           i_rx_new,
    input           i_rx_err,
    
    input           i_tx_done,
    output          o_tx_start,
    output [7:0]    o_tx_data,
    
    output          o_loopback
);

`include "cmds.vh"
	
wire [4:0] w_cmd_data_bytes;
wire [4:0] w_resp_data_bytes;
wire       w_cmd_cli;
                     
wire [3:0] w_rx_data_hex = 
    (i_rx_data == 8'h30) ? 4'h0 :
    (i_rx_data == 8'h31) ? 4'h1 :
    (i_rx_data == 8'h32) ? 4'h2 :
    (i_rx_data == 8'h33) ? 4'h3 :
    (i_rx_data == 8'h34) ? 4'h4 :
    (i_rx_data == 8'h35) ? 4'h5 :
    (i_rx_data == 8'h36) ? 4'h6 :
    (i_rx_data == 8'h37) ? 4'h7 :
    (i_rx_data == 8'h38) ? 4'h8 :
    (i_rx_data == 8'h39) ? 4'h9 :
    (i_rx_data == 8'h41) ? 4'hA :
    (i_rx_data == 8'h42) ? 4'hB :
    (i_rx_data == 8'h43) ? 4'hC :
    (i_rx_data == 8'h44) ? 4'hD :
    (i_rx_data == 8'h45) ? 4'hE :
                           4'hF ;
                     
wire [7:0] w_tx_data_hex = 
    (r_resp_data[3:0] == 4'h0) ? 8'h30 :
    (r_resp_data[3:0] == 4'h1) ? 8'h31 :
    (r_resp_data[3:0] == 4'h2) ? 8'h32 :
    (r_resp_data[3:0] == 4'h3) ? 8'h33 :
    (r_resp_data[3:0] == 4'h4) ? 8'h34 :
    (r_resp_data[3:0] == 4'h5) ? 8'h35 :
    (r_resp_data[3:0] == 4'h6) ? 8'h36 :
    (r_resp_data[3:0] == 4'h7) ? 8'h37 :
    (r_resp_data[3:0] == 4'h8) ? 8'h38 :
    (r_resp_data[3:0] == 4'h9) ? 8'h39 :
    (r_resp_data[3:0] == 4'hA) ? 8'h41 :
    (r_resp_data[3:0] == 4'hB) ? 8'h42 :
    (r_resp_data[3:0] == 4'hC) ? 8'h43 :
    (r_resp_data[3:0] == 4'hD) ? 8'h44 :
    (r_resp_data[3:0] == 4'hE) ? 8'h45 :
                                 8'h46 ;
    

reg r_rx_new_prev = 1'b0;
wire w_rx_new_rising = ~r_rx_new_prev & i_rx_new;

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_rx_new_prev = 1'b0;
    end
    else begin
        r_rx_new_prev <= i_rx_new;
    end
end

reg r_tx_done_prev = 1'b0;
wire w_tx_done_rising = ~r_tx_done_prev & i_tx_done;

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_tx_done_prev = 1'b0;
    end
    else begin
        r_tx_done_prev <= i_tx_done;
    end
end

// Output Registers
reg [7:0]  r_cmd      = 8'd0;
reg [63:0] r_cmd_data = 64'd0;
reg        r_cmd_new  = 1'b0;
reg [7:0]  r_tx_data  = 8'd0;
reg        r_tx_start = 1'b0;
reg        r_loopback = 1'b1;

// state parameters
parameter [3:0]
    s_idle         = 4'd0,
    s_cmd          = 4'd1,
    s_data         = 4'd2,
    s_cmd_process  = 4'd3,
    s_resp         = 4'd4,
    s_tx_wait      = 4'd5,
    s_pre_data_cli = 4'd6,
    s_pre_resp_cli = 4'd7,
    s_post_cli_cr  = 4'd8,
    s_post_cli_nl  = 4'd9;

// state registers
reg [3:0]  r_state           = s_idle;
reg [3:0]  r_next_state      = s_idle;
reg [63:0] r_resp_data       = 64'd0;
reg [3:0]  r_cmd_data_count  = 3'd0;
reg [3:0]  r_resp_data_count = 3'd0;

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_cmd      = 8'd0;
        r_cmd_data = 64'd0;
        r_cmd_new  = 1'b0;
        r_tx_data  = 8'd0;
        r_tx_start = 1'b0;
        r_loopback = 1'b1;
        
        r_state           = s_idle;
        r_resp_data       = 64'd0; 
        r_cmd_data_count  = 3'd0;
        r_resp_data_count = 3'd0;
    end
    else begin
        case (r_state)
            s_idle: begin
                if (w_rx_new_rising) begin
                    r_cmd_new <= 1'b0;
                    r_state <= s_cmd;
                    r_cmd <= i_rx_data;
                end
            end 
            
            s_cmd: begin
                r_state <= (w_cmd_cli) ? s_pre_data_cli : s_data;
                r_cmd_data_count <= (w_cmd_cli) ? w_cmd_data_bytes << 1 : w_cmd_data_bytes;
                r_resp_data_count <= (w_cmd_cli) ? w_resp_data_bytes << 1 : w_resp_data_bytes;
            end 
            
            s_pre_data_cli: begin
                r_tx_start   <= 1'b1;
                r_tx_data    <= 8'h3A;
                r_state      <= s_tx_wait;
                r_next_state <= s_data;
            end
            
            s_data: begin
                if (r_cmd_data_count == 0) begin
                    r_state <= (w_cmd_cli && r_resp_data_count) ? s_pre_resp_cli : s_cmd_process;
                    r_cmd_new <= 1'b1;
                end 
                else if (w_rx_new_rising) begin
                    r_cmd_data <= (w_cmd_cli) ? ((r_cmd_data << 4) | w_rx_data_hex) : ((r_cmd_data << 8) | i_rx_data);
                    r_cmd_data_count = r_cmd_data_count - 1;
                end
            end 
            
            s_pre_resp_cli: begin
                r_tx_start   <= 1'b1;
                r_tx_data    <= 8'h3E;
                r_state      <= s_tx_wait;
                r_next_state <= s_cmd_process;
            end
            
            s_cmd_process: begin
                if (i_resp_ready) begin
                    r_state      <= s_resp;
                    r_resp_data  <= i_resp_data;
                    r_loopback   <= 1'b0;
                end
            end
            
            s_resp: begin
                if (r_resp_data_count == 0) begin
                    r_state    <= (w_cmd_cli) ? s_post_cli_cr : s_idle;
                    r_tx_start <= 1'b0;
                    r_loopback <= 1'b1;
                end 
                else begin
                    r_resp_data      <= (w_cmd_cli) ? (r_resp_data >> 4) : (r_resp_data >> 8);
                    r_tx_data        <= (w_cmd_cli) ? w_tx_data_hex : r_resp_data[7:0];
                    r_state          <= s_tx_wait;
                    r_next_state     <= s_resp;
                    r_tx_start       <= 1'b1;
                    r_resp_data_count <= r_resp_data_count - 1;
                end
            end
            
            s_post_cli_cr: begin
                r_tx_start   <= 1'b1;
                r_tx_data    <= 8'h0D;
                r_state      <= s_tx_wait;
                r_next_state <= s_post_cli_nl;
            end
            
            s_post_cli_nl: begin
                r_tx_start   <= 1'b1;
                r_tx_data    <= 8'h0A;
                r_state      <= s_tx_wait;
                r_next_state <= s_idle;
            end
            
            s_tx_wait: begin
                r_loopback <= 1'b0;
                r_tx_start <= 1'b0;
                if (w_tx_done_rising) begin
                    r_loopback <= 1'b1;
                    r_state    <= r_next_state;
                end
            end
        endcase
    end
end

assign o_tx_data  = r_tx_data;
assign o_tx_start = r_tx_start;
assign o_cmd      = r_cmd;
assign o_cmd_data = r_cmd_data;
assign o_cmd_new  = r_cmd_new;
assign o_loopback = r_loopback;

endmodule
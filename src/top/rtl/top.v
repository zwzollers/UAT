module top #(
    parameter       p_clk_freq,
    parameter       p_baud_freq
)(
    input           i_clk,
	input           i_rst,
	
	input           i_rx,
	output          o_tx,
	// board IO
	input           button,
	output [7:0]    o_leds,
	// LCD IO
	output          o_lcd_rs,
	output          o_lcd_e,
	output          o_lcd_rw,
	output [7:0]    o_lcd_db,
	// ping sensor IO
	output          o_trigger,
    input           i_echo,
    
    output          o_trigger_1,
    input           i_echo_1,
    
   	output [12:0]   MEM_A,
	output [2:0]    MEM_BA,
	output          MEM_CK,
	output          MEM_CKN,
	output          MEM_CKE,
	output          MEM_CSN,
	output          MEM_RAS_N,
	output          MEM_WE,
	output          MEM_RST_N,
	output          MEM_CAS_N,
	inout  [15:0]   MEM_DQ,
	inout  [1:0]    MEM_DQS,
	inout  [1:0]    MEM_DQSN,
	output          MEM_ODT,
	output [1:0]    MEM_DM,
	input           MEM_RZQ
);

// Ping sensor 
wire [15:0] w_echo_time;
wire w_new_echo;

assign o_leds = w_echo_time[7:0];

ping driver(
    .i_clk(i_clk), 
    .i_start(~ping_clk),
    .i_rst(i_rst), 
    .o_trigger(o_trigger), 
    .i_echo(i_echo), 
    .o_echo_time(w_echo_time),
    .o_new(w_new_echo)
);

// moving average filter
wire signed [15:0] w_avg_echo;

maf #(
    .p_data_size(16),
    .p_filter_len(50)
) test (
    .i_data(w_echo_time),
    .o_avg(w_avg_echo),
    
    .i_new_data(w_new_echo),
    .i_rst(i_rst),
    .i_clk(i_clk)
);

// Ping sensor 1 
wire [15:0] w_echo_time_1;
wire w_new_echo_1;

ping driver_1(
    .i_clk(i_clk), 
    .i_start(ping_clk),
    .i_rst(i_rst), 
    .o_trigger(o_trigger_1), 
    .i_echo(i_echo_1), 
    .o_echo_time(w_echo_time_1),
    .o_new(w_new_echo_1)
);

// moving average filter 1
wire signed [15:0] w_avg_echo_1;

maf #(
    .p_data_size(16),
    .p_filter_len(50)
) test_1 (
    .i_data(w_echo_time_1),
    .o_avg(w_avg_echo_1),
    
    .i_new_data(w_new_echo_1),
    .i_rst(i_rst),
    .i_clk(i_clk)
);

// lcd controller and refresh clock
wire signed [32:0] wind_speed_x;
wire signed [32:0] wind_speed_y;
wire [10:0] wind_speed;// = wind_speed_x;
wire [8:0] wind_direction;

wire refresh_lcd;

reg signed [15:0] r_x_cal = 11'h153;
reg signed [15:0] r_y_cal = 11'h137;

assign wind_speed_x = (w_avg_echo_1 - r_x_cal) * 4;
assign wind_speed_y = (w_avg_echo - r_y_cal) * 4;

assign wind_direction = ((wind_direction_radians + 8'b01100100) * 11'b11100101001) >> 11;

wire [31:0] wind_direction_radians;

atan2 tan(
	.areset(~i_rst), 
	.clk(refresh_lcd),    
	.q(wind_direction_radians),      
	.x(wind_speed_x/10),      
	.y(wind_speed_y/10)       
);

sqrt sqrt(
	.clk(i_clk),
	.radical((wind_speed_x*wind_speed_x) + (wind_speed_y*wind_speed_y)),
	.q(wind_speed),
	.remainder()
);

clk_div #(
    .p_input_freq(50000000),
    .p_output_freq(1)
) baud_clk (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_clk(refresh_lcd)
);

wire ping_clk;

clk_div #(
    .p_input_freq(50000000),
    .p_output_freq(20)
) sample_clk (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_clk(ping_clk)
);

lcd_controller lcd(
    .i_clk(i_clk), 
    .ar(i_rst), 
    .wind_data(wind_speed), 
    .wind_direction(wind_direction), 
    .new_data(refresh_lcd), 
    .o_lcd_rs(o_lcd_rs), 
	.o_lcd_rw(o_lcd_rw), 
	.o_lcd_e(o_lcd_e), 
	.o_lcd_db(o_lcd_db), 
	.init_done(), 
	.done_writing()
);

wire [7:0]  w_cmd;
wire [63:0] w_cmd_data;
wire [63:0] w_resp_data;
wire        w_cmd_new;
wire        w_loopback;

assign w_resp_data = 
    (w_cmd == 8'h70) ? w_cmd_data     :
    (w_cmd == 8'h73) ? {wind_speed[3:0], wind_speed[7:4], wind_speed[10:8], 5'd0}    :
    (w_cmd == 8'h64) ? wind_direction :
    (w_cmd == 8'h63) ? 8'hFF          :
                       64'd0          ;
                    
reg r_prev_new_cmd;
wire w_rising_new_cmd= ~r_prev_new_cmd && w_cmd_new;

always @(posedge i_clk or negedge i_rst) begin
    if (~i_rst) begin
        r_prev_new_cmd = 1'b0;
    end
    else begin
        r_prev_new_cmd = w_cmd_new;
    end
end

always @(posedge i_clk) begin
    if (w_rising_new_cmd) begin
        if (w_cmd == 8'h63) begin
            r_x_cal = w_avg_echo_1;
            r_y_cal = w_avg_echo;
        end
    end
end

cmd_controller ctrl (
    .i_clk(i_clk),
    .i_rst(i_rst),
    
    .i_resp_ready(1'b1),
    .i_resp_data(w_resp_data),
    
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
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_loopback(w_loopback),
    .o_tx(o_tx),
    .o_tx_done(w_tx_done),
    .i_tx_start(w_tx_start),
    .i_tx_data(w_tx_data),
    .i_rx(i_rx),
    .o_rx_new(w_rx_new),
    .o_rx_err(o_rx_err),
    .o_rx_data(w_rx_data)
);

//Instantiate HPS and PIO

wire [31:0] wind_data_sd;
assign wind_data_sd = {5'b0, wind_speed, 7'b0, wind_direction};

soc_design soc_inst(
	.clk_clk(i_clk),            //       clk.clk
	.memory_mem_a(MEM_A),       //    memory.mem_a
	.memory_mem_ba(MEM_BA),      //          .mem_ba
	.memory_mem_ck(MEM_CK),      //          .mem_ck
	.memory_mem_ck_n(MEM_CKN),    //          .mem_ck_n
	.memory_mem_cke(MEM_CKE),     //          .mem_cke
	.memory_mem_cs_n(MEM_CSN),    //          .mem_cs_n
	.memory_mem_ras_n(MEM_RAS_N),   //          .mem_ras_n
	.memory_mem_cas_n(MEM_CAS_N),   //          .mem_cas_n
	.memory_mem_we_n(MEM_WE),    //          .mem_we_n
	.memory_mem_reset_n(MEM_RST_N), //          .mem_reset_n
	.memory_mem_dq(MEM_DQ),      //          .mem_dq
	.memory_mem_dqs(MEM_DQS),     //          .mem_dqs
	.memory_mem_dqs_n(MEM_DQSN),   //          .mem_dqs_n
	.memory_mem_odt(MEM_ODT),     //          .mem_odt
	.memory_mem_dm(MEM_DM),      //          .mem_dm
	.memory_oct_rzqin(MEM_RZQ),   //          .oct_rzqin
	.mpu_eventi(1'b0),         //       mpu.eventi
	.mpu_evento(),         //          .evento
	.mpu_standbywfe(),     //          .standbywfe
	.mpu_standbywfi(),     //          .standbywfi
	.wind_data_export(wind_data_sd)    // wind_data.export
);

endmodule
module top (
    
    input           i_clk,
	input           i_rst,
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
    input           i_echo
);

// Ping sensor 
wire [15:0] w_echo_time;
wire w_new_echo;

ping driver(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .o_trigger(o_trigger), 
    .i_echo(i_echo), 
    .o_echo_time(w_echo_time),
    .o_new(w_new_echo)
);

// moving average filter
wire [15:0] w_avg_echo;

maf #(
    .p_data_size(16),
    .p_filter_len(128)
) test (
    .i_data(w_echo_time),
    .o_avg(w_avg_echo),
    
    .i_new_data(r_new_data),
    .i_rst(i_rst)
);

// lcd controller and refresh clock
wire [10:0] wind_speed = w_avg_echo[10:0];	
wire [8:0] wind_direction = 9'd270;

wire refresh_lcd;

clk_div #(
       .p_input_freq(50000000),
       .p_output_freq(1)
   ) baud_clk (
       .i_clk(i_clk),
       .i_rst(ar),
       .o_clk(refresh_lcd)
   );

lcd_controller lcd(
    .i_clk(i_clk), 
    .ar(i_rst), 
    .wind_data(wind_speed), 
    .wind_direction(wind_direction), 
    .new_data(~button), 
    .o_lcd_rs(o_lcd_rs), 
	.o_lcd_rw(o_lcd_rw), 
	.o_lcd_e(o_lcd_e), 
	.o_lcd_db(o_lcd_db), 
	.init_done(), 
	.done_writing()
);

endmodule
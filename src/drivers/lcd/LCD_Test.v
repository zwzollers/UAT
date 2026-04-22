module LCD_Test(clk, ar, button, LCD_RS, LCD_E, LCD_RW, LCD_DB, LEDS);
	input clk /*synthesis chip_pin = "V11"*/;
	input ar /*synthesis chip_pin = "AH17"*/;
	input button /*synthesis chip_pin = "AH16"*/;
	output LCD_RS /*synthesis chip_pin = "AH14"*/;
	output LCD_E /*synthesis chip_pin = "AG14"*/;
	output LCD_RW /*synthesis chip_pin = "AH3"*/;
	output [7:0] LCD_DB /*synthesis chip_pin = "W14, W11, AB23, AC22, AD17, AD20, AE24, AE6"*/;
	output [1:0] LEDS /*synthesis chip_pin = "W15, AA24"*/;

	wire [10:0] wind_speed = 11'd809;	
	wire [8:0] wind_direction = 9'd270;
	wire init_done = LEDS[1];
	wire new_data = ~button;
	wire lcd_clk;
	
	clk_div #(25, 25'd24999) clk_27K(.ar(ar), .clk_in(clk), .clk_out(lcd_clk));

	lcd_controller lcd(.clk(lcd_clk), .ar(ar), .wind_data(wind_speed), .wind_direction(wind_direction), .new_data(new_data), .LCD_rs(LCD_RS), 
						.LCD_rw(LCD_RW), .LCD_e(LCD_E), .LCD_db(LCD_DB), .init_done(init_done), .done_writing(LEDS[0]));

endmodule
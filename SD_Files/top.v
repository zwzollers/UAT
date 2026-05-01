module LCD_Test(clk, ar, button, LCD_RS, LCD_E, LCD_RW, LCD_DB, LEDS, MEM_A, MEM_BA, MEM_CK, MEM_CKN, MEM_CKE, MEM_CSN, MEM_DM, MEM_RAS_N, MEM_CAS_N, MEM_WE, MEM_RST_N, MEM_DQ, MEM_DQS, MEM_DQSN, MEM_ODT, MEM_RZQ);
	input clk /*synthesis chip_pin = "V11"*/;
	input ar /*synthesis chip_pin = "AH17"*/;
	input button /*synthesis chip_pin = "AH16"*/;
	output LCD_RS /*synthesis chip_pin = "AH14"*/;
	output LCD_E /*synthesis chip_pin = "AG14"*/;
	output LCD_RW /*synthesis chip_pin = "AH3"*/;
	output [7:0] LCD_DB /*synthesis chip_pin = "W14, W11, AB23, AC22, AD17, AD20, AE24, AE6"*/;
	output [1:0] LEDS /*synthesis chip_pin = "W15, AA24"*/;
	output [12:0] MEM_A;
	output [2:0] MEM_BA;
	output MEM_CK;
	output MEM_CKN;
	output MEM_CKE;
	output MEM_CSN;
	output MEM_RAS_N;
	output MEM_WE;
	output MEM_RST_N;
	output MEM_CAS_N;
	inout [15:0] MEM_DQ;
	inout [1:0] MEM_DQS;
	inout [1:0] MEM_DQSN;
	output MEM_ODT;
	output [1:0] MEM_DM;
	input MEM_RZQ;


	wire [10:0] wind_data = 11'd547;
	wire [8:0] wind_direction = 9'd85;
	wire [31:0] wind_data_sd;
	wire init_done = LEDS[1];
	wire new_data = ~button;
	
	assign wind_data_sd = {5'b0, wind_data, 7'b0, wind_direction};	//Save wind data sent For SD Card in 32-bit format
	
	wire lcd_clk;
	
	clk_div #(25, 25'd24999) clk_27K(.ar(ar), .clk_in(clk), .clk_out(lcd_clk));
	
	//Instantiate HPS and PIO
	soc_design soc_inst(
		.clk_clk(clk),            //       clk.clk
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
	
	lcd_controller lcd(.clk(lcd_clk), .ar(ar), .wind_data(wind_data), .wind_direction(wind_direction), .new_data(new_data), .LCD_rs(LCD_RS), .LCD_rw(LCD_RW), .LCD_e(LCD_E), .LCD_db(LCD_DB), .init_done(init_done), .done_writing(LEDS[0]));

endmodule
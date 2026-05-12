
module soc_design (
	clk_clk,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	mpu_eventi,
	mpu_evento,
	mpu_standbywfe,
	mpu_standbywfi,
	wind_data_export);	

	input		clk_clk;
	output	[12:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[15:0]	memory_mem_dq;
	inout	[1:0]	memory_mem_dqs;
	inout	[1:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[1:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	input		mpu_eventi;
	output		mpu_evento;
	output	[1:0]	mpu_standbywfe;
	output	[1:0]	mpu_standbywfi;
	input	[31:0]	wind_data_export;
endmodule

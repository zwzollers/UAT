//Testbench for SPI.v
`timescale 1 ns / 1 ns

module spi_tb;

reg ar;		//Reset
reg clk;	//System clock
reg sck;	//SPI sck
reg mosi;	//SPI MOSI
wire miso;	//SPI MISO
reg cs;		//Chip select

spi u1 (
    .ar(ar), 
	.clk(clk), 
	.sck(sck), 
	.mosi(mosi), 
	.miso(miso), 
	.cs(cs)
); //Instantiate SPI.v
	
//Initialize sck toggle speed
task SPI_Clock;
	begin
	#100 sck = 1'b1;
	#100 sck = 1'b0;
	end
endtask

//Task to send data over MOSI
task send_data(input [7:0] data);
	integer i;
	for(i = 7; i >= 0; i = i - 1) begin
		mosi = data[i]; //Send MSB of data over mosi
		SPI_Clock(); //Toggle sck after transmitting bit
	end
endtask	
	

initial begin
	$dumpfile("wave.vcd");
    $dumpvars(0,spi_tb);
	//Set to default conditions
	clk = 1'b0;
	ar = 1'b0;
	sck = 1'b0;
	cs = 1'b1;
	mosi = 1'b0;
	
	#50;
	ar = 1'b1;		//Start reset
	
	#100;
	
	cs = 1'b0;			//Start transmission
	#50;
	send_data(8'hC3);	//Send 0xC3 over MOSI
	#50;
	cs = 1'b1;			//Stop transmission
	
	#200;
	cs = 1'b0;			//Start second transmission
	#50;
	send_data(8'hA3);	//Send 0xA3 over MOSI
	#50;
	cs = 1'b1;			//Stop second transmission

	#500;
	$finish;
end
	
always #10 clk = ~clk;	
	
endmodule
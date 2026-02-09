//Adapted from fpga4fun.com
//SPI slave module
module SPI(ar, clk, sck, mosi, miso, cs);
	input ar;		//reset
	input clk;		//system clock
	input sck;		//SPI master clock
	input mosi;		//SPI MOSI
	input cs;		//SPI chip select
	output miso;	//SPI MISO
	
	reg [2:0] sck_reg; //sck shift register
	
	//sync SCK to system clock
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			sck_reg <= 3'd0;
			end
		else
			sck_reg <= {sck_reg[1:0], sck};
		
	wire sck_rising_edge = (sck_reg[2:1] == 2'b01); 	//rising edge of sck
	wire sck_falling_edge = (sck_reg[2:1] == 2'b10); 	//falling edge of sck
	
	reg [2:0] cs_reg; //CS shift register
	
	//sync cs to system clock
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			cs_reg <= 3'd0;
			end
		else
			cs_reg <= {cs_reg[1:0], cs};
		
	wire cs_rising_edge = (cs_reg[2:1] == 2'b01); 	//rising edge means message stops
	wire cs_falling_edge = (cs_reg[2:1] == 2'b10);	//falling edge means message starts
	wire cs_active = ~cs_reg[1];					//CS active low
	
	reg [1:0] mosi_reg; //MOSI shift register
	
	//synce MOSI to system clock
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			mosi_reg <= 2'd0;
			end
		else
			mosi_reg <= {mosi_reg[0], mosi};
	
	wire mosi_data = mosi_reg[1]; 
	
	
	reg [2:0] bit_ctr;		//track bits read
	reg [7:0] byte_data;	//value of recieved byte
	
	//recieve MOSI data
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			bit_ctr <= 3'd0;
			byte_data <= 8'd0;
			end
		else
			begin
			//reset bit counter when inactive
			if(~cs_active)
				bit_ctr <= 3'd0;
			else
				//read on rising edge of SCK
				if(sck_rising_edge)
					begin
					bit_ctr <= bit_ctr + 1'b1;
					byte_data <= {byte_data[6:0], mosi_data};
					end
			end
		
	reg [7:0] sent_data;		//value of transmitted
	reg [7:0] message_count;	//value of message count 
	
	//count messages
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			message_count <= 8'd0;
			end
		else
			begin
			if(cs_falling_edge)
				begin
				message_count <= message_count + 8'h1;
				end
			end
			
	//transmit MISO data	
	always @(negedge ar or posedge clk)
		if(~ar)
			begin
			sent_data <= 8'd0;
			
			end
		else
			begin
			if(cs_active)
				begin
				if(cs_falling_edge)
					sent_data <= message_count; //send message count when transmission begins
					//sent_data <= 8'hF5; //Temporary MISO test 
				else
					//transmit on falling edge of SCK 
					if(sck_falling_edge)
						begin
						if(bit_ctr == 3'd0)
							sent_data <= 8'd0; //send 0 once bit counter resets
						else
							sent_data <= {sent_data[6:0], 1'b0};
						end
				end
			end
			
			
	assign miso = sent_data[7]; //send MSB first
		

endmodule
module lcd_controller (clk, ar, wind_data, new_data, LCD_rs, LCD_rw, LCD_e, LCD_db, init_done, done_writing);
	input clk;
	input ar;
	input [10:0] wind_data;
	input new_data;
	output reg LCD_rs;
	output LCD_rw;
	output reg LCD_e;
	output reg [7:0] LCD_db;
	output reg init_done;
	output reg done_writing;
	
	
	parameter [3:0] Idle0 = 4'd0, Func_Set = 4'd1, Wait1 = 4'd2, CMD_Wait1 = 4'd3, Display_On = 4'd4, Wait2 = 4'd5,
					CMD_Wait2 = 4'd6, Clear = 4'd7, Wait3 = 4'd8, CMD_Wait3 = 4'd9, Entry_Mode = 4'd10, Wait4 = 4'd11, 
					CMD_Wait4 = 4'd12, Done = 4'd13;

	parameter [1:0] Idle_Write = 2'd0, Begin_Write = 2'd1, Write = 2'd2, Write_done = 2'd3;
	
	parameter [3:0] Idle1 = 4'd0, Clear_Screen = 4'd1, Clear_Wait = 4'd2, Write_Hundreds = 4'd3, Wait_H = 4'd4, Write_Tens = 4'd5, 
					Wait_T = 4'd6, Write_Ones = 4'd7, Wait_O = 4'd8, Write_Decimal = 4'd9, Wait_D = 4'd10, Write_Tenths = 4'd11, Wait_Tenths = 4'd12,
					Done_Writing = 4'd13;

	reg [3:0] cs0;
	reg [3:0] cs1;
	reg [1:0] cs_Write;
	
	reg [7:0] write_data;
	reg [7:0] hundreds;
	reg [7:0] tens;
	reg [7:0] ones;
	reg [7:0] tenths;
	reg [21:0] timer;
	
	reg write_start;
	reg write_done;
	
	assign LCD_db = write_data;
	assign LCD_rw = 1'b0;
	
	always @(*)
		begin
		hundreds = (wind_data / 11'd1000);
		tens = (wind_data % 11'd1000) / 11'd100;
		ones = (wind_data % 11'd100) / 11'd10;
		tenths = (wind_data % 11'd10);
		end
		
	wire [7:0] write_hundreds = hundreds + 8'h30;
	wire [7:0] write_tens = tens + 8'h30;
	wire [7:0] write_ones = ones + 8'h30;
	wire [7:0] write_tenths = tenths + 8'h30;
	
	always @(negedge ar or posedge clk)
		begin
		if(~ar)
			begin
			write_data = 8'h00;
			timer = 22'd0;
			cs0 = Idle0;
			LCD_rs = 1'b0;
			LCD_e = 1'b0;
			init_done = 1'b0;
			end
			
		else
			case(cs0)
				Idle0:
					begin
					//2500000
					if(timer >= 22'd2500000)
						begin
						cs0 = Func_Set;
						init_done = 1'b0;
						end
					else
						timer = timer + 1'b1;
					end
					
				Func_Set:
					begin
					LCD_rs = 1'b0;
					write_data = 8'h30;
					LCD_e = 1'b1;
					timer  = 22'd0;
					cs0 = Wait1;
					end
				
				Wait1:
					begin
					if(timer >= 22'd20)
						begin
						LCD_e = 1'b0;
						timer = 22'd0;
						cs0 = CMD_Wait1;
						end
					else
						timer = timer + 1'b1;
					end
					
				CMD_Wait1:
					begin
					//2000
					if(timer >= 22'd20)
						cs0 = Display_On;
					else
						timer = timer + 1'b1;
					end
				
				Display_On:
					begin
					write_data = 8'h0C;
					timer = 22'd0;
					LCD_e = 1'b1;
					cs0 = Wait2;
					end
					
				Wait2:
					begin
					if(timer >= 22'd20)
						begin
						LCD_e = 1'b0;
						timer = 22'd0;
						cs0 = CMD_Wait2;
						end
					else
						timer = timer + 1'b1;
					end
					
				CMD_Wait2:
					begin
					//2000
					if(timer >= 22'd2000)
						cs0 = Clear;
					else
						timer = timer + 1'b1;
					end
					
				Clear:
					begin
					write_data = 8'h01;
					timer = 22'd0;
					LCD_e = 1'b1;
					cs0 = Wait3;
					end
					
				Wait3:
					begin
					if(timer >= 22'd20)
						begin
						LCD_e = 1'b0;
						timer = 22'd0;
						cs0 = CMD_Wait3;
						end
					else
						timer = timer + 1'b1;
					end
					
				CMD_Wait3:
					begin
					//80000
					if(timer >= 22'd80000)
						cs0 = Entry_Mode;
					else
						timer = timer + 1'b1;
					end	
				
				Entry_Mode:
					begin
					write_data = 8'h06;
					timer = 22'd0;
					LCD_e = 1'b1;
					cs0 = Wait4;
					end
					
				Wait4:
					begin
					if(timer >= 22'd20)
						begin
						LCD_e = 1'b0;
						timer = 22'd0;
						cs0 = CMD_Wait4;
						end
					else
						timer = timer + 1'b1;
					end
					
				CMD_Wait4:
					begin
					//2000
					if(timer >= 22'd2000)
						begin
						timer = 22'd0;
						cs0 = Done;
						end
					else
						timer = timer + 1'b1;
					end
					
				Done:
					begin
					init_done = 1'b1;
					end
				
				default:
					begin
					write_data = 8'h00;
					LCD_e = 1'b0;
					timer  = 22'd0;
					cs0 = Idle0;
					end
			endcase
		end

	always @(negedge ar or posedge clk)
		begin
		if(~ar)
			begin
			LCD_e = 1'b0;
			write_done = 1'b0;
			cs_Write = Idle_Write;
			end
			
		else
			case(cs_Write)
				Idle_Write:
					begin
					LCD_e = 1'b0;
					write_done = 1'b0;
					
					if(write_start)
						begin
						cs_Write = Begin_Write;
						end
					end
					
				Begin_Write:
					begin
					LCD_e = 1'b0;
					write_done = 1'b0;
					cs_Write = Write;
					end
					
				Write:
					begin
					LCD_e = 1'b1;
					write_done = 1'b0;
					cs_Write = Write_done;
					end
				
				Write_done:
					begin
					LCD_e = 1'b0;
					write_done = 1'b1;
					cs_Write = Idle_Write;
					end
				default:
					begin
					LCD_e = 1'b0;
					write_done = 1'b0;
					cs_Write = Idle_Write;
					end
			endcase
		end
					
		
	always @(negedge ar or posedge clk)
		begin
		if(~ar)
			begin
			write_data = 8'h00;
			write_start = 1'b0;
			LCD_rs = 1'b0;
			cs1 = Idle1;
			end
		else
			case(cs1)
				Idle1:
					begin
					write_start = 1'b0;
					write_data = 8'h00;
					LCD_rs = 1'b0;
					done_writing = 1'b0;
					
					if(init_done && new_data)
						begin
						cs1 = Clear_Screen;
						end
					else
						cs1 = Idle1;
					end
					
				Clear_Screen:
					begin
					write_start = 1'b1;
					write_data = 8'h01;
					LCD_rs = 1'b0;
					cs1 = Clear_Wait;
					end
				
				Clear_Wait:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Write_Hundreds;
						end
					end
					
				Write_Hundreds:
					begin
					write_start = 1'b1;
					write_data = write_hundreds;
					LCD_rs = 1'b1;
					cs1 = Wait_H;
					end
					
				Wait_H:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Write_Tens;
						end
					end
					
				Write_Tens:
					begin
					write_start = 1'b1;
					write_data = write_tens;
					LCD_rs = 1'b1;
					cs1 = Wait_T;
					end
					
				Wait_T:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Write_Ones;
						end
					end
					
				Write_Ones:
					begin
					write_start = 1'b1;
					write_data = write_ones;
					LCD_rs = 1'b1;
					cs1 = Wait_O;
					end
					
				Wait_O:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Write_Decimal;
						end
					end
					
				Write_Decimal:
					begin
					write_start = 1'b1;
					write_data = 8'h2E;
					LCD_rs = 1'b1;
					cs1 = Wait_D;
					end
					
				Wait_D:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Write_Tenths;
						end
					end
					
				Write_Tenths:
					begin
					write_start = 1'b1;
					write_data = write_tenths;
					LCD_rs = 1'b1;
					cs1 = Wait_Tenths;
					end
					
				Wait_Tenths:
					begin
					write_start = 1'b0;
					LCD_rs = 1'b0;
					
					if(write_done)
						begin
						cs1 = Done_Writing;
						end
					end
					
				Done_Writing:
					begin
					done_writing = 1'b1;
					cs1 = Idle1;
					end
					
				default:
					begin
					write_start = 1'b0;
					write_data = 8'h00;
					LCD_rs = 1'b0;
					done_writing = 1'b1;
					cs1 = Idle1;
					end
			endcase
		end	

endmodule
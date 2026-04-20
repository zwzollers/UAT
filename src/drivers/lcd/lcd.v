module lcd_controller (clk, ar, wind_data, wind_direction, new_data, LCD_rs, LCD_rw, LCD_e, LCD_db, init_done, done_writing);
	input clk;					//LCD clock 1kHz cycling every 1ms
	input ar;					//Reset
	input [10:0] wind_data;		//Raw wind speed displayed to LCD
	input [8:0] wind_direction; //Raw wind direction displayed to LCD
	input new_data;				//Indicates new data is recieved
	output LCD_rs;				//RS pin to clarify writing data or instructions
	output LCD_rw;				//RW pin to switch between read and write
	output LCD_e;				//Enable pin to initiate writes
	output [7:0] LCD_db;		//DB pin data written to the LCD
	output reg init_done;		//Indicates LCD is initialized
	output reg done_writing;	//Indicates LCD is finished writing
	
	//States for initializing LCD for 8-bit 2 line display
	parameter [3:0] Idle0 = 4'd0, Func_Set = 4'd1, Wait1 = 4'd2, CMD_Wait1 = 4'd3, Display_On = 4'd4, Wait2 = 4'd5,
					CMD_Wait2 = 4'd6, Clear = 4'd7, Wait3 = 4'd8, CMD_Wait3 = 4'd9, Entry_Mode = 4'd10, Wait4 = 4'd11, 
					CMD_Wait4 = 4'd12, Done = 4'd13;
	
	//States to pulse LCD_E during writes
	parameter [1:0] Idle_Write = 2'd0, Begin_Write = 2'd1, Write = 2'd2, Write_Done = 2'd3;
	
	//States to determine what to write
	parameter [5:0] Idle1 = 6'd0, Clear_Screen = 6'd1, Clear_Wait = 6'd2, Write_Hundreds = 6'd3, Wait_Hund = 6'd4, Write_Tens = 6'd5, 
					Wait_T = 6'd6, Write_Ones = 6'd7, Wait_O = 6'd8, Write_Decimal = 6'd9, Wait_D = 6'd10, Write_Tenths = 6'd11, Wait_Tenths = 6'd12,
					Space1 = 6'd13, Wait_Space1 = 6'd14, Write_M = 6'd15, Wait_M = 6'd16, Write_P = 6'd17, Wait_P = 6'd18, Write_H = 6'd19, Wait_H = 6'd20, 
					Write_Line2 = 6'd21, Wait_Line2 = 6'd22, Write_Deg1 = 6'd23, Wait_Deg1 = 6'd24, Write_Deg2 = 6'd25, Wait_Deg2 = 6'd26, Write_Deg3 = 6'd27, 
					Wait_Deg3 = 6'd28, Space2 = 6'd29, Wait_Space2 = 6'd30, Write_Dir1 = 6'd31, Wait_Dir1 = 6'd32, Write_Dir2 = 6'd33, Wait_Dir2 = 6'd34, 
					Done_Writing = 6'd35;

	
	reg [3:0] cs0;			//Reg to keep track of initialization FSM
	reg [5:0] cs1;			//Reg to keep track of data FSM
	reg [1:0] cs_Write;		//Reg to keep track of write FSM
	
	reg [7:0] write_data;	//Data written to the LCD during writes
	reg [7:0] init_data;	//Data written to the LCD during initializtion
	reg [7:0] hundreds;		//Hundreds digit of wind speed
	reg [7:0] tens;			//Tens digit of wind speed
	reg [7:0] ones;			//Ones digit of wind speed
	reg [7:0] tenths;		//Tenths digit of wind speed
	reg [7:0] direction_hundreds;	//Hundreds digit of wind direction
	reg [7:0] direction_tens;	//Tens digit of wind direction
	reg [7:0] direction_ones;	//Ones digit of wind direction 
	reg [7:0] dir_char1;		//First character of wind direction
	reg [7:0] dir_char2;		//Second charcter of wind direction
	
	//Enable and RS pins for initialization and writes
	reg LCD_e_write;		
	reg LCD_e_init;			
	reg LCD_rs_write;
	reg LCD_rs_init;
	
	
	reg [5:0] timer;	//Timer used to meet timing requirements during initialization
	reg [1:0] ctr;		//Func set counter
	reg [5:0] delay;	//Func set delay
	
	reg write_start;	//Signal to start a write for the write FSM
	reg write_done;		//Signal that write FSM is finished writing
	
	//Assign LCD pins to write_data if finished initialization, and init_data otherwise
	assign LCD_db = init_done ? write_data : init_data;
	assign LCD_e = init_done ? LCD_e_write : LCD_e_init;
	assign LCD_rs = init_done ? LCD_rs_write : LCD_rs_init;
	
	assign LCD_rw = 1'b0;	//Set RW to write only
	

	always @(*)
		begin
		//Get Hundreds through Tenths digits of wind speed and direction
		hundreds = (wind_data / 11'd1000);
		tens = (wind_data % 11'd1000) / 11'd100;
		ones = (wind_data % 11'd100) / 11'd10;
		tenths = (wind_data % 11'd10);
		direction_hundreds = (wind_direction / 9'd100);
		direction_tens = (wind_direction % 9'd100) / 9'd10;
		direction_ones = (wind_direction % 9'd10);
		
		//Find direction based on wind_direction value, with N at 0 degrees, East at 90 degrees, etc.
		if(wind_direction < 9'd23 || wind_direction >= 9'd338)
			begin
			dir_char1 = "N";
			dir_char2 = " ";
			end
		else if (wind_direction < 68)
			begin
			dir_char1 = "N";
			dir_char2 = "E";
			end
		else if (wind_direction < 113)
			begin
			dir_char1 = "E";
			dir_char2 = " ";
			end
		else if (wind_direction < 158)
			begin
			dir_char1 = "S";
			dir_char2 = "E";
			end
		else if (wind_direction < 203)
			begin
			dir_char1 = "S";
			dir_char2 = " ";
			end
		else if (wind_direction < 248)
			begin
			dir_char1 = "S";
			dir_char2 = "W";
			end
		else if (wind_direction < 293)
			begin
			dir_char1 = "W";
			dir_char2 = " ";
			end
		else
			begin
			dir_char1 = "N";
			dir_char2 = "W";
			end
		end
		
	//Translate digits to ASCII values
	wire [7:0] write_hundreds = hundreds + 8'h30;
	wire [7:0] write_tens = tens + 8'h30;
	wire [7:0] write_ones = ones + 8'h30;
	wire [7:0] write_tenths = tenths + 8'h30;
	wire [7:0] write_direc_hun = direction_hundreds + 8'h30;
	wire [7:0] write_direc_tens = direction_tens + 8'h30;
	wire [7:0] write_direc_ones = direction_ones + 8'h30;
	
	//Initialization FSM
	always @(negedge ar or posedge clk)
		begin
		//Reset values
		if(~ar)
			begin
			init_data = 8'h00;
			timer = 6'd0;
			cs0 = Idle0;
			LCD_rs_init = 1'b0;
			LCD_e_init = 1'b0;
			init_done = 1'b0;
			end
			
		else
			case(cs0)
				//After power on
				Idle0:
					begin
					//After 50ms pass
					if(timer >= 6'd50)
						begin
						cs0 = Func_Set; 		//Move to Func_Set state
						init_done = 1'b0;		//Clear init_done 
						ctr = 2'd0;
						end
					//Still waiting to meet power on timing requirements
					else
						timer = timer + 1'b1;	//Increment timer
					end
					
				//Initialize LCD for 8-bit 2 line display 
				Func_Set:
					begin
					LCD_rs_init = 1'b0;		//Set RS to 0 to indicate instruction
					init_data = 8'h38;		//Code for 8-bit 2 line display
					LCD_e_init = 1'b1;		//Pulse enable pin to write code
					timer  = 6'd0;			//Reset timer
					cs0 = Wait1;
					end
				
				//Set enable pin low to stop writing
				Wait1:
					begin
						LCD_e_init = 1'b0;	
						timer = 6'd0;
						cs0 = CMD_Wait1;
					end
				
				//Wait to meet timing requirements
				CMD_Wait1:
					begin
					//If Func_Set command was only written once
					if(ctr == 0)
						delay = 6'd5; 	//Wait 5ms
					else
						delay = 6'd1;	//Wait 1ms
					
					//Once delay has passed
					if(timer >= delay)
						begin
						timer = 6'd0; 			//Reset timer
						
						//If Func_Set has been called less than 4 times
						if(ctr < 3)
							begin
							ctr = ctr + 1;		//Increment counter
							cs0 = Func_Set;		//Move back to Func_set to ensure mode is properly set
							end
						else
							begin
							cs0 = Display_On;	//Move to Display_On
							end
						end
					else
						timer = timer + 1'b1;	//Increment timer
					end
				
				//Turn on display
				Display_On:
					begin
					init_data = 8'h0C;
					timer = 6'd0;
					LCD_e_init = 1'b1;
					cs0 = Wait2;
					end
					
					
				Wait2:
					begin
						LCD_e_init = 1'b0;
						timer = 6'd0;
						cs0 = CMD_Wait2;
					end
					
				//Wait for Display On timing requirements
				CMD_Wait2:
					begin
					//If 1 ms has passed
					if(timer >= 6'd1)
						cs0 = Clear;			//Move to clear
					else
						timer = timer + 1'b1;	//Increment timer
					end
				
				//Clear the screen
				Clear:
					begin
					init_data = 8'h01;
					timer = 6'd0;
					LCD_e_init = 1'b1;
					cs0 = Wait3;
					end
					
				Wait3:
					begin
						LCD_e_init = 1'b0;
						timer = 6'd0;
						cs0 = CMD_Wait3;
					end
					
				//Wait for Clear timing reqirements
				CMD_Wait3:
					begin
					//If 2 ms has passed
					if(timer >= 6'd2)
						cs0 = Entry_Mode;		//Move to Entry_Mode
					else
						timer = timer + 1'b1;	//Increment timer
					end	
				
				//Set Entry Mode to increment data to the right
				Entry_Mode:
					begin
					init_data = 8'h06;
					timer = 6'd0;
					LCD_e_init = 1'b1;
					cs0 = Wait4;
					end
					
				Wait4:
					begin
						LCD_e_init = 1'b0;
						timer = 6'd0;
						cs0 = CMD_Wait4;
					end
				
				//Wait for Entry Mode timing requirements
				CMD_Wait4:
					begin
					//If 1 ms has passed
					if(timer >= 6'd1)
						begin
						timer = 6'd0;			//Reset timer
						cs0 = Done;				//Move to Done
						end
					else
						timer = timer + 1'b1;	//Increment timer
					end
				
				//Done Initializing
				Done:
					begin
					init_done = 1'b1;	//Set init_done flag to 1 to indicate LCD is initialized
					end
				
				//Default values
				default:
					begin
					init_data = 8'h00;
					LCD_e_init = 1'b0;
					timer  = 6'd0;
					cs0 = Idle0;
					end
			endcase
		end
		
	//Write FSM
	always @(negedge ar or posedge clk)
		begin
		//Reset values
		if(~ar)
			begin
			LCD_e_write = 1'b0;
			write_done = 1'b0;
			cs_Write = Idle_Write;
			end
			
		else
			case(cs_Write)
				Idle_Write:
					begin
					LCD_e_write = 1'b0;
					write_done = 1'b0;
					
					//If there is data to write
					if(write_start)
						begin
						cs_Write = Begin_Write;	//Move to begin write 
						end
					end
				
				Begin_Write:
					begin
					LCD_e_write = 1'b0;
					write_done = 1'b0;
					cs_Write = Write;	//Move to Write
					end
					
				//Pulse enable pin to start writing data
				Write:
					begin
					LCD_e_write = 1'b1;
					write_done = 1'b0;
					cs_Write = Write_Done;	//Move to Write_done
					end
				
				//Clear enable pin to stop writing and indicate write is complete
				Write_Done:
					begin
					LCD_e_write = 1'b0;
					write_done = 1'b1;
					cs_Write = Idle_Write;
					end
					
				//Default values
				default:
					begin
					LCD_e_write = 1'b0;
					write_done = 1'b0;
					cs_Write = Idle_Write;
					end
			endcase
		end
					
	//Data FSM	
	always @(negedge ar or posedge clk)
		begin
		//Reset values
		if(~ar)
			begin
			write_data = 8'h00;
			write_start = 1'b0;
			LCD_rs_write = 1'b0;
			cs1 = Idle1;
			end
		else
			case(cs1)
				Idle1:
					begin
					write_start = 1'b0;
					write_data = 8'h00;
					LCD_rs_write = 1'b0;
					done_writing = 1'b0;
					
					//If LCD is initialized and new data is recieved
					if(new_data && init_done)
						begin
						cs1 = Clear_Screen;	//Move to Clear_Screen
						end
					else
						cs1 = Idle1;
					end
				
				//Clear LCD screen
				Clear_Screen:
					begin
					write_start = 1'b1;
					write_data = 8'h01;
					LCD_rs_write = 1'b0;
					cs1 = Clear_Wait;
					end
				
				//Wait to meet Clear timing requirements
				Clear_Wait:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b0;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Write_Hundreds;	//Move to Write_Hundreds 
						end
					end
					
				//Write Hundreds digit to LCD
				Write_Hundreds:
					begin
					write_start = 1'b1;
					write_data = write_hundreds;
					LCD_rs_write = 1'b1;
					cs1 = Wait_Hund;
					end
				
				//Wait for write to finished
				Wait_Hund:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b1;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Write_Tens;	//Move to Write_Tens;
						end
					end
					
				//Write tens digit to LCD
				Write_Tens:
					begin
					write_start = 1'b1;
					write_data = write_tens;
					LCD_rs_write = 1'b1;
					cs1 = Wait_T;
					end
					
				
				Wait_T:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b1;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Write_Ones;	//Move to Write_Ones 
						end
					end
					
				//Write ones digit to LCD
				Write_Ones:
					begin
					write_start = 1'b1;
					write_data = write_ones;
					LCD_rs_write = 1'b1;
					cs1 = Wait_O;
					end
					
				Wait_O:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b1;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Write_Decimal;	//Move to Write_Decimal
						end
					end
					
				//Write decimal to LCD
				Write_Decimal:
					begin
					write_start = 1'b1;
					write_data = 8'h2E;
					LCD_rs_write = 1'b1;
					cs1 = Wait_D;
					end
					
				Wait_D:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b1;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Write_Tenths;		//Move to Write_Tenths
						end
					end
					
				//Write tenths digit to LCD
				Write_Tenths:
					begin
					write_start = 1'b1;
					write_data = write_tenths;
					LCD_rs_write = 1'b1;
					cs1 = Wait_Tenths;
					end
					
				Wait_Tenths:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b1;
					
					//When finished writing
					if(write_done)
						begin
						cs1 = Space1;		//Move to Done_Writing
						end
					end
				
				//Write space character
				Space1:
					begin
					write_start = 1'b1;
					write_data = 8'h20;
					LCD_rs_write = 1'b1;
					cs1 = Wait_Space1;
					end
				
				Wait_Space1:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_M;
						end
					end
				
				//Write 'm'
				Write_M:
					begin
					write_start = 1'b1;
					write_data = 8'h6D;
					cs1 = Wait_M;
					end
					
				Wait_M:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_P;
						end
					end
					
				//Write 'p'
				Write_P:
					begin
					write_start = 1'b1;
					write_data = 8'h70;
					cs1 = Wait_P;
					end
					
				Wait_P:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_H;
						end
					end
				
				//Write 'h'
				Write_H:
					begin
					write_start = 1'b1;
					write_data = 8'h68;
					cs1 = Wait_H;
					end
					
				Wait_H:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Line2;
						end
					end
				
				//Move to second line on LCD
				Write_Line2:
					begin
					write_start = 1'b1;
					write_data = 8'hC0; 	//Memory address for start of second row.
					LCD_rs_write = 1'b0;	//Set rs to 0 to indicate instruction
					cs1 = Wait_Line2;
					end
					
				Wait_Line2:
					begin
					write_start = 1'b0;
					LCD_rs_write = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Deg1;
						end
					end
				
				//Write first digit of direction
				Write_Deg1:
					begin
					write_start = 1'b1;
					write_data = write_direc_hun;
					LCD_rs_write = 1'b1;
					cs1 = Wait_Deg1;
					end
					
				Wait_Deg1:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Deg2;
						end
					end
					
				//Write second digit of direction
				Write_Deg2:
					begin
					write_start = 1'b1;
					write_data = write_direc_tens;
					cs1 = Wait_Deg2;
					end
					
				Wait_Deg2:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Deg3;
						end
					end
					
				//Write third digit of direction
				Write_Deg3:
					begin
					write_start = 1'b1;
					write_data = write_direc_ones;
					cs1 = Wait_Deg3;
					end
					
				Wait_Deg3:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Space2;
						end
					end
					
				//Write space character
				Space2:
					begin
					write_start = 1'b1;
					write_data = 8'h20;
					cs1 = Wait_Space2;
					end
				Wait_Space2:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Dir1;
						end
					end
					
				//Write first direction character
				Write_Dir1:
					begin
					write_start = 1'b1;
					write_data = dir_char1;
					cs1 = Wait_Dir1;
					end
					
				Wait_Dir1:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Write_Dir2;
						end
					end
					
				//Write second direction character
				Write_Dir2:
					begin
					write_start = 1'b1;
					write_data = dir_char2;
					cs1 = Wait_Dir2;
					end
					
				Wait_Dir2:
					begin
					write_start = 1'b0;
					if(write_done)
						begin
						cs1 = Done_Writing;
						end
					end
					
				Done_Writing:
					begin
					done_writing = 1'b1;	//Indicate write is complete
					cs1 = Idle1;
					end
					
				//Default values
				default:
					begin
					write_start = 1'b0;
					write_data = 8'h00;
					LCD_rs_write = 1'b0;
					done_writing = 1'b1;
					cs1 = Idle1;
					end
			endcase
		end	

endmodule
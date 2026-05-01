#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdbool.h>

//HPS base addresses
#define HW_REGS_BASE 0XFF200000
#define HW_REGS_SPAN 0X00200000
#define WIND_DATA_BASE 0x00010000

#define WIND_DIRECTION_MASK 0x0000FFFF	//Mask for wind direction
#define WIND_SPEED_MASK 0xFFFF0000	//Mask for wind speed


int main(int argc, char** argv)
{
	//Set up HPS
	void *virtual_base;
	int fd;
	volatile uint32_t *wind_data; //Set to base
	
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
	    printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
	
	virtual_base = mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, HW_REGS_BASE);
	if(virtual_base == MAP_FAILED)
	{
		printf("ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	wind_data = (uint32_t *)((uint8_t *)virtual_base + WIND_DATA_BASE);	//Wind data from FPGA
	uint32_t raw_data;	//Raw 32 bit wind data
	uint16_t speed_int;	//Wind speed from fpga
	uint16_t direction_int;	//Wind direction
	double speed;	//Actual wind speed to the nearest decimal
	const char* directions[] = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}; //Cardinal directions
	int char_index = 0;	//Index for directions array
	
	//Write data to file
	FILE* fp = fopen("/media/FAT/Data.txt", "w");
	if(!fp)
	{
		printf("Error opening file");
		munmap(virtual_base, HW_REGS_SPAN);
		close(fd);
		return 1;
	}
	
	while(1)
	{
		raw_data= *wind_data;
		speed_int = (raw_data & WIND_SPEED_MASK) >> 16;	//Shift wind speed to get rid of leading 0's
		direction_int = raw_data & WIND_DIRECTION_MASK;
		speed = speed_int / (double) 10.0;	//Get actual speed.
		char_index = (direction_int + 22) / 45;	//Find the correct index based on direction
		char_index = char_index % 8;	//Round
		char* direction = directions[char_index];
		
		fprintf(fp, "%.1f MPH %u Degrees %s\n", speed, direction_int, direction);	//Write data to fill
		fflush(fp);
		
		usleep(500000);	//Wait half a second between writes
	}
	
	//Disconnect from bridge
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	
	close(fd);
	return 1;
}
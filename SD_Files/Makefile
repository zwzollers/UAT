#
TARGET = sd_write


CFLAGS = -g -Wall
LDFLAGS =  -g -Wall 
CC = gcc

build: $(TARGET)
$(TARGET): sd_write.o 
	$(CC) $(LDFLAGS)   $^ -o $@  
%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@


clean:
	rm -f $(TARGET) *.a *.o *~ 

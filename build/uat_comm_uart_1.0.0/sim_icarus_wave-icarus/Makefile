TARGET           := uat_comm_uart_1.0.0
TOPLEVEL         := -suart_tb
IVERILOG_OPTIONS := -g2012
VVP_OPTIONS := 

all: $(VPI_MODULES) $(TARGET)

$(TARGET):
	iverilog $(TOPLEVEL) -c $(TARGET).scr -o $@ $(IVERILOG_OPTIONS)

run: $(VPI_MODULES) $(TARGET)
	vvp -n -M. -l icarus.log $(patsubst %.vpi,-m%,$(VPI_MODULES)) $(VVP_OPTIONS) $(TARGET) -fst $(EXTRA_OPTIONS)

clean:
	$(RM) $(VPI_MODULES) $(TARGET)

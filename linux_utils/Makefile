CC=arm-linux-gnueabihf-gcc

PROGS=get_clkcnt get_resolution mode_rgb mode_tmds

.PHONY: all clean

all: $(addsuffix .elf, $(PROGS))

$(addsuffix .elf, $(PROGS)): %.elf:%.c
	${CC} $< -o $@

clean:
	rm *.elf

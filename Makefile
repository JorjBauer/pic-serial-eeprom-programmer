SCRIPT = /usr/local/share/gputils/lkr/16f627.lkr
OBJECTS = globals.o i2c.o piceeprom.o delay.o serial.o commands.o

all:main.hex

main.hex:$(OBJECTS) main.o $(SCRIPT)
	gplink --map -c -s $(SCRIPT) -o main.hex $(OBJECTS) main.o

testmain.hex:$(OBJECTS) testmain.o $(SCRIPT)
	gplink --map -c -s $(SCRIPT) -o main.hex $(OBJECTS) testmain.o


%.o:%.asm
	gpasm -c $<

clean:
	rm -f *~ *.o *.lst *.map *.hex *.cod *.cof

install: main.hex
	picp /dev/ttyS0 16f627 -s -wd main.hex

globals.o: globals.asm globals.inc

i2c.o: i2c.asm i2c.inc common.inc delay.inc

piceeprom.o: piceeprom.asm piceeprom.inc common.inc

main.o: main.asm common.inc

delay.o: delay.asm delay.inc common.inc

serial.o: serial.asm serial.inc common.inc

commands.o: commands.asm commands.inc common.inc

SCRIPT = /usr/local/share/gputils/lkr/16f627.lkr
OBJECTS = globals.o seree.o piceeprom.o delay.o serial.o commands.o serbuf.o
#SERIAL = /dev/tty.KeySerial1
SERIAL = `ls /dev/tty.PL2303-*|head -1`

all:main.hex

main.hex:$(OBJECTS) main.o $(SCRIPT)
	gplink --map -c -s $(SCRIPT) -o main.hex $(OBJECTS) main.o

testmain.hex:$(OBJECTS) testmain.o $(SCRIPT)
	gplink --map -c -s $(SCRIPT) -o testmain.hex $(OBJECTS) testmain.o

%.o:%.asm
	gpasm -c $<

clean:
	rm -f *~ *.o *.lst *.map *.hex *.cod *.cof

install: main.hex
	picp $(SERIAL) 16f627 -wc `./perl-flags-generator main.hex` -s -wp main.hex 

installtest: testmain.hex
	picp $(SERIAL) 16f627 -wc `./perl-flags-generator testmain.hex` -s -wp testmain.hex 

globals.o: globals.asm globals.inc processor_def.inc

piceeprom.o: piceeprom.asm piceeprom.inc common.inc processor_def.inc

main.o: main.asm common.inc processor_def.inc

testmain.o: testmain.asm common.inc processor_def.inc

delay.o: delay.asm delay.inc common.inc processor_def.inc

serial.o: serial.asm serial.inc common.inc processor_def.inc

commands.o: commands.asm commands.inc common.inc processor_def.inc

seree.o: seree.asm seree.inc i2c.inc common.inc globals.inc delay.inc processor_def.inc


SCRIPT = /usr/local/share/gputils/lkr/16f627.lkr
OBJECTS = globals.o i2c.o piceeprom.o delay.o serial.o commands.o
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

globals.o: globals.asm globals.inc

i2c.o: i2c.asm i2c.inc common.inc delay.inc

piceeprom.o: piceeprom.asm piceeprom.inc common.inc

main.o: main.asm common.inc

testmain.o: testmain.asm common.inc

delay.o: delay.asm delay.inc common.inc

serial.o: serial.asm serial.inc common.inc

commands.o: commands.asm commands.inc common.inc

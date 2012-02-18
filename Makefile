MCU = t10

TARGET = main

AVRA = avra

AVRDUDE = avrdude
AVRDUDE_FLAGS = -C ./avrdude.conf -c dasaftdi -P /dev/ttyUSB0
AVRDUDE_WRITE_FLASH = -U flash:w:$(TARGET).hex

all: build
	
install:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -p $(MCU) $(AVRDUDE_WRITE_FLASH)

build:
	$(AVRA) $(TARGET).asm

clean:
	rm $(TARGET).hex $(TARGET).eep.hex $(TARGET).obj $(TARGET).cof

CC = clang

TARGET = prog

SRC = main.c 

all: $(TARGET)
	make -C cpu/32bits
	make -C gpu/32bits
	make -C power_sampling


$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)
	make -C cpu/32bits clean
	make -C gpu/32bits clean
	make -C power_sampling clean

CC = clang

TARGET = prog

SRC = main.c 

all: $(TARGET)
	make -C shared_memory
	make -C managed_memory
	make -C private_memory


$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)
	make -C shared_memory clean
	make -C managed_memory clean
	make -C private_memory clean

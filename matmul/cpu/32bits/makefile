CC = clang
CFLAGS = -Wall -O3 -DACCELERATE_NEW_LAPACK -DACCELERATE_LAPACK_ILP64 #Importante para usar nuevas versiones de LAPACK
LDFLAGS = -framework Accelerate

TARGET = matmul 

SRC = main.c ../../utils/Verify.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)

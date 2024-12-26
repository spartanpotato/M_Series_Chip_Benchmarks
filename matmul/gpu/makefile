CC = clang

OUTPUT = matmul

SOURCES = main.m MetalMatmul.m

FRAMEWORKS = -framework Foundation -framework Metal -framework MetalPerformanceShaders

CFLAGS = $(FRAMEWORKS)

all: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $(SOURCES)

clean:
	rm -f $(OUTPUT)

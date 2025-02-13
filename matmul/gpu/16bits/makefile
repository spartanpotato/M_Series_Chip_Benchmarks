# Makefile for compiling matrix_multiplication.swift

# Compiler and flags
SWIFT_COMPILER = xcrun -sdk macosx swiftc
CLANG_COMPILER = xcrun -sdk macosx clang
OUTPUT_NAME = matmul
SOURCE_FILE = main.swift ../../utils/swift_utils.swift
C_SOURCE = ../../utils/verify.c
C_HEADER = ../../utils/BridgingHeader.h  # Path to your bridging header
FRAMEWORKS = -framework Foundation -framework Metal -framework MetalPerformanceShaders

# Temporary object file for C source
C_OBJECT = ../../utils/verify.o

# Target to build the executable
all: $(OUTPUT_NAME)

# Compile the C source file to an object file
$(C_OBJECT): $(C_SOURCE)
	$(CLANG_COMPILER) -c $(C_SOURCE) -o $(C_OBJECT)

# Compile the Swift code, linking the C object file and frameworks
$(OUTPUT_NAME): $(SOURCE_FILE) $(C_OBJECT)
	$(SWIFT_COMPILER) -o $(OUTPUT_NAME) $(SOURCE_FILE) $(C_OBJECT) $(FRAMEWORKS) -import-objc-header $(C_HEADER)

# Clean up generated files
clean:
	rm -f $(OUTPUT_NAME) $(C_OBJECT)

# Phony targets
.PHONY: all clean

# Define variables
SWIFT_SOURCES = main.swift ../utils/swift_utils.swift
METAL_SOURCES = ../game_of_life.metal  # Adjust the relative path
EXECUTABLE = prog

# Compiler and tools
SWIFT_COMPILER = swiftc
METAL_COMPILER = xcrun -sdk macosx metal
METALLIB_COMPILER = xcrun -sdk macosx metallib

# Build paths
BUILD_DIR = build
METAL_LIB = $(BUILD_DIR)/default.metallib

# Targets
all: $(EXECUTABLE)

# Build the executable
$(EXECUTABLE): $(SWIFT_SOURCES) $(METAL_LIB)
	mkdir -p $(BUILD_DIR)
	$(SWIFT_COMPILER) $(SWIFT_SOURCES) -o $(BUILD_DIR)/$(EXECUTABLE) -framework Metal

# Compile the Metal shader
$(METAL_LIB): $(METAL_SOURCES)
	mkdir -p $(BUILD_DIR)
	$(METAL_COMPILER) -c $(METAL_SOURCES) -o $(BUILD_DIR)/GameOfLifeShader.air
	$(METALLIB_COMPILER) $(BUILD_DIR)/GameOfLifeShader.air -o $(METAL_LIB)

# Clean the build directory
clean:
	rm -rf $(BUILD_DIR)

# Run the program
run: $(EXECUTABLE)
	./$(BUILD_DIR)/$(EXECUTABLE)

.PHONY: all clean run

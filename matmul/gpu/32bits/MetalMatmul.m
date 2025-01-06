#include <stdio.h>
#import "MetalMatmul.h"
#include "TimeUtils.h"
#include "../../Verify.h"


@interface MetalMatrixMultiplication ()

// device: Metal device that represents the gpu
// commandQueue: Metal command queue used to send instructions to the gpu
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

@implementation MetalMatrixMultiplication


// Initializer: Initializes the object MetalMatrixMultiplication with the given device
- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        // Instance variables (ivars) are defined for the device and command queue of the object
        _device = device;
        _commandQueue = [device newCommandQueue];
    }
    return self;
}

// Converts a normal matrix into an MPSMatrix object optimized for computations on the GPU
- (MPSMatrix *)createMatrixWithData:(float *)data
                               rows:(int)rows
                               cols:(int)cols
                             buffer:(id<MTLBuffer> *)outBuffer {
    // Calculates size
    size_t dataSize = rows * cols * sizeof(float);

    // Creates private buffer
    id<MTLBuffer> privateBuffer = [self.device newBufferWithLength:dataSize options:MTLResourceStorageModePrivate];

    // Creates a temporary shared buffer to transfer data from the original matrix to the private buffer
    id<MTLBuffer> sharedBuffer = [self.device newBufferWithBytes:data length:dataSize options:MTLResourceStorageModeShared];

    // Creates a command buffer to execute the transfer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    // Creates a blit command to copy the matrix
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder copyFromBuffer:sharedBuffer sourceOffset:0 toBuffer:privateBuffer destinationOffset:0 size:dataSize];
    [blitEncoder endEncoding];

    // Commit 
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    // Aligns rowBytes to 256 for performance improvement
    size_t rowBytes = ((cols * sizeof(float) + 255) / 256) * 256;

    // Creates an MPSMatrixDescriptor (metadata)
    MPSMatrixDescriptor *descriptor = [MPSMatrixDescriptor matrixDescriptorWithRows:rows
                                                                            columns:cols
                                                                           rowBytes:rowBytes
                                                                           dataType:MPSDataTypeFloat32];

    // Pointer
    *outBuffer = privateBuffer;

    // Returns an MPSMatrix with the given information
    return [[MPSMatrix alloc] initWithBuffer:privateBuffer descriptor:descriptor];
}



// Main function
- (void)performMatrixMultiplicationWithMatrixA:(float *)matrixA
                                        rowsA:(int)rowsA
                                        colsA:(int)colsA
                                       matrixB:(float *)matrixB
                                        rowsB:(int)rowsB
                                        colsB:(int)colsB
                                       N:(int)N
                                      result:(float *)resultMatrix
                                      checkResult:(int)checkResult
                                      checkEnergy:(int)checkEnergy {
    if (colsA != rowsB) {
        NSLog(@"Dimensiones de la matriz invalidas para multiplicacion.");
        return;
    }

    // Timer starts
    uint64_t startTime = startTimer();
    
    // Creates MPSMatrix objects
    id<MTLBuffer> bufferA, bufferB, bufferC;
    MPSMatrix *matA = [self createMatrixWithData:matrixA rows:rowsA cols:colsA buffer:&bufferA];
    MPSMatrix *matB = [self createMatrixWithData:matrixB rows:rowsB cols:colsB buffer:&bufferB];
    MPSMatrix *matC = [self createMatrixWithData:resultMatrix rows:rowsA cols:colsB buffer:&bufferC];

    // Timer ends
    double elapsedTime = endTimer(startTime);

    // Output MPSMatrix creation time
    NSLog(@"Tiempo crear MPSMatrix: %f.", elapsedTime);
    
    startTime = startTimer();
    // Set block size (for interleaving, we divide the matrix into sub-blocks)
    int blockSize = 32;  // Choose an appropriate block size for your GPU's architecture
    int numBlocksX = (colsA + blockSize - 1) / blockSize;
    int numBlocksY = (rowsA + blockSize - 1) / blockSize;


    // Loop through blocks and perform matrix multiplication on sub-blocks
    for (int blockX = 0; blockX < numBlocksX; blockX++) {
        for (int blockY = 0; blockY < numBlocksY; blockY++) {

            // Create MPSMatrix multiplication kernel for each block (this is interleaving)
            float alpha = 1.0, beta = 0.0;
            MPSMatrixMultiplication *matMul = [[MPSMatrixMultiplication alloc] initWithDevice:self.device
                                                                              transposeLeft:NO
                                                                             transposeRight:NO
                                                                                resultRows:blockSize
                                                                             resultColumns:blockSize
                                                                         interiorColumns:blockSize
                                                                                    alpha:alpha
                                                                                     beta:beta];
            
            // Create command buffer
            id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

            // Encode the kernel for each block
            [matMul encodeToCommandBuffer:commandBuffer leftMatrix:matA rightMatrix:matB resultMatrix:matC];

            // Commit the command
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
    }
    

    /*
    // Creates a matrix multiplication kernel provided by MPS
    // MPSMatrixMultiplication is the operation alpha * A * B + beta * C.
    // To simulate a matmul calculation, simply set beta to 0
    float alpha = 1.0, beta = 0.0;
    MPSMatrixMultiplication *matMul = [[MPSMatrixMultiplication alloc] initWithDevice:self.device
                                                                          transposeLeft:NO
                                                                         transposeRight:NO
                                                                            resultRows:rowsA
                                                                         resultColumns:colsB
                                                                     interiorColumns:colsA
                                                                                alpha:alpha
                                                                                 beta:beta];
    
    // Creates a command buffer to send commands to the GPU
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    if(checkEnergy == 1){
        // Call a shell command using system() to store energy usage
        int ret = system("sudo powermetrics -i 1 --sampler cpu_power | while read line; do echo \"$(gdate '+%H:%M:%S.%3N'),$line\"; done | grep -E \"CPU Power|GPU Power\" | awk -F': ' '{print $1 \",\" $2}' >> power_metrics_gpu.csv &");

        if (ret == 0) {
            NSLog(@"System call succeeded!");
        } else {
            NSLog(@"System call failed!");
        }
    }

    // Timer starts
    startTime = startTimer();

    // Encodes the kernel into the commandBuffer
    [matMul encodeToCommandBuffer:commandBuffer leftMatrix:matA rightMatrix:matB resultMatrix:matC];
    
    // Commits
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    */

    // Timer ends
    elapsedTime = endTimer(startTime);

    /*if(checkEnergy == 1){
        // Kills command stop measuring power usage
        system("sudo pkill -f 'powermetrics'");
    }*/

    // Calculates FLOPS
    double flops = (2.0 * N * N * N) / (elapsedTime / 1000);
    NSLog(@"FLOPS: %f GFLOPS\n", flops / 1e9);

    // Output time
    NSLog(@"Tiempo computo GPU: %f.", elapsedTime);


    if (checkResult == 1){
        // Creates shared buffer to be used by the cpu
        id<MTLBuffer> stagingBuffer = [self.device newBufferWithLength:(rowsA * colsB * sizeof(float))
                                                           options:MTLResourceStorageModeShared];

        // Copies data from the private buffer to the shared buffer using a blitEncoder
        id<MTLCommandBuffer> blitCommandBuffer = [self.commandQueue commandBuffer];
        id<MTLBlitCommandEncoder> blitEncoder = [blitCommandBuffer blitCommandEncoder];

        // Makes copy
        [blitEncoder copyFromBuffer:bufferC sourceOffset:0 toBuffer:stagingBuffer destinationOffset:0 size:rowsA * colsB * sizeof(float)];
        [blitEncoder endEncoding];

        // Commit
        [blitCommandBuffer commit];
        [blitCommandBuffer waitUntilCompleted];

        // Verifies result
        resultMatrix = (float *)stagingBuffer.contents;
        if (verify_matrix_product(matrixA, matrixB, resultMatrix, N, N, N)) {
            NSLog(@"El calculo fue correcto.");
        }
    }


    // Writes the times and dimensions to a CSV file
    FILE *file = fopen("times.csv", "a");
    if (file == NULL) {
        NSLog(@"Error al abrir o crear el archivo times.csv");
        return;
    }

    // Checks if the file is empty and writes the header if necessary
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0) {
        fprintf(file, "N,ComputationTime(ms),GFLOPS,CPU,GPU\n");
    }

    // Adds the data
    fprintf(file, "%d,%f,%f,0,1\n", N, elapsedTime,flops / 1e9);

    fclose(file);
}


@end

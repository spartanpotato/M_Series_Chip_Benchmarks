#import <Foundation/Foundation.h> // Basic obj c functions
#import <Metal/Metal.h> // Metal
#import <MetalPerformanceShaders/MetalPerformanceShaders.h> // Apple's hardware optimized metal kernels

// Class to perform matmul
@interface MetalMatrixMultiplication : NSObject

// Initializer
- (instancetype)initWithDevice:(id<MTLDevice>)device;

// Function to perform matmul
- (void)performMatrixMultiplicationWithMatrixA:(float *)matrixA
                                      rowsA:(int)rowsA
                                      colsA:(int)colsA
                                     matrixB:(float *)matrixB
                                      rowsB:(int)rowsB
                                      colsB:(int)colsB
                                     N:(int)N
                                    result:(float *)resultMatrix
                                    checkResult:(int)checkResult
                                    checkEnergy:(int)checkEnergy;

@end

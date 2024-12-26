#import <Foundation/Foundation.h> // Funciones basicas de objective c
#import <Metal/Metal.h> // Metal, equivalente de cuda para maquinas apple
#import <MetalPerformanceShaders/MetalPerformanceShaders.h> // Kernels de metal optimizadas para hardware de apple

// Definicion de una clase de objective c para realizar la multiplicacion de matrices
// Hereda de NSObject, clase basica de objective c
@interface MetalMatrixMultiplication : NSObject

// Iicializador
- (instancetype)initWithDevice:(id<MTLDevice>)device;

// Funcion para realizar multplicacion de matrices
- (void)performMatrixMultiplicationWithMatrixA:(float *)matrixA
                                      rowsA:(int)rowsA
                                      colsA:(int)colsA
                                     matrixB:(float *)matrixB
                                      rowsB:(int)rowsB
                                      colsB:(int)colsB
                                    result:(float *)resultMatrix;

@end

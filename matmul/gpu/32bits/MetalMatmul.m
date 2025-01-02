#include <stdio.h>
#import "MetalMatmul.h"
#include "TimeUtils.h"
#include "../../Verify.h"


@interface MetalMatrixMultiplication ()

// Propiedades
// device: Metal device que representa a la gpu
// commandQueue: Metal command queue que se usa para enviar instrucciones a la gpu
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

@implementation MetalMatrixMultiplication

// Inicializador: inicializa el objeto MetalMatrixMultiplication con el device dado
- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        // Se definen ivars (instance variables) para device y command queue del objeto
        _device = device;
        _commandQueue = [device newCommandQueue];
    }
    return self;
}

// Convierte una matriz normal en un objeto MPSMatrix, optimizado para computos en la gpu
- (MPSMatrix *)createMatrixWithData:(float *)data
                               rows:(int)rows
                               cols:(int)cols
                             buffer:(id<MTLBuffer> *)outBuffer {
    // Calcula tamaño 
    size_t dataSize = rows * cols * sizeof(float);

    // Crea private buffer
    id<MTLBuffer> privateBuffer = [self.device newBufferWithLength:dataSize options:MTLResourceStorageModePrivate];

    // Crea shared buffer temporal para pasar data de la matriz original al private buffer
    id<MTLBuffer> sharedBuffer = [self.device newBufferWithBytes:data length:dataSize options:MTLResourceStorageModeShared];

    // Crea command buffer para realizar cambio
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    // Crea blit command para copiar la matriz
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder copyFromBuffer:sharedBuffer sourceOffset:0 toBuffer:privateBuffer destinationOffset:0 size:dataSize];
    [blitEncoder endEncoding];

    // Commit 
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    // Alinea rowBytes a 256 para mejorar performance
    size_t rowBytes = ((cols * sizeof(float) + 255) / 256) * 256;

    // Crea an MPSMatrixDescriptor(metadata)
    MPSMatrixDescriptor *descriptor = [MPSMatrixDescriptor matrixDescriptorWithRows:rows
                                                                            columns:cols
                                                                           rowBytes:rowBytes
                                                                           dataType:MPSDataTypeFloat32];

    // Puntero
    *outBuffer = privateBuffer;

    // Regresa MPSMatrix con informacion dada
    return [[MPSMatrix alloc] initWithBuffer:privateBuffer descriptor:descriptor];
}



// Funcion principal
- (void)performMatrixMultiplicationWithMatrixA:(float *)matrixA
                                        rowsA:(int)rowsA
                                        colsA:(int)colsA
                                       matrixB:(float *)matrixB
                                        rowsB:(int)rowsB
                                        colsB:(int)colsB
                                       N:(int)N
                                      result:(float *)resultMatrix
                                      check:(int)check {
    if (colsA != rowsB) {
        NSLog(@"Dimensiones de la matriz invalidas para multiplicacion.");
        return;
    }

    // Timer starts
    uint64_t startTime = startTimer();
    
    // Crea objetos de las matrices
    id<MTLBuffer> bufferA, bufferB, bufferC;
    MPSMatrix *matA = [self createMatrixWithData:matrixA rows:rowsA cols:colsA buffer:&bufferA];
    MPSMatrix *matB = [self createMatrixWithData:matrixB rows:rowsB cols:colsB buffer:&bufferB];
    MPSMatrix *matC = [self createMatrixWithData:resultMatrix rows:rowsA cols:colsB buffer:&bufferC];

    // Timer ends
    double elapsedTime = endTimer(startTime);

    // Output time
    NSLog(@"Tiempo crear MPSMatrix: %f.", elapsedTime);
    
    // Crea kernel de multiplicacion de matrices dado por MPS
    // MPSMatrixMultiplication es la operacion alpha * A * B + beta * C.
    // Para simular calulo matmul basta con definir beta como 0
    float alpha = 1.0, beta = 0.0;
    MPSMatrixMultiplication *matMul = [[MPSMatrixMultiplication alloc] initWithDevice:self.device
                                                                          transposeLeft:NO
                                                                         transposeRight:NO
                                                                            resultRows:rowsA
                                                                         resultColumns:colsB
                                                                     interiorColumns:colsA
                                                                                alpha:alpha
                                                                                 beta:beta];
    
    // Crea un buffer para comandos a enviar a la gpu
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    // Timer starts
    startTime = startTimer();

    // codifica kernel en el commandBuffer
    [matMul encodeToCommandBuffer:commandBuffer leftMatrix:matA rightMatrix:matB resultMatrix:matC];
    
    // Ejecuta
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    // Timer ends
    elapsedTime = endTimer(startTime);

    // Calcular FLOPS
    double flops = (2.0 * N * N * N) / (elapsedTime / 1000);
    NSLog(@"FLOPS: %f GFLOPS\n", flops / 1e9);

    // Output time
    NSLog(@"Tiempo computo GPU: %f.", elapsedTime);


    if (check == 1){
        // Crea shared buffer que puede ser usado por la cpu
        id<MTLBuffer> stagingBuffer = [self.device newBufferWithLength:(rowsA * colsB * sizeof(float))
                                                           options:MTLResourceStorageModeShared];

        // Copia data de private buffer a shared buffer usando blitEncoder
        id<MTLCommandBuffer> blitCommandBuffer = [self.commandQueue commandBuffer];
        id<MTLBlitCommandEncoder> blitEncoder = [blitCommandBuffer blitCommandEncoder];

        // Hacer la copia
        [blitEncoder copyFromBuffer:bufferC sourceOffset:0 toBuffer:stagingBuffer destinationOffset:0 size:rowsA * colsB * sizeof(float)];
        [blitEncoder endEncoding];

        // Commit
        [blitCommandBuffer commit];
        [blitCommandBuffer waitUntilCompleted];

        // Verificar resultado
        resultMatrix = (float *)stagingBuffer.contents;
        if (verify_matrix_product(matrixA, matrixB, resultMatrix, N, N, N)) {
            NSLog(@"El calculo fue correcto.");
        }
    }


    // Escribe los tiempos y dimensiones en un archivo CSV
    FILE *file = fopen("times.csv", "a");
    if (file == NULL) {
        NSLog(@"Error al abrir o crear el archivo times.csv");
        return;
    }

    // Verifica si el archivo está vacío y escribe el encabezado si es necesario
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0) {
        fprintf(file, "N,ComputationTime(ms),GFLOPS,CPU,GPU\n");
    }

    // Agrega los datos
    fprintf(file, "%d,%f,%f,0,1\n", N, elapsedTime,flops / 1e9);

    fclose(file);
}


@end

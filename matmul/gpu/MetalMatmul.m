#include <stdio.h>
#import "MetalMatmul.h"
#include "TimeUtils.h"


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
- (MPSMatrix *)createMatrixWithData:(float *)data rows:(int)rows cols:(int)cols {
    size_t dataSize = rows * cols * sizeof(float); // Calcula tamaño

    // Define buffer, la opcion MTLResourceStorageModeShared dice que puede ser accedido por cpu o gpu
    id<MTLBuffer> buffer = [self.device newBufferWithBytes:data length:dataSize options:MTLResourceStorageModeShared];
    // Define datos de la matriz con objeto dado por MPS
    MPSMatrixDescriptor *descriptor = [MPSMatrixDescriptor matrixDescriptorWithRows:rows
                                                                            columns:cols
                                                                           rowBytes:cols * sizeof(float)
                                                                            dataType:MPSDataTypeFloat32];
    // Regresa objeto MPSMatrix de la matriz
    return [[MPSMatrix alloc] initWithBuffer:buffer descriptor:descriptor];
}

// Funcion principal
- (void)performMatrixMultiplicationWithMatrixA:(float *)matrixA
                                        rowsA:(int)rowsA
                                        colsA:(int)colsA
                                       matrixB:(float *)matrixB
                                        rowsB:(int)rowsB
                                        colsB:(int)colsB
                                      result:(float *)resultMatrix {
    if (colsA != rowsB) {
        NSLog(@"Dimensiones de la matriz invalidas para multiplicacion.");
        return;
    }

    // Timer starts
    uint64_t startTime = startTimer();
    
    // Crea objetos de las matrices
    MPSMatrix *matA = [self createMatrixWithData:matrixA rows:rowsA cols:colsA];
    MPSMatrix *matB = [self createMatrixWithData:matrixB rows:rowsB cols:colsB];
    MPSMatrix *matC = [self createMatrixWithData:resultMatrix rows:rowsA cols:colsB];

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

    // Output time
    NSLog(@"Tiempo computo GPU: %f.", elapsedTime);
    
    // Copia resultados del objeto MPSMatrix en la matriz normal
    memcpy(resultMatrix, matC.data.contents, rowsA * colsB * sizeof(float));

    // Escribe los tiempos y dimensiones en un archivo CSV
    FILE *file = fopen("times.csv", "a");
    if (file == NULL) {
        NSLog(@"Error al abrir o crear el archivo times.csv");
        return;
    }

    // Verifica si el archivo está vacío y escribe el encabezado si es necesario
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0) {
        fprintf(file, "N,ComputationTime(ms),CPU,GPU\n");
    }

    // Agrega los datos
    fprintf(file, "%d,%f,0,1\n", colsB, elapsedTime);

    fclose(file);
}


@end

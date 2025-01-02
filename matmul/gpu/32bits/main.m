#import <Foundation/Foundation.h>
#import "MetalMatmul.h"
#import "TimeUtils.h"
#import "../../Verify.h"

int main(int argc, char **argv) {
    @autoreleasepool {
        // Crea device(representacion de la gpu en Metal)
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Error al crear device.\n");
            return -1;
        }

        // Toma argumentos
        if (argc < 3) {
            NSLog(@"Se debe ejecutar como ./matmul N check\n");
            return -1;
        }
        
        int N = atoi(argv[1]);
        if (N <= 0) {
            NSLog(@"El tamaño de la matriz debe ser un numero positivo");
            return -1;
        }

        int check = atoi(argv[2]);

        float *A = malloc(N * N * sizeof(float));
        float *B = malloc(N * N * sizeof(float));
        float *C = malloc(N * N * sizeof(float)); 

        if (!A || !B || !C) {
            NSLog(@"Error al guardar memoria");
            return -1;
        }

        // Inicializa matrices con valores al azar
        for (int i = 0; i < N * N; ++i) {
            A[i] = (float)(rand() % 100) / 10.0;
            B[i] = (float)(rand() % 100) / 10.0;
        }
        // Inicializa matriz de resulados con ceros
        memset(C, 0, N * N * sizeof(float)); 

        // Realiza multiplicacion de matrices
        MetalMatrixMultiplication *matrixMultiplication = [[MetalMatrixMultiplication alloc] initWithDevice:device];
        [matrixMultiplication performMatrixMultiplicationWithMatrixA:A 
                                                                rowsA:N 
                                                                colsA:N 
                                                                matrixB:B 
                                                                rowsB:N 
                                                                colsB:N 
                                                                N:N 
                                                                result:C
                                                                check:check];

        // Liberar memoria
        free(A);
        free(B);
        free(C);
    }
    return 0;
}

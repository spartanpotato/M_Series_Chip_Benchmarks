import Metal
import Foundation
import simd

func main() {
    // Get command line arguments
    let argc = CommandLine.argc
    let argv = CommandLine.arguments

    if(argc != 6){
        print("Must be executed as ./prog <grid_size> <stencil_radius> <iterations> <check_instant_energy> <check_energy_over_time>")
        return 
    }

    let n = Int(argv[1])!
    let stencilRadius = Int(argv[2])!
    let iterations = Int(argv[3])!
    let checkInstantEnergy = Int(argv[4])!
    let checkEnergyOverTime = Int(argv[5])!

    // Initialize the grid
    let gridHeight = n
    let gridWidth = n

    let inputBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: gridWidth * gridHeight)
    for i in 0..<gridWidth * gridHeight {
        inputBuffer[i] = UInt8.random(in: 0...1)
    }

    // Get the Metal device
    guard let device = MTLCreateSystemDefaultDevice() else {
        print("Metal is not supported on this device.")
        return
    }

    // Create a command queue
    guard let commandQueue = device.makeCommandQueue() else {
        print("Unable to create command queue.")
        return
    }

    // Load the Metal shader library
    guard let library = device.makeDefaultLibrary(),
          let kernelFunction = library.makeFunction(name: "game_of_life") else {
        print("Unable to load game_of_life kernel function.")
        return
    }

    // Create a compute pipeline state
    let pipelineState: MTLComputePipelineState
    do {
        pipelineState = try device.makeComputePipelineState(function: kernelFunction)
    } catch {
        print("Failed to create compute pipeline state: \(error)")
        return
    }

    // Prepare input and output buffers with storageModeShared
    var currentBuffer = device.makeBuffer(bytes: inputBuffer.baseAddress!,
                                      length: gridWidth * gridHeight * MemoryLayout<UInt8>.stride,
                                      options: .storageModeManaged)
    var outputBuffer = device.makeBuffer(length: gridWidth * gridHeight * MemoryLayout<UInt8>.stride,
                                      options: .storageModeManaged)

    // Grid size buffer
    var gridSize = vector_uint2(UInt32(gridWidth), UInt32(gridHeight))
    let gridSizeBuffer = device.makeBuffer(bytes: &gridSize, length: MemoryLayout<vector_uint2>.stride, options: .storageModeShared)

    // Stencil radius buffer
    var stencilRadiusValue = stencilRadius
    let stencilRadiusBuffer = device.makeBuffer(bytes: &stencilRadiusValue, length: MemoryLayout<Int>.stride, options: .storageModeShared)

    // Starts measuring energy
    if checkInstantEnergy == 1 {
        let ret = startInstantEnergyMeasurement(N: n, storageType: 0)
        if ret == 0 {
            print("Energy measurement started successfully.")
            usleep(1000000);
        } else {
            print("Failed to start energy measurement.")
        }
    }
    if checkEnergyOverTime == 1 {
        let ret = startEnergyOverTimeMeasurement(N: n, storageType: 0)
        if ret == 0 {
            print ("Energy measurement started successfully.")
            usleep(1000000);
        } else {
            print("Failed to start energy measurement.")
        }
    }
    

    let startTime = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Unable to create command buffer or compute encoder.")
            return
        }

        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(gridSizeBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(stencilRadiusBuffer, offset: 0, index: 3)

        // Configure thread execution
        let threadsPerThreadgroup = MTLSize(width: 32, height: 32, depth: 1)
        let threadgroups = MTLSize(
            width: (gridWidth + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (gridHeight + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: 1
        )
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Swap buffers for the next iteration
        if let buffer = currentBuffer {
            (currentBuffer, outputBuffer) = (outputBuffer, buffer)
        } else {
            print("Failed to swap buffers.")
        }
    }

    let elapsed = CFAbsoluteTimeGetCurrent() - startTime

    // Stops measuring energy
    if checkInstantEnergy == 1 || checkEnergyOverTime == 1 {
        stopEnergyMeasurement()
        print("Energy measurement stopped.")
    }

    let elapsed_ = Double(elapsed) / Double(iterations) // Individual elapsed time or each iteration

    let accessPerMs = (Double(estimateMemoryAccesses(N:n, radius: stencilRadius, iterations: iterations)) / Double(elapsed)) / 1000.0 

    print("Time: \(Float(elapsed_)) seconds")
    print("Accesses per ms \(Double(accessPerMs))")

    // Retrieve the output
    if let outputPointer = currentBuffer?.contents().bindMemory(to: UInt8.self, capacity: gridWidth * gridHeight) {
        let flattenedOutput = Array(UnsafeBufferPointer(start: outputPointer, count: gridWidth * gridHeight))
        var output: [[UInt8]] = []
        for rowIndex in 0..<gridHeight {
            let start = rowIndex * gridWidth
            let end = start + gridWidth
            output.append(Array(flattenedOutput[start..<end]))
        }
        if n <= 32 {
            print("Final Output:")
            output.forEach { print($0) }
        }
    } else {
        print("Failed to compute Game of Life.")
    }

    writeTimesToCSV(N: n, radius: stencilRadius, elapsedTime: elapsed_, accessPerMs: accessPerMs, storageType: 0)

}

main()

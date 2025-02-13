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

    // Prepare staging buffer (CPU-accessible)
    guard let stagingBuffer = device.makeBuffer(bytes: inputBuffer.baseAddress!,
                    length: gridWidth * gridHeight, options: .storageModeShared) else {
        print("Error: Failed to create staging buffer.")
        return
    }

    // Prepare private buffer (GPU-accessible) for input and output
    guard var inputBuffer = device.makeBuffer(length: gridWidth * gridHeight, options: .storageModePrivate),
          var outputBuffer = device.makeBuffer(length: gridWidth * gridHeight, options: .storageModePrivate) else {
        print("Error: Failed to create input or output buffers.")
        return
    }

    // Grid size buffer
    var gridSize = vector_uint2(UInt32(gridWidth), UInt32(gridHeight))
    guard let gridSizeBuffer = device.makeBuffer(bytes: &gridSize, length: MemoryLayout<vector_uint2>.stride, options: .storageModePrivate) else {
        print("Error: Failed to create grid size buffer.")
        return
    }

    // Stencil radius buffer
    var stencilRadiusValue = stencilRadius
    guard let stencilRadiusBuffer = device.makeBuffer(bytes: &stencilRadiusValue, length: MemoryLayout<Int>.stride, options: .storageModePrivate) else {
        print("Error: Failed to create stencil radius buffer.")
        return
    }

    // Starts measuring energy
    if checkInstantEnergy == 1 {
        let ret = startInstantEnergyMeasurement(N: n, storageType: 2)
        if ret == 0 {
            print("Energy measurement started successfully.")
            usleep(1000000)
        } else {
            print("Failed to start energy measurement.")
        }
    }
    if checkEnergyOverTime == 1 {
        let ret = startEnergyOverTimeMeasurement(N: n, storageType: 2)
        if ret == 0 {
            print ("Energy measurement started successfully.")
            usleep(1000000)
        } else {
            print("Failed to start energy measurement.")
        }
    }

    let startTime = CFAbsoluteTimeGetCurrent()

    // Copy the initial grid from the staging buffer to the input buffer (GPU)
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
        print("Unable to create command buffer or blit encoder.")
        return
    }

    // Transfer data from staging buffer to input buffer on GPU
    blitEncoder.copy(from: stagingBuffer, sourceOffset: 0, to: inputBuffer, destinationOffset: 0, size: gridWidth * gridHeight)
    blitEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    // Main computation loop
    for _ in 0..<iterations {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Unable to create command buffer or compute encoder.")
            return
        }

        // Set up the compute encoder
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)   // Input buffer
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)  // Output buffer
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

        // Commit the command buffer
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Swap the input and output buffers for the next iteration
        let tempBuffer = inputBuffer
        inputBuffer = outputBuffer
        outputBuffer = tempBuffer
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

    // Copy the final result back to CPU (staging buffer)
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
        print("Unable to create command buffer or blit encoder.")
        return
    }

    // Transfer data from output buffer back to staging buffer on CPU
    blitEncoder.copy(from: outputBuffer, sourceOffset: 0, to: stagingBuffer, destinationOffset: 0, size: gridWidth * gridHeight)
    blitEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    // Retrieve the output
    let outputPointer = stagingBuffer.contents().bindMemory(to: UInt8.self, capacity: gridWidth * gridHeight)
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

    writeTimesToCSV(N: n, radius: stencilRadius, elapsedTime: elapsed_, accessPerMs: accessPerMs, storageType: 2)
}

main()

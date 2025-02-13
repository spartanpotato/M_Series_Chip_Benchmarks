import Foundation
import MetalPerformanceShaders

func gflops(time: Double, size: Int, iterations: Int) -> Double {
    let sizeCubed = pow(Double(size), 3)        // Compute size cubed first
    let operations = Double(iterations) * 2.0  // Compute operations separately
    return (operations * sizeCubed) / ((time) * 1E9)  // Combine the results
}


func writeTimesToCSV(N: Int, elapsedTime: Double, flops: Double, presicion: Int) {
    let filePath = "./outputs/csvs/times.csv"
    
    // Create a URL for the file
    let fileURL = URL(fileURLWithPath: filePath)
    let fileManager = FileManager.default
    
    // Check if the file exists
    if !fileManager.fileExists(atPath: filePath) {
        // Create the file and write the header if necessary
        do {
            try "N,ComputationTime(ms),GFLOPS,CPU,GPU,Presicion(bits)\n".write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating file and writing header: \(error)")
            return
        }
    }
    
    // Append data to the file
    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
        fileHandle.seekToEndOfFile()
        if presicion == 32{
            let data = "\(N),\(elapsedTime * 1000),\(flops),0,1,32\n".data(using: .utf8)!
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            let data = "\(N),\(elapsedTime * 1000),\(flops),0,1,16\n".data(using: .utf8)!
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    } else {
        print("Error opening file for writing")
    }
}


func startInstantEnergyMeasurement(N: Int, presicion: Int) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    if presicion == 32 {
        process.arguments = ["-c", """
            sudo powermetrics -i 1 --sampler gpu_power | grep -E "GPU Power" | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/gpu_instant_32bits.csv &
            """]
    } else {
        process.arguments = ["-c", """
            sudo powermetrics -i 1 --sampler gpu_power | grep -E "GPU Power" | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/gpu_instant_16bits.csv &
            """]
    }

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Error starting CPU energy measurement: \(error)")
        return -1
    }
}


func startEnergyOverTimeMeasurement(N: Int, presicion: Int) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    if presicion == 32{
        process.arguments = ["-c", """
            sudo powermetrics -i 5 --sampler gpu_power | grep -E 'elapsed|GPU Power' | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/gpu_over_time_32bits.csv &
            """]
    } else {
        process.arguments = ["-c", """
            sudo powermetrics -i 5 --sampler gpu_power | grep -E 'elapsed|GPU Power' | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/gpu_over_time_16bits.csv &
            """]
    }

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Error starting CPU energy measurement: \(error)")
        return -1
    }
}


func stopEnergyMeasurement() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    process.arguments = ["-f", "powermetrics"]
    
    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Energy measurement stopped successfully!")
        } else {
            print("Failed to stop energy measurement.")
        }
    } catch {
        print("Error stopping energy measurement: \(error)")
    }
}
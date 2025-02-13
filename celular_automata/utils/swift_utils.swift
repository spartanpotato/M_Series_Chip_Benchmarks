import Foundation
import Darwin

// shared storage == 0
// managed storage == 1
// private storage == 2
func writeTimesToCSV(N: Int, radius: Int, elapsedTime: Double, accessPerMs: Double, storageType: Int) {
    let filePath = "./outputs/csvs/times.csv"
    
    // Create a URL for the file
    let fileURL = URL(fileURLWithPath: filePath)
    let fileManager = FileManager.default
    
    // Check if the file exists
    if !fileManager.fileExists(atPath: filePath) {
        // Create the file and write the header if necessary
        do {
            try "N,StencilRadius,ComputationTime(ms),AccessPerMs,storageType\n".write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating file and writing header: \(error)")
            return
        }
    }
    
    // Determine storage type string
    let storageTypeString: String
    switch storageType {
    case 0:
        storageTypeString = "0" // Shared storage
    case 1:
        storageTypeString = "1" // Managed storage
    case 2:
        storageTypeString = "2" // Private storage
    default:
        print("Invalid storageType: \(storageType)")
        return
    }

    // Append data to the file
    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
        fileHandle.seekToEndOfFile()
        let data = "\(N),\(radius),\(elapsedTime * 1000),\(accessPerMs),\(storageTypeString)\n".data(using: .utf8)!
        fileHandle.write(data)
        fileHandle.closeFile()
    } else {
        print("Error opening file for writing")
    }
}


// shared storage == 0
// managed storage == 1
// private storage == 2
func startInstantEnergyMeasurement(N: Int, storageType: Int) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")

    let fileName: String
    switch storageType {
    case 0:
        fileName = "sharedStorage_instant.csv"
    case 1:
        fileName = "managedStorage_instant.csv"
    case 2:
        fileName = "privateStorage_instant.csv"
    default:
        print("Invalid storageType: \(storageType)")
        return -1
    }

    process.arguments = ["-c", """
        sudo powermetrics -i 1 --sampler gpu_power | grep -E "GPU Power" | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/\(fileName) &
        """]

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Error starting GPU energy measurement: \(error)")
        return -1
    }
}


// shared storage == 0
// managed storage == 1
// private storage == 2
func startEnergyOverTimeMeasurement(N: Int, storageType: Int) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")

    let fileName: String
    switch storageType {
    case 0:
        fileName = "sharedStorage_ot.csv"
    case 1:
        fileName = "managedStorage_ot.csv"
    case 2:
        fileName = "privateStorage_ot.csv"
    default:
        print("Invalid storageType: \(storageType)")
        return -1
    }

    process.arguments = ["-c", """
        sudo powermetrics -i 5 --sampler gpu_power | grep -E 'elapsed|GPU Power' | sed 'N;s/$/\\nN=\(N)/' >> ./outputs/csvs/\(fileName) &
        """]

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Error starting GPU energy measurement: \(error)")
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


// Retrieves cache sizes dynamically
func getCacheSizes() -> (L1: Int, L2: Int, L3: Int) {
    var size = 0
    var sizeL1 = 0
    var sizeL2 = 0
    var sizeL3 = 0
    var len = MemoryLayout<Int>.size

    sysctlbyname("hw.l1dcachesize", &size, &len, nil, 0)
    sizeL1 = size

    sysctlbyname("hw.l2cachesize", &size, &len, nil, 0)
    sizeL2 = size

    sysctlbyname("hw.l3cachesize", &size, &len, nil, 0)
    sizeL3 = size

    return (sizeL1, sizeL2, sizeL3)
}


// Improved function with cache awareness
func estimateMemoryAccesses(N: Int, radius: Int, iterations: Int) -> Int {
    let (L1, L2, L3) = getCacheSizes()
    
    let readsPerCell = (2 * radius + 1) * (2 * radius + 1)
    let writesPerCell = 1
    let accessesPerCell = readsPerCell + writesPerCell

    let totalAccesses = iterations * N * N * accessesPerCell

    // Estimated working set size, assumes uint8_t (1 byte) as the data type
    let workingSetSize = N * N * 1  

    var estimatedAccesses = totalAccesses

    // Adjust based on cache levels
    if workingSetSize <= L1 {
        estimatedAccesses = Int(Double(totalAccesses) * 0.1)  // ~90% cache hits
    } else if workingSetSize <= L2 {
        estimatedAccesses = Int(Double(totalAccesses) * 0.3)  // ~70% cache hits
    } else if workingSetSize <= L3 {
        estimatedAccesses = Int(Double(totalAccesses) * 0.6)  // ~40% cache hits
    } // If larger than L3, assume most accesses hit DRAM

    return estimatedAccesses
}
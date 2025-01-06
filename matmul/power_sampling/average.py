import csv

# File path to the CSV
file_path = 'power_metrics.csv'

# Initialize variables to store the sum and count of CPU and GPU power readings
cpu_total = 0
gpu_total = 0
cpu_count = 0
gpu_count = 0

# Read the CSV file
with open(file_path, newline='') as csvfile:
    reader = csv.reader(csvfile)
    
    for row in reader:
        if len(row) < 3:
            continue
        
        timestamp, device, power = row
        power_value = int(power.replace(' mW', '').strip())  # Clean the power value
        
        if 'CPU' in device:
            cpu_total += power_value
            cpu_count += 1
        elif 'GPU' in device:
            gpu_total += power_value
            gpu_count += 1

# Calculate average values
average_cpu = cpu_total / cpu_count if cpu_count > 0 else 0
average_gpu = gpu_total / gpu_count if gpu_count > 0 else 0

# Print the results
print(f'Average CPU Power: {average_cpu} mW')
print(f'Average GPU Power: {average_gpu} mW')

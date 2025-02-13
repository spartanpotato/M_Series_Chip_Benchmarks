import re
import csv
import argparse
from collections import defaultdict
import matplotlib.pyplot as plt

# Set up argument parsing
parser = argparse.ArgumentParser(description="Process CPU or GPU power and time data.")
parser.add_argument('device', choices=['cpu', 'gpu'], help="Specify 'cpu' or 'gpu' to select the corresponding power file.")
parser.add_argument('precision', choices=['16', '32'], help="Specify '16' or '32' for the precision of the data.")
args = parser.parse_args()

# Check that CPU only uses 32-bit precision
if args.device == 'cpu' and args.precision == '16':
    print("CPU can only use 32-bit precision. Defaulting to 32.")
    args.precision = '32'

# Choose the power file based on the argument
power_file = f'./outputs/csvs/{args.device}_instant_transformed_{args.precision}bits.csv'  # Dynamically select power file (cpu_transformed.csv or gpu_transformed.csv)
time_file = './outputs/csvs/times.csv'  # Times CSV with N, ComputationTime, FLOPS, CPU, GPU, Precision

# Data storage for power and times
power_data = defaultdict(list)
time_data = defaultdict(list)

# Read power data
with open(power_file, 'r') as infile:
    csv_reader = csv.reader(infile)
    next(csv_reader)  # Skip header
    for row in csv_reader:
        power, n = map(int, row)
        power_data[n].append(power)

# Read times data, filtering only CPU or GPU rows and matching precision
with open(time_file, 'r') as infile:
    csv_reader = csv.reader(infile)
    next(csv_reader)  # Skip header
    for row in csv_reader:
        n = int(row[0])
        gflops = float(row[2])
        cpu_flag = row[3].strip()
        gpu_flag = row[4].strip()
        precision = row[5].strip()  # Assuming precision is in the 6th column
        if (args.device == 'cpu' and cpu_flag == '1' and precision == args.precision) or \
           (args.device == 'gpu' and gpu_flag == '1' and precision == args.precision):
            time_data[n].append(gflops)

# Compute average energy and GFLOPS per N
energy_avg = {n: sum(powers) / len(powers) for n, powers in power_data.items()}
gflops_avg = {n: sum(times) / len(times) for n, times in time_data.items()}

# Compute FLOPS per joule and prepare data for plotting
flops_per_joule = {n: gflops_avg[n] / (energy_avg[n] / 1000) for n in energy_avg if n in gflops_avg}

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(flops_per_joule.keys(), flops_per_joule.values(), marker='o')
plt.xlabel('N')
plt.ylabel('GFLOPS per Watt')
plt.title(f'GFLOPS per Watt vs N ({args.device.upper()} {args.precision}-bit)')
plt.grid(True)
plt.tight_layout()
plt.show()

# Save plot to a PNG file
output_file = f'./outputs/graphs/{args.device}_{args.precision}bits_efficency.png'
plt.savefig(output_file, dpi=300)

print(f"Plot generated for GFLOPS per Watt ({args.device.upper()} {args.precision}-bit).")

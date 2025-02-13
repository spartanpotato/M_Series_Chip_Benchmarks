import csv
import argparse
from collections import defaultdict
import matplotlib.pyplot as plt

# Set up argument parsing
parser = argparse.ArgumentParser(description="Process bandwidth per watt data.")
parser.add_argument("storageType", choices=["shared", "managed", "private"], help="Type of memory access used by kernel")
args = parser.parse_args()
storage_map = {"shared": "0", "managed": "1", "private": "2"}  # Map storage types to values
storage_filter = storage_map[args.storageType]

# File paths
power_file = f'./outputs/csvs/{args.storageType}Storage_instant_transformed.csv'
time_file = './outputs/csvs/times.csv'

# Data storage
power_data = defaultdict(list)
bandwidth_data = defaultdict(list)

# Read power data
with open(power_file, 'r') as infile:
    csv_reader = csv.reader(infile)
    next(csv_reader)  # Skip header
    for row in csv_reader:
        power, n = map(float, row)  # Convert power to float in case of decimals
        power_data[int(n)].append(power)

# Read times data, filtering by storage type
with open(time_file, 'r') as infile:
    csv_reader = csv.reader(infile)
    next(csv_reader)  # Skip header
    for row in csv_reader:
        n = int(row[0])
        stencil_radius = int(row[1])  # Might be useful later
        time_ms = float(row[2])
        access_per_ms = float(row[3])
        storage_type = row[4].strip()

        if storage_type == storage_filter:
            bandwidth = (access_per_ms * time_ms) / 1000  # Convert to accesses per second
            bandwidth_data[n].append(bandwidth)

# Compute averages
power_avg = {n: sum(values) / len(values) for n, values in power_data.items()}
bandwidth_avg = {n: sum(values) / len(values) for n, values in bandwidth_data.items()}

# Compute bandwidth per watt
bandwidth_per_watt = {n: bandwidth_avg[n] / (power_avg[n] / 1000) for n in power_avg if n in bandwidth_avg}

# Prepare data for plotting
Ns = sorted(bandwidth_per_watt.keys())
values = [bandwidth_per_watt[n] for n in Ns]

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(Ns, values, marker='o', label="Bandwidth per Watt")
plt.xlabel('N')
plt.ylabel('Bandwidth per Watt (accesses/s per W)')
plt.title(f'Bandwidth per Watt vs N ({args.storageType.capitalize()} Storage)')
plt.grid(True)
plt.legend()
plt.tight_layout()

# Save plot
output_file = f'./outputs/graphs/bandwidth_per_watt_{args.storageType}.png'
plt.savefig(output_file, dpi=300)
plt.show()

print(f"Plot saved to {output_file}.")

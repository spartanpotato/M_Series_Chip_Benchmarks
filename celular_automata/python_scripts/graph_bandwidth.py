import csv
import argparse
import matplotlib.pyplot as plt
from collections import defaultdict

# Set up argument parsing
parser = argparse.ArgumentParser(description="Plot access performance data.")
parser.add_argument("storageType", choices=["shared", "managed", "private"], help="Type of memory access used by kernel")
args = parser.parse_args()
storage_map = {"shared": "0", "managed": "1", "private": "2"}  # Map storage types to values
storage_filter = storage_map[args.storageType]

# Define file path
time_file = './outputs/csvs/times.csv'

# Data storage
access_data = defaultdict(list)

# Read time and access performance data, filtering by storage type
with open(time_file, 'r') as infile:
    csv_reader = csv.reader(infile)
    next(csv_reader)  # Skip header
    for row in csv_reader:
        n = int(row[0])  # N value
        access_per_ms = float(row[3])  # Accesses per millisecond
        storage_type = row[4].strip()  # Storage type as string

        if storage_type == storage_filter:
            # Calculate bandwidth: Accesses per ms (in bytes per ms) * 1000 (convert ms to seconds)
            bandwidth = access_per_ms * 1 / 1000  # Bandwidth in bytes per second
            # Convert bandwidth to GB/s
            bandwidth_gb_s = bandwidth / 10**9  # Convert to GB per second
            access_data[n].append(bandwidth_gb_s)

# Compute averages
access_avg = {n: sum(values) / len(values) for n, values in access_data.items()}

# Prepare data for plotting
Ns = sorted(access_avg.keys())
avg_bandwidth_gb_s = [access_avg[n] for n in Ns]

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(Ns, avg_bandwidth_gb_s, marker='o', label="Avg Bandwidth (GB/s)", color="b")
plt.xlabel('N')
plt.ylabel('Bandwidth (GB/s)')
plt.title(f'Bandwidth vs N ({args.storageType.capitalize()} Storage)')
plt.grid(True)
plt.legend()
plt.tight_layout()

# Save plot
output_file = f'./outputs/graphs/bandwidth_{args.storageType}.png'
plt.savefig(output_file, dpi=300)
plt.show()

print(f"Plot saved to {output_file}.")

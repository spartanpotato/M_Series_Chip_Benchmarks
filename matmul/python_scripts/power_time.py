import matplotlib.pyplot as plt
import pandas as pd
import argparse

# Set up argument parser to accept command-line input
parser = argparse.ArgumentParser(description="Plot Power vs Time for N values.")
parser.add_argument('device', choices=['cpu', 'gpu'], help="Device type: 'cpu' or 'gpu'")
parser.add_argument('precision', choices=['16', '32'], help="Device type: '16' or '32'")
parser.add_argument('max_n', type=int, help="Maximum N value to plot")
args = parser.parse_args()

# Choose the appropriate CSV file based on the device argument
csv_file = './outputs/csvs/cpu_ot_transformed_32bits.csv' if args.device == 'cpu' else f'./outputs/csvs/gpu_ot_transformed_{args.precision}bits.csv'

# Read the CSV data
df = pd.read_csv(csv_file)

# Filter rows where N is less than or equal to the specified max N
df = df[df['N'] <= args.max_n]

# Initialize a list to store cumulative times for each N
df['cumulative_time'] = 0.0
last_cumulative_time = 0.0

# Iterate through the data and calculate cumulative time for each N
for i, row in df.iterrows():
    # Reset cumulative time for each new N
    if i == 0 or df.at[i, 'N'] != df.at[i-1, 'N']:
        last_cumulative_time = 0.0  # Reset for the new N
    # Add the time_elapsed to the last cumulative time
    df.at[i, 'cumulative_time'] = last_cumulative_time
    last_cumulative_time += row['time_elapsed']

# Plot data for each N
plt.figure(figsize=(12, 8))
for n_value in df['N'].unique():
    subset = df[df['N'] == n_value]
    plt.plot(subset['cumulative_time'], subset['power'], label=f'N={n_value}', linestyle='-')

plt.title(f"Power Consumption Over Time for Different N ({args.device.upper()})")
plt.xlabel("Cumulative Time (ms)")
plt.ylabel("Power (mW)")
plt.legend()
plt.grid(True)
plt.tight_layout()

# Save plot to a PNG file
output_file = f'./outputs/graphs/{args.device}_{args.precision}bits_ot_{args.max_n}.png'
plt.savefig(output_file, dpi=300)

# Display the plot
plt.show()

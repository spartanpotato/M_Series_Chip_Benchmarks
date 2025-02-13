import re
import csv
import argparse

# Set up argument parsing
parser = argparse.ArgumentParser(description="Transform CPU power readings with specified precision.")
parser.add_argument("precision", choices=['32'], help="Only 32bits available, argument exist for future implementations")
args = parser.parse_args()
precision = args.precision

# Input and output file paths
input_file = f'./outputs/csvs/cpu_instant_{precision}bits.csv'  # Replace with your actual input file
output_file = f'./outputs/csvs/cpu_instant_transformed_{precision}bits.csv'  # Replace with your desired output file

# Initialize data storage
power_entries = []

# Read the input file
with open(input_file, 'r') as infile:
    lines = infile.readlines()
    current_entries = []

    for line in lines:
        # Match CPU Power lines
        power_match = re.match(r"CPU Power: (\d+) mW", line)
        if power_match:
            power = int(power_match.group(1))
            current_entries.append(power)
        
        # Match N lines and store the last two power readings separately with N
        elif line.startswith("N="):
            n_value = int(line.strip().split('=')[1])
            if len(current_entries) >= 2:
                power_entries.append((current_entries[-2], n_value))  # First power reading
                power_entries.append((current_entries[-1], n_value))  # Second power reading
            current_entries = []  # Reset for the next set

# Write the output to a CSV file
with open(output_file, 'w', newline='') as outfile:
    csv_writer = csv.writer(outfile)
    csv_writer.writerow(["Power (mW)", "N"])
    csv_writer.writerows(power_entries)

print(f"Transformed data written to '{output_file}'")

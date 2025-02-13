import re
import csv

# Read data from the raw input file (replace 'power_metrics.csv' with your actual file path)
with open('./outputs/csvs/cpu_over_time_32bits.csv', 'r') as file:
    data = file.read()

# Regular expressions to match elapsed time, CPU power, and N value
time_pattern = r'\(([\d.]+)ms elapsed\)'
power_pattern = r'CPU Power: (\d+) mW'
n_pattern = r'N=(\d+)'

# Prepare a list to store the processed data
processed_data = []

# Initialize variables to track current N, elapsed times, and power values
current_n = None
elapsed_time = None
power_value = None

# Process each line to extract data
for line in data.splitlines():
    # Match N value
    n_match = re.search(n_pattern, line)
    if n_match:
        # Check if N has changed (i.e., we have encountered a new N)
        new_n = int(n_match.group(1))
        # If we have a valid N, elapsed time, and power value, store the previous data
        if current_n is not None and elapsed_time is not None and power_value is not None:
            processed_data.append([current_n, power_value, elapsed_time])

        # Reset for the new N
        current_n = new_n
    
    # Match elapsed time
    time_match = re.search(time_pattern, line)
    if time_match:
        elapsed_time = float(time_match.group(1))
    
    # Match CPU power value
    power_match = re.search(power_pattern, line)
    if power_match:
        power_value = int(power_match.group(1))

# Store the last entry after the loop ends
if current_n is not None and elapsed_time is not None and power_value is not None:
    processed_data.append([current_n, power_value, elapsed_time])

# Write the processed data to a new CSV file
with open('./outputs/csvs/cpu_ot_transformed_32bits.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['N', 'power', 'time_elapsed'])  # Write headers
    writer.writerows(processed_data)

print("Data preprocessing complete. Output saved to './outputs/csvs/cpu_ot_transformed.csv'.")

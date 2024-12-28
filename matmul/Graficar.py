import pandas as pd
import matplotlib.pyplot as plt

data = pd.read_csv('times.csv')

plt.figure(figsize=(10, 6))

cpu_data = data[data['CPU'] == 1]
plt.plot(cpu_data['N'], cpu_data['ComputationTime(ms)'], label='CPU', color='blue', marker='o')

gpu_data = data[data['GPU'] == 1]
plt.plot(gpu_data['N'], gpu_data['ComputationTime(ms)'], label='GPU', color='red', marker='o')

plt.xlabel('N (Matrix Size)')
plt.ylabel('Computation Time (ms)')
plt.title('Computation Time vs Matrix Size (N) for CPU and GPU')

plt.legend()

plt.grid(True)
plt.show()

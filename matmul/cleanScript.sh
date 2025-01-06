#!/bin/bash
if [ -f "power_metrics_cpu.csv" ]; then
    rm "power_metrics_cpu.csv"
    echo "File power_metrics_cpu.csv has been deleted."
fi

if [ -f "power_metrics_gpu.csv" ]; then
    rm "power_metrics_gpu.csv"
    echo "File power_metrics_gpu.csv has been deleted."
fi

if [ -f "power_sampling/power_metrics.csv" ]; then
    rm "power_sampling/power_metrics.csv"
    echo "File power_metrics.csv has been deleted."
fi

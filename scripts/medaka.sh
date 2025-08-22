#!/usr/bin/env bash

# USAGE: medaka.sh <input.fastq/bam> <assembly> <output_dir> [ threads ]

if [ $# -lt 3 ]; then
    echo "Usage: $0 <input.fastq/bam> <assembly> <output_dir> [threads]"
    exit 1
fi
input_file="$1"
assembly="$2"
output_dir="$3"
threads="${4:-1}"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist."
    exit 1
fi
# Check if assembly file exists
if [ ! -f "$assembly" ]; then
    echo "Error: Assembly file '$assembly' does not exist."
    exit 1
fi

medaka_consensus -i "$input_file" -d "$assembly" -o "$output_dir" -t "$threads" --bacteria -f

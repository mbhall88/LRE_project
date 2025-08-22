#!/usr/bin/env bash

# USAGE: polypolish.sh <assembly.fasta> <reads_1.fq> <reads_2.fq> <outdir> [ threads ]

set -euo pipefail

# Make sure number of arguments is correct
if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
	echo "Usage: $0 <assembly.fasta> <reads_1.fq> <reads_2.fq> <outdir> [ threads ]"
	exit 1
fi

ASSEMBLY="$1"
READS1="$2"
READS2="$3"
OUTDIR="$4"
THREADS="${5:-1}"
mkdir -p "$OUTDIR"
POLYPOLISH_LOG="$OUTDIR/polypolish.log"
POLYPOLISH_OUT="$OUTDIR/polished.fasta"
echo "Indexing assembly with BWA..." >"$POLYPOLISH_LOG"
bwa index "$ASSEMBLY" 2>&1 | tee -a "$POLYPOLISH_LOG"
echo "Aligning 1 reads to assembly with BWA..." >>"$POLYPOLISH_LOG"
R1_ALN="$OUTDIR/reads1_aligned.sam"
bwa mem -t "$THREADS" -a "$ASSEMBLY" "$READS1" >"$R1_ALN" 2>>"$POLYPOLISH_LOG"
echo "Aligning 2 reads to assembly with BWA..." >>"$POLYPOLISH_LOG"
R2_ALN="$OUTDIR/reads2_aligned.sam"
bwa mem -t "$THREADS" -a "$ASSEMBLY" "$READS2" >"$R2_ALN" 2>>"$POLYPOLISH_LOG"
echo "Filtering with Polypolish..." >>"$POLYPOLISH_LOG"
FILTERED_R1="$OUTDIR/filtered_1.sam"
FILTERED_R2="$OUTDIR/filtered_2.sam"
polypolish filter --in1 "$R1_ALN" --in2 "$R2_ALN" --out1 "$FILTERED_R1" --out2 "$FILTERED_R2" &>>"$POLYPOLISH_LOG"
echo "Polishing assembly with Polypolish..." >>"$POLYPOLISH_LOG"
polypolish polish "$ASSEMBLY" "$FILTERED_R1" "$FILTERED_R2" >"$POLYPOLISH_OUT" 2>>"$POLYPOLISH_LOG"
echo "Polypolish complete. Cleaning up temporary files..." >>"$POLYPOLISH_LOG"
# clean up index files from running bwa index on the assembly
rm "$ASSEMBLY".amb "$ASSEMBLY".ann "$ASSEMBLY".bwt "$ASSEMBLY".pac "$ASSEMBLY".sa "$OUTDIR"/*.sam 2>>"$POLYPOLISH_LOG"

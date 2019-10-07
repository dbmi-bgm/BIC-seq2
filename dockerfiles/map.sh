#!/usr/bin/env bash

# maintainer: Tiziana Sanavia (tiziana.sanavia@gmail.com)

# Get the uniquely mapped reads from bam file in parallel runs
# Writes to directory $OUTDIR, file/sample name is defined by $PREFIX when looping over $CHRLIST, which is newline-separated list of chromosomes passed to samtools, e.g., 'chr1'

# Usage:
#   map.sh -b BAM -p PREFIX -c CHRLIST -o OUTDIR

printHelpAndExit() {
    echo "Usage: ${0##*/} -b bam -p prefix -c chrlist -o outdir"
    echo "-b bam : input bam file"
    echo "-p prefix : sample file name"
    echo "-c chrlist : newline-separated list of chromosomes, e.g., 'chr1'"
    echo "-o outdir : output directory"
    exit "$1"
}

while getopts ":b:p:c:o:" opt
do
    case "$opt" in
        b ) bam="$OPTARG" ;;
        p ) prefix="$OPTARG" ;;
        c ) chrlist="$OPTARG" ;;
        o ) outdir="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$bam" ] || [ -z "$prefix" ] || [ -z "$chrlist" ] || [ -z "$outdir" ]
then
    echo "Some or all of the parameters are empty";
    helpFunction
fi

if [ ! -d "$outdir" ]; then
    mkdir -p $outdir
fi

cat $chrlist | parallel --jobs 24 "samtools view -b -h $bam {} | samtools view -q 30 | perl -ane 'print \$F[3], \"\n\";' > $outdir/${prefix}_{}.seq"

tar -czvf $outdir/${prefix}_SeqFilesBICseq2.tar.gz $outdir/${prefix}_*.seq

rm $outdir/${prefix}_*.seq

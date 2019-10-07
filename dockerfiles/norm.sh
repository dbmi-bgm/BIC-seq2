#!/usr/bin/env bash

# maintainer: Tiziana Sanavia (tiziana.sanavia@gmail.com)

# Create normalization configuration file and run BICSeq2 normalization
# Writes to directory $OUTDIR, file/sample name is defined by a $PREFIX derived from the .seq file names provided by the input archive file/directory $SEQ

# Usage:
#   norm.sh -s SEQ -c CHRLIST -a FASTA -i FAIDX -m MAPPABILITY -n NOMCHR -b BINSIZE -p PERC -l RLEN -f FSIZE -o OUTDIR

printHelpAndExit() {
    echo "Usage: ${0##*/} -s seq -c chrlist -f fasta -i faidx -m mappability -n nomchr -b binsize -p perc -l rlen -f fsize -o outdir"
    echo "-s seq : path to seq files. It can be either a folder pointing to the files or a tar.gz archive. The name of seq files must have the following structure '{prefix}_{chromosome}.seq' with all the same 'prefix' name"
    echo "-c chrlist : newline-separated list of chromosomes, e.g., 'chr1'"
    echo "-a fasta : path fasta file"
    echo "-i faidx : path index fasta file"
    echo "-m mappability : path to mappability file. It can be either a folder poiting to the files or a tar.gz archive. The name of mappability files must have the following structure '{chromosome}_{suffix}' with all the same 'suffix' name"
    echo "-n nomchr : add also a prefix (e.g. 'chr') in the mappability files if their names differ from the chromosomes reported in chrlist (e.g. 1,2... in  chrlist but chr1_{suffix}, etc. in the mappability file)"
    echo "-b binsize : size of the bins (default=1000)"
    echo "-p perc : a subsample percentage (default=0.0002)"
    echo "-l rlen : read length (default=100). NOTE: the read length must be smaller than the fragment size"
    echo "-f fsize : fragment size (default=300)" # the mean fragment size is used to have a rasonable window to estimate the GC content
    echo "-o outdir : output directory"
    exit "$1"
}

# Set defaults
perc=0.0002
rlen=100
fsize=300
binsize=1000

while getopts ":s:c:a:i:m:nb:p:l:f:o:" opt
do
    case "$opt" in
        s ) seq="$OPTARG" ;;
        c ) chrlist="$OPTARG" ;;
        a ) fasta="$OPTARG" ;;
        i ) faidx="$OPTARG" ;;
        m ) mappability="$OPTARG" ;;
        n ) nomchr="$OPTARG" ;;
        b ) binsize="$OPTARG" ;;
        p ) perc="$OPTARG" ;;
        l ) rlen="$OPTARG" ;;
        f ) fsize="$OPTARG" ;;
        o ) outdir="$OPTARG" ;;
        ? ) printHelpAndExit ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$seq" ] || [ -z "$chrlist" ] || [ -z "$fasta" ] || [ -z "$faidx" ] || [ -z "$mappability" ] || [ -z "$outdir" ]
then
    echo "Some or all of the parameters are empty";
    printHelpAndExit
fi

if [ ! -d "$outdir" ]; then
    mkdir -p $outdir
fi

mkdir -p $outdir/tmp

if [[ $seq=~\tar.gz$ ]]
then
    tar -xzf $seq > $outdir/tmp
else
    scp $seq > $outdir/tmp
fi

# derive the prefix to be used as file name from the .seq files, assuming that the name structure is '{prefix}_{chromosome}.seq'

flist=(`ls $outdir/tmp/*.seq`)
nompath=${flist[0]/%\.seq}
nomfile=`basename $nompath`
prefix=`echo $nomfile | rev | cut -d"_" -f2-  | rev`

# reference fasta
if [[ $fasta=~\.gz$ ]]
then
    gunzip $fasta > $outdir/tmp/${prefix}_fasta.fa
else
    scp $fasta > $outdir/tmp/${prefix}_fasta.fa
fi

if [[ $faidx=~\.gz$ ]]
then
    gunzip $faidx > $outdir/tmp/${prefix}_faidx.fa.fai
else
    scp $faidx > $outdir/tmp/${prefix}_faidx.fa.fai
fi

mkdir $outdir/tmp/mappability

if [[ $mappability=~\tar.gz$ ]]
then
    tar -xzf $mappability > $outdir/tmp/mappability
else
    scp $mappability > $outdir/tmp/mappability
fi

nompath=(`ls $outdir/tmp/mappability/*`)
nomfile=`basename $nompath`
suffix=`echo $nomfile | cut -d "_" -f2`

# split fasta file
cat $chrlist | parallel --jobs 24 "samtools faidx $output/tmp/${prefix}_fasta.fa {} > $output/tmp/${prefix}_fasta_{}.fa"

# prepare the configuration file

NORM_CONFIG="$output/tmp/${prefix}.norm-config.txt"

printf "chromName\tfaFile\tMapFile\treadPosFile\tbinFileNorm\n" > $NORM_CONFIG
while read CHR; do
    faFile=$output/tmp/${prefix}_fasta_${CHR}.fa
    if [ ! -z "$nomchr" ];then
        MapFile=$outdir/tmp/${nomchr}${CHR}_${suffix}
    else
        MapFile=$outdir/tmp/${CHR}_${suffix}
    fi
    readPosFile=$output/tmp/${prefix}_${CHR}.seq
    binFile=$output/${prefix}_${CHR}.bin
    printf "$CHR\t$faFile\t$MapFile\t$readPosFile\t$binFile\n" >> $NORM_CONFIG
done<$chrlist

perl /usr/local/bin/NBICseq-norm_v0.2.4/NBICseq-norm.pl -p $perc -b $binsize -l $rlen -s $fsize --tmp $output/tmp $NORM_CONFIG $output/${prefix}_bin.prm

rm -rf $outdir/tmp

tar -czvf $outdir/${prefix}_BinFilesBICseq2.tar.gz $outdir/${prefix}*bin*

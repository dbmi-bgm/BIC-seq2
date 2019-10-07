#!/usr/bin/env bash

# maintainer: Tiziana Sanavia (tiziana.sanavia@gmail.com)

# Create segmentation configuration file and detect CNVs based on the normalized data generated by BICseq2-norm
# Writes to directory $OUTDIR, file/sample name is defined by a $PREFIX derived from the .bin file names provided by the input archive file/directory $BIN

# Usage:
#   seg.sh -i BIN -c CHRLIST -l LAMBDA -g CTRLGENOME -o OUTDIR

printHelpAndExit() {
    echo "Usage: ${0##*/} -b bin -c chrlist -f fasta -i faidx -m mappability -b binsize -p perc -l rlen -f fsize -o outdir"
    echo "-b bin : path to bin files. It can be either a folder pointing to the files or a tar.gz archive. The name of bin files must have the following structure '{prefix}_{chromosome}.bin' with all the same 'prefix' name"
    echo "-c chrlist : newline-separated list of chromosomes, e.g., 'chr1'"
    echo "-l lambda : the (positive) penalty used for BICseq2 (default=3)"
    echo "-g ctrlgenome : path to bin files of the control genome (if available). It can be either a folder pointing to the files or a tar.gz archive. The name of bin   files must have the following structure '{ctrlprefix}_{chromosome}.bin' with all the same 'ctrlprefix' name"
    echo "-o outdir : output directory"
    exit "$1"
}

# Set defaults
lambda=3

while getopts ":i:c:l:g:o:" opt
do
    case "$opt" in
        b ) bin="$OPTARG" ;;
        c ) chrlist="$OPTARG" ;;
        l ) lambda="$OPTARG" ;;
        g ) ctrlgenome="$OPTARG" ;;
        o ) outdir="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$bin" ] || [ -z "$chrlist" ] || [ -z "$outdir" ]
then
    echo "Some or all of the parameters are empty";
    helpFunction
fi

if [ ! -d "$outdir" ]; then
    mkdir -p $outdir
fi

mkdir -p $outdir/tmp

if [[ $bin=~\tar.gz$ ]]
then
    tar -xzf $bin > $outdir/tmp
else
    scp $bin > $outdir/tmp
fi

# derive the prefix to be used as file name from the .bin files, assuming that the name structure is '{prefix}_{chromosome}.bin'

flist=(`ls $outdir/tmp/*.bin`)
nompath=${flist[0]/%\.bin}
nomfile=ll=`basename $nompath`
prefix=`echo $nomfile | rev | cut -d"_" -f2-  | rev`

SEG_CONFIG="$output/tmp/${prefix}.seg-config.txt" # configuration file

# manage control genome, create the configuration file and launch segmentation

if [ ! -z "$ctrlgenome" ]
then
    mkdir -p $outdir/tmp/ctrl
    if [[ $ctrlgenome=~\tar.gz$ ]]
    then
        tar -xzf $ctrlgenome > mkdir -p $outdir/tmp/ctrl
    else
        scp $ctrlgenome > mkdir -p $outdir/tmp/ctrl
    fi
    flistctrl=(`ls mkdir -p $outdir/tmp/ctrl/*.bin`)
    nompathctrl=${flistctrl[0]/%\.bin}
    nomfilectrl=`basename $nompathctrl`
    prefixctrl=`echo $nomfilectrl | rev | cut -d"_" -f2-  | rev`
    printf "chromName\tbinFileNorm.Case\tbinFileNorm.Control\n" > $SEG_CONFIG
    while read CHR; do
        binCase=$output/tmp/${prefix}_${CHR}.bin
        binControl=$output/tmp/ctrl/${prefixctrl}_${CHR}.bin
        printf "$CHR\t$binCase\t$binControl\n" >> $SEG_CONFIG
    done<$chrlist
    perl /usr/local/bin/NBICseq-seg_v0.7.2/NBICseq-seg.pl --lambda 3 --bootstrap --control --tmp $output/tmp $SEG_CONFIG $output/${prefix}.BICseq.out
else
    printf "chromName\tbinFileNorm\n" > $SEG_CONFIG
    while read CHR; do
        binFileNorm=$output/tmp/${prefix}_${CHR}.bin
        printf "$CHR\t$binFileNorm\n" >> $SEG_CONFIG
    done<$chrlist
    perl /usr/local/bin/NBICseq-seg_v0.7.2/NBICseq-seg.pl --lambda 3 --bootstrap --tmp $output/tmp $SEG_CONFIG $output/${prefix}.BICseq.out
fi

rm -rf $outdir/tmp

tar -zvf $outdir/${prefix}_SegFilesBICseq2.tar.gz $outdir/${prefix}_*

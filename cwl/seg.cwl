!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
- class: InlineJavascriptRequirement

hints:
- class: DockerRequirement
dockerPull: cgap/cgap:v11

baseCommand: [seg.sh]

inputs:
- id: seq
type: File
inputBinding:
position: 1
prefix: -s
doc: path to seq files

- id: prefix
type: string
inputBinding:
position: 2
prefix: -x
doc: size of the bins

- id: chrlist
type: File
inputBinding:
position: 3
prefix: -c
doc: newline-separated list of chromosomes, e.g., 'chr1'"

- id: reference
type: File
inputBinding:
position: 4
prefix: -r
secondaryFiles:
- .fai
doc: path to the fa file

- id: mappability
type: File
inputBinding:
position: 5
prefix: -m
doc: path to mappability file

- id: nomchr
type: string
default: ''
inputBinding:
position: 6
prefix: -n
doc: prefix (e.g. 'chr') in the name of mappability files derived from chrlist if the names of the chromosomes reported in chrlist differ (e.g. 1,2... in  chrlist but chr1_{suffix}, etc. in the mappability file)"

- id: binsize
type: integer
default: 1000
inputBinding:
position: 7
prefix: -b
doc: size of the bins

- id: perc
type: double
default: 0.0002
inputBinding:
position: 8
prefix: -p
doc: a subsample percentage

- id: rlen
type: integer
default: 100
inputBinding:
position: 9
prefix: -l
doc: read length. NOTE: the read length must be smaller than the fragment size

- id: fsize
type: integer
default: 300
inputBinding:
position: 10
prefix: -f
doc: fragment size. NOTE: the mean fragment size is used to have a rasonable window to estimate the GC content

outputs:
- id: output
type: File
outputBinding:
glob: $(inputs.prefix + "_BinFilesBICseq2.tar.gz")

doc: |
Usage: ${0##*/} -s seq -c chrlist -f fasta -i faidx -m mappability -n nomchr -b binsize -p perc -l rlen -f fsize -o outdir |

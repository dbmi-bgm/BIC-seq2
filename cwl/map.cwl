#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
    - class: InlineJavascriptRequirement

hints:
    - class: DockerRequirement
    dockerPull: cgap/cgap:v11

baseCommand: [map.sh]

inputs:
    - id: bam
      type: File
      inputBinding:
        position: 1
        prefix: -b
      secondaryFiles:
      - .bai
      doc: path to input bam file

    - id: prefix
      type: string
      inputBinding:
          position: 2
          prefix: -p
      doc: sample file name

    - id: chrlist
      type: File
        position: 3
        prefix: -c
      doc: newline-separated list of chromosomes, e.g., 'chr1'"

outputs:
    - id: output
      type: File
      outputBinding:
        glob: $(inputs.prefix + "_SeqFilesBICseq2.tar.gz")

doc: |
Usage: ${0##*/} -b bam -p prefix -c chrlist -o outdir |

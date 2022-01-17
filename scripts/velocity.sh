#!/bin/bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] -i fastq/ -c v3 -s star/ -t 30 ./velocity
Script description here.
Available options:
-i, --input         Path to fastq files
-c, --chemistry     10X chemistry (suported: v1, v2, v3)
-s, --starindex     Path to star index
-t, --threads       Number of threads
-h, --help          Print this help and exit
-v, --verbose       Print script debug info
EOF
  exit
}

die() {
  echo $1
  exit ${2-1}
}

parse_params() {
  INPUT=''
  OUTPUT=''
  CHEMISTRY=''
  STAR_INDEX=''
  THREADS=1
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    -i | --input) 
      INPUT="${2-}"
      shift
      ;;
    -c | --chemistry) 
      CHEMISTRY="${2-}"
      shift
      ;;
    -s | --starindex) 
      STAR_INDEX="${2-}"
      shift
      ;;
    -t | --threads) 
      THREADS="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  [[ -z "${INPUT-}" ]] && die "Missing path to fastq files"
  [[ -z "${STAR_INDEX-}" ]] && die "Missing star index"
  [[ -z "${CHEMISTRY-}" ]] && die "Missing 10X chemistry"
  [[ ${#args[@]} -eq 0 ]] && die "Missing output argument"

  return 0
}

parse_params "$@"

# check params
OUTPUT="${args[0]}"
if [[ ! -d $OUTPUT ]]; then
  echo "Creating output directory $OUTPUT"
  mkdir $OUTPUT
fi

# whitelist
if [ $CHEMISTRY == "v1" ]; then
  WHITELIST="737K-april-2014_rc.txt"
  CB_LEN=14
  UMI_START=15
  UMI_LEN=10
  curl "https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/${WHITELIST}" -o $OUTPUT/$WHITELIST
elif [ $CHEMISTRY == "v2" ]; then
  WHITELIST="737K-august-2016.txt"
  CB_LEN=16
  UMI_START=17
  UMI_LEN=10
  curl "https://github.com/10XGenomics/cellranger/blob/master/lib/python/cellranger/barcodes/${WHITELIST}" -o $OUTPUT/$WHITELIST
elif [ $CHEMISTRY == "v3" ]; then
  WHITELIST="3M-february-2018.txt"
  CB_LEN=16
  UMI_START=17
  UMI_LEN=12
  curl -o - "https://github.com/10XGenomics/cellranger/blob/master/lib/python/cellranger/barcodes/${WHITELIST}.gz" | gunzip > $OUTPUT/$WHITELIST
else
  die "Chemistry $CHEMISTRY not recognized."
fi

# script logic here
echo "Loading FASTQ files from ${INPUT}"

N_READS=`ls $INPUT/*L00*_R{1,2}*.fastq.gz | wc -l | awk '{print $1}'`
if (( $N_READS % 2 != 0 )); then
  die "Reads need to be pair-end!"
fi

echo "Concatenating pair-end reads ..."
cat $INPUT/*L00*_R1*.fastq.gz > $INPUT/read_1.fastq.gz
cat $INPUT/*L00*_R2*.fastq.gz > $INPUT/read_2.fastq.gz

STAR_VERSION=`STAR --version`
echo "Running with STAR version: ${STAR_VERSION}"
echo "RNA-velocity estimation"
STAR \
    --soloType CB_UMI_Simple \
    --genomeDir $STAR_INDEX \
    --readFilesIn $INPUT/read_2.fastq.gz $INPUT/read_1.fastq.gz \
    --soloCBwhitelist $WHITELIST \
    --soloCBlen $CB_LEN \
    --soloUMIstart $UMI_START \
    --soloUMIlen $UMI_LEN \
    --soloFeatures Gene GeneFull SJ Velocyto \
    --runThreadN $THREADS \
    --outfileNamePrefix $OUTPUT/ \
    --readFilesCommand zcat

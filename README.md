# 10X

This repository contains scripts used to 10x pre-processing and RNA-velocity
estimation with StarSolo.

## Requirements

```txt
STAR >=2.7.3a
cellranger
```

If you don't have `STAR` available as a module you can install it with conda:

```console
conda install -c bioconda star=2.7.3a
```

## Velocity estimation with StarSolo

1. Find genome (`fasta`) and annotation (`gtf`) used with `cellranger`. You will
need to rebuild the star index with `STAR >=2.7.3a`. Adjust the number of threads
(`--runThreadN`) to your setup.

```console
mkdir ./star
STAR \
  --runMode genomeGenerate \
  --genomeDir ./star/ \
  --genomeFastaFiles mm38.fa \
  --sjdbGTFfile mm38.gtf \
  --runThreadN 20
```

2. Run helper script for StarSolo

This script will check the necessary requirements and downloads the proper
whitelist based on 10X chemistry. It also adjusted the parameters for StarSolo
accordingly.

- `-i` path to fastq files
- `-c` 10X chemistry used `v1`, `v2` or `v3`
- `-s` path to star index from `step 1`
- `-t` number of threads used
- last parameter is the output path

```console
sh scripts/velocity.sh -i /path/to/fastq -c v3 -s /path/to/star -t 20 ./velocity
```

## Notes

- [reference preparation](https://support.10xgenomics.com/single-cell-gene-expression/software/release-notes/)

### Custom reference preparation

```console
wget http://ftp.ensembl.org/pub/release-98/gtf/mus_musculus/Mus_musculus.GRCm38.98.chr.gtf.gz
wget http://ftp.ensembl.org/pub/release-98/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.chromosome.{1..19,X,Y,MT}.fa.gz
gunzip -c Mus_musculus.GRCm38.dna.chromosome.*.fa.gz > mm38.fa
gunzip *.gt.gz > mm38.gtf
```

## Credits

- Kevin Blighe: [10X chemistry](https://www.biostars.org/p/462568/)
- Kevin Lane: [template setup](https://github.com/klane/databall)

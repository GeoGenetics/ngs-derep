# NGS Derep - a generic module for read dereplication

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.25.0-brightgreen.svg)](https://snakemake.readthedocs.io/en/stable/)

This module implements read derelication steps:
- Read extension:
  - [Tadpole](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/bb-tools-user-guide/tadpole-guide/)
- Dereplication
  - [vsearch](https://github.com/torognes/vsearch)
  - [seqkit rmdup](https://bioinf.shenwei.me/seqkit/usage/#rmdup)
- Select original representative read
  - [seqkit fx2tab](https://bioinf.shenwei.me/seqkit/usage/#fx2tab-tab2fx)
  - [seqkit grep](https://bioinf.shenwei.me/seqkit/usage/#grep)
- Remove low complexity reads
  - [BBDuk](https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbduk-guide/)

And QC steps:
- [MultiQC](https://multiqc.info/) (aggregates QC from several of the tools above)
- [seqkit stats](https://bioinf.shenwei.me/seqkit/usage/#stats)
- [nonpareil](https://github.com/lmrodriguezr/nonpareil)

This module can be used directly, but is designed to be used together with other modules.

## Authors

* Filipe G. Vieira

## Usage

For an example on how to use this module, check repo [aeDNA](https://github.com/GeoGenetics/aeDNA).

# Nextflow pipeline for individual data analysis

The pipeline is designed to provide phenotypic and genotypic information about a participant from corresponding cohort files given participant ID and optionally a gene name.

Currently pipeline produces an rmarkdown html report (named as multiqc) with the following tables:
 1. Participant phenotypic markers
 2. Participant genotype (list of mutations)
 3. Participant summary statistics on number of mutations by type (SNP/InDel) and by tier(I-III). 
 4. [Optional] If a gene name is specified with `--gene` argument the pipeline also produces a list of all mutations (tier I-II) within this gene found in the cohort file.

Example command:
```
nextflow run main.nf --participant_id 229001 --gene SHANK3
```

## Pipeline arguments
The `--participant_id` is only the one required argument.

#### Optional arguments:
- `--gene` - specify gene name (abbreviation) to generate a list of all mutations found in genotypic file for this gene (e.g. SHANK3) [default: `false`, meaning no table will be generated]
- `--phenotypic_file` - path to a file with phenotypic cohort data [default: GEL phenotypic cohort data, fetched from s3 automatically, needs access credentials]
- `--genotypic_file` path to a file with genotypic cohort data [default: GEL tiering data, fetched from s3 automatically, needs access credentials]


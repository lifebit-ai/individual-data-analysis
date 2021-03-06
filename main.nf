#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/individual-data-analysis
========================================================================================
 lifebit-ai/individual-data-analysis Nextflow pipeline for individual data analysis. 
 #### Homepage / Documentation
 https://github.com/lifebit-ai/individual-data-analysis
----------------------------------------------------------------------------------------
*/

Channel
  .fromPath( params.phenotypic_file )
  .ifEmpty { exit 1, "Cannot find any phenotypica data file : ${params.phenotypic_file}" }
  .set { phenotypic_file_ch }
Channel
  .fromPath( params.genotypic_file )
  .ifEmpty { exit 1, "Cannot find genotypic data file : ${params.genotypic_file}" }
  .set { genotypic_file_ch }
/*
#Channel
#  .fromPath( params.dictionary_file )
#  .ifEmpty { exit 1, "Cannot find dictionary file : ${params.dictionary_file}" }
#  .set { dictionary_file_ch }
*/

Channel
  .fromPath( params.rmarkdown )
  .ifEmpty { exit 1, "Cannot find R Markdown file : ${params.rmarkdown}" }
  .set { rmarkdown }


/*--------------------------------------------------
  Filter genotypic file
---------------------------------------------------*/
process Filter_genotypic_file {
  input:
  file(genotypic_file) from genotypic_file_ch

  output:
  file "${genotypic_file.simpleName}_filtered.tsv" into filtered_genotypic_file_ch

  script:
  """
  # Filtering giant file with awk is much fater than with R
  # Conditional decompression of the file before passing it to awk
  file=${genotypic_file} #to pass file name into if condition
  if [[ \${file: -3} == ".gz" ]]
  then \
    gunzip -k -c ${genotypic_file} | awk -v id=${params.participant_id} ' BEGIN {getline;print} \$2==id {print} ' > ${genotypic_file.simpleName}_filtered.tsv
  else \
    awk -v id=${params.participant_id} ' BEGIN {getline;print} \$2==id {print}  ' ${genotypic_file} > ${genotypic_file.simpleName}_filtered.tsv
  fi

  """
}


/*--------------------------------------------------
  Run the R script
---------------------------------------------------*/

process Produce_tables  {
  publishDir "${params.outdir}/out_tables", mode: 'copy'

  input:
  file(phenotypic_file) from phenotypic_file_ch
  file(filtered_genotypic_file) from filtered_genotypic_file_ch
  //file(dictionary_file) from dictionary_file_ch

  output:
  file("*.csv") into (sript_results_ch)
  /* if many different file types:
  file("*.{csv,tsv,png}") into (sript_results_ch) */
  script:
  """
  tactical_solution.R $params.participant_id $params.gene $phenotypic_file $filtered_genotypic_file #\$dictionary_file
  """
}


/*--------------------------------------------------
  Produce R Markdown report
---------------------------------------------------*/

process Prepare_report {
  publishDir params.outdir, mode: 'copy'

  input:
  file(all_tables) from sript_results_ch
  file(rmarkdown) from rmarkdown

  output:
  file('MultiQC') into report

  script:
  """
  # copy the rmarkdown into the pwd
  cp $rmarkdown tmp && mv tmp $rmarkdown
  R -e "rmarkdown::render('${rmarkdown}')"
  mkdir MultiQC && mv ${rmarkdown.baseName}.html MultiQC/multiqc_report.html
  """
}


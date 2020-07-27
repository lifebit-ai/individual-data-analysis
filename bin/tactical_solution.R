#!/usr/bin/env Rscript

library(data.table)
library(tidyverse)

args = commandArgs(trailingOnly=TRUE)
id   <- args[1] 
gene <- args[2]
phenotypic_file_path <- args[3]
genotypic_file_path <- args[4]
#dict_file_path <- args[5]

# FOR DEMO ONLY
#args <- list()
#id <- args[1] <- '229001'
#gene <- args[2] <- F # or for example "SHANK3"
#phenotypic_file_path <- args[3] <- "COVID_data_synthetic.tsv"
#genotypic_file_path <- args[4] <- "tiering_data.tsv"
#dict_file_path <- args[5] <- "dictionary.tsv"




# What is needed
# 

# TODO Filippo
# get variant annotations > Filippo to prepare file variant_annotations.csv > merge by 'Location' column (format: chr:pos)
# create markdown
# create plot (easiest one) for tiered data
# Output table as csv > ideally it should be interactive
# Make different tiering table for comparison
# Pheontypes Age Sex Severe COVID-19 / Mild COVID-19 Alive / deceased  Ethnicity


# Mechanics #
# Input1 > participant_id
### Output
# filter phenotype table by participant_id
# filter genotypic table by participant_id > show only tier 1 and tier 2 if too many entries. Check for pagination
# create a summary table plot > 3 columns (Tier I, Tier II and Tier III) and 2 rows (snp, indel) for participant_id > show numbers
# Input2 > gene name
### Output
# genotypic talble filtered by gene name > all participants > only tier I and tier II   > pagination if possible

# EXTRAS
# be able to input multiple parcipants id



# Functions ####
decode_phenotypes <- function(mydata, dictionary) {
  for (i in colnames(mydata)) {
    # message(i)
    # if (grepl('[[:digit:]]',codings$Coding[  codings$Phenotype.raw.names == paste(i)]) & length(codings$Coding[  codings$Phenotype.raw.names == paste(i)])>1) {
    if (length(codings$Coding[codings$Original_name == paste(i)]) >= 1) {
      if (!is.na(codings$Coding[codings$Original_name == paste(i)])) {
        message(
          paste0(
            'Phenotype ',
            i,
            ' has a coding system. Coding ',
            codings$Coding[codings$Original_name == paste(i)],
            '. Starting to decode.'
          )
        )
        
        # mydata[[i]] <- mydata %>% select(i) %>% mutate(i = as.character(i)) %>%
        #   left_join(., get(paste0('coding', paste(codings$Coding[  codings$Phenotype.raw.names == paste(i)]), '.csv')), # name of the coding file e.g.  coding19.csv
        #           by = setNames("coding", i)) %>% select(meaning) %>% rename(!!paste(i) := meaning)
        
        new_data <-
          mydata %>% select(paste(i)) %>% mutate_all(~ as.character(.)) %>%
          left_join(., get(paste0(
            'coding', paste(codings$Coding[codings$Original_name == paste(i)]), '.csv'
          )), # name of the coding file e.g.  coding19.csv
          by = setNames("coding", i)) #%>% select(meaning) %>% rename(!!paste(i) := meaning)
        
        new_col <- new_data$meaning
        mydata <-
          cbind(mydata %>% select(-i), new_col) %>% rename(!!paste(i) := new_col)
      }
    }
  }
  return(mydata)
}

#################
#Generate tables# 
#################
#dictionary <- read.table('Data_Dictionary_31052020.tsv', h = T, sep = '\t')

##### Table 1
data <- fread(phenotypic_file_path, h=T, sep ='\t') %>%
  filter(participant_id == paste(id))

#Add here convert step if needed

##### Table 2
tier <- read.table(genotypic_file_path, h=T, sep ='\t', quote = "") %>% select(-c(key))

# Output participant table
personal_tier <- tier %>% filter(participant_id == paste(id))
# If table is too big (>150 rows) subset to TIER1 and TIER2 only (if there are any) 
if (nrow(personal_tier) >150 && ("TIER1" %in% personal_tier$tier || "TIER2" %in% personal_tier$tier)) {
  personal_tier <- personal_tier %>% filter(tier %in% c("TIER1", "TIER2") )
}
#Add here convert step if needed

##### Table 3
#Create a new column with mutation type
personal_tier$mutation <- 
  ifelse( test =  (personal_tier$reference %>% as.character() %>% nchar() > 1 |
                     personal_tier$alternate %>% as.character() %>% nchar() > 1 ),
          yes="INDEL",
          no="SNP") %>% as.factor() 


# For nice table of mutation statistics we want to always see both types
# of mutations (even if there are 0 InDels or SNPs), and we want to always see SNPs first row.

#add "INDEL" category if missing
if(! "INDEL" %in% levels(personal_tier$mutation) ) {
  levels(personal_tier$mutation) <- c(levels(personal_tier$mutation), "INDEL")
}

#add "SNP" category if missing
if(! "SNP" %in% levels(personal_tier$mutation) ) {
  levels(personal_tier$mutation) <- c(levels(personal_tier$mutation), "INDEL")
}

#Reorder categories if "SNP" is not first
if(levels(personal_tier$mutation)[1] != "SNP"){
  personal_tier$mutation <- relevel(personal_tier$mutation, "SNP")
}

#Final statistics table
mutation_statistics <- personal_tier %>% select(mutation,tier) %>% table() %>% as.data.frame.matrix()
#as.data.frame.matrix() is a handy function that converts table object in data frame as we need.




##### Table 4
# If there is a gene name spceified, output a table of all mutations 
# for all participants within this gene (only tier 1 and 2) 
if (gene!=F) {
  gene <- gene %>% toupper() #remove if not always gene names are completely uppercase
  gene_mutations <- tier %>% filter(genomic_feature_hgnc==gene, tier %in% c("TIER1","TIER2"))
}



################
#    Output    #
################

write.csv(file = "participant_phenotype.csv", data, row.names = FALSE)
write.csv(file = "participant_genotype.csv", personal_tier, row.names = FALSE)
write.csv(file = "mutation_statistics.csv", mutation_statistics, row.names = FALSE)
if (gene!=F) {write.csv(file = "gene_mutations.csv", gene_mutations, row.names = FALSE)}






##################
# Handy commands #
##################
#Find top 10 participants with most entries:
#table(tier$participant_id) %>% sort(decreasing = T) %>% .[1:10]

#Same but only for participant contained in phenotypic_data file
#tier %>% select(participant_id) %>% filter(participant_id %in% data$participant_id) %>% .$participant_id %>% table() %>% sort(decreasing = T) %>% .[1:10]

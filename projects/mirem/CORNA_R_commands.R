# Corna is another software for predicting miRNA from target genes
# Here are the steps to run CORNA
# http://corna.sourceforge.net/index.html#Introduction

# To install the bioconductor packages:

source("http://www.bioconductor.org/biocLite.R") 
biocLite(c("Biobase", "biomaRt", "GEOquery", "RCurl"))
biocLite("BiocUpgrade")

# To install the other packages:

install.packages("XML")
install.packages("CORNA_1.4.tar.gz", repos = NULL, type="source")



# MOUSE mmu

library(CORNA)
data(CORNA.DATA)
targets <- miRBase2df.fun(file="arch.v5.txt.mus_musculus.zip")

tran2gene <- BioMart2df.fun(biomart="ENSEMBL_MART_ENSEMBL",
                            dataset="mmusculus_gene_ensembl",
                            col.old=c("ensembl_transcript_id",
                                      "ensembl_gene_id"),
                            col.new=c("tran", "gene"))

mir2gene <- corna.map.fun(x=targets,
                          y=tran2gene,
                          m="gene",
                          n="mir")

gsam = read.table("rod_155.txt")[[1]]
res     <- corna.test.fun(x=gsam,
                          y=unique(mir2gene$gene),
                          z=mir2gene,
                          p.adjust="BH")
# list significant microRNAs
res[res$hypergeometric<=0.05,]






# Human hsa

library(CORNA)
data(CORNA.DATA)
# read targets information from mirbase
targets <- miRBase2df.fun(file="arch.v5.txt.homo_sapiens.zip")
# read transcript to gene information from biomaRt
tran2gene     <- BioMart2df.fun(biomart="ENSEMBL_MART_ENSEMBL",
                                dataset="hsapiens_gene_ensembl",
                                col.old=c("ensembl_transcript_id",
                                          "ensembl_gene_id"),
                                col.new=c("tran", "gene"))
# convert microRNA-transcript to microRNA-gene relationship

mir2gene <- corna.map.fun(x=targets,
                          y=tran2gene,
                          m="gene",
                          n="mir")
# perform hypergeometric test on our gsam gene list
gsam = read.table("rod_155.txt")[[1]]
res <- corna.test.fun(x=gsam, y=unique(mir2gene$gene), z=mir2gene, p.adjust="BH")
# list significant microRNAs
res[res$hypergeometric<=0.05,]

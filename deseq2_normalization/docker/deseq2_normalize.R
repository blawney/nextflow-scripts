library(DESeq2)

# args from command line:
args<-commandArgs(TRUE)
RAW_COUNT_MATRIX<-args[1]
OUTPUT_FILE_PATH <- args[2]

# read the raw count matrix, genes as row names:
count_data <- read.table(RAW_COUNT_MATRIX, sep='\t', header = T, row.names = 1, stringsAsFactors = F)

deseq_sf = estimateSizeFactorsForMatrix(count_data)
norm_mtx = sweep(count_data,2,deseq_sf,'/')

write.table(norm_mtx, file=OUTPUT_FILE_PATH, sep='\t', quote=FALSE)
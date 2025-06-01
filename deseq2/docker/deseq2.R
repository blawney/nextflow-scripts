library(DESeq2)

# args from command line:
args<-commandArgs(TRUE)
RAW_COUNT_MATRIX<-args[1]
ANN_PATH <- args[2]
CONDITION_A<-args[3]
CONDITION_B<-args[4]
OUTPUT_DESEQ_FILE <- args[5]
OUTPUT_NC_FILE <- args[6]

# create a string to identify the contrast:
contrast_str = paste0(CONDITION_B, '_vs_', CONDITION_A)

annotations <- read.table(ANN_PATH, sep='\t', row.names=1, header=T)
annotations['orig.names'] <- rownames(annotations)
rownames(annotations) <- make.names(rownames(annotations))
annotations <- annotations[annotations$condition %in% c(CONDITION_A, CONDITION_B), ]

# read the raw count matrix, genes as row names:
count_data <- read.table(RAW_COUNT_MATRIX, sep='\t', header = T, row.names = 1, stringsAsFactors = F)
count_data <- count_data[,rownames(annotations)]

# Need to set the condition as a factor since it's going to be used as a design matrix
annotations$condition <- as.factor(annotations$condition)

# run the actual differential expression:
dds <- DESeqDataSetFromMatrix(countData = count_data,
							  colData = annotations,
							  design = ~condition)


dds <- DESeq(dds)
res <- results(dds, contrast=c("condition", CONDITION_B, CONDITION_A))
original_colnames = colnames(res)
n = length(original_colnames)
baseMeanA = rowMeans(counts(dds,normalized=TRUE)[,dds$condition == CONDITION_A]) 
baseMeanB = rowMeans(counts(dds,normalized=TRUE)[,dds$condition == CONDITION_B]) 
res = cbind(rownames(res), res[,1],baseMeanA, baseMeanB, as.data.frame(res[,2:n])) 
colnames(res) = c('Gene', 'overall_mean', CONDITION_A, CONDITION_B, original_colnames[2:n])
resOrdered <- res[order(res$padj),]

write.table(resOrdered, OUTPUT_DESEQ_FILE, sep='\t', quote=F)

dds <- estimateSizeFactors(dds)
nc <- counts(dds, normalized=TRUE)
write.table(nc, OUTPUT_NC_FILE, sep='\t', quote=F)

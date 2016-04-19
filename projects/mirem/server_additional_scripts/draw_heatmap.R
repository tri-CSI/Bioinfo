q = read.table(file="matrix_output.txt", sep="\t", header=T, row.names=1)
clust <- hclust(dist(q))
mat <- as.matrix(q[clust$order, ])

d <- data.frame(mirem=rep(colnames(mat),each=nrow(mat)), gene = rep(row.names(mat), ncol(mat)), score= as.vector(mat));
d[,1]=gsub("\\.","-",d[,1])
if (ncol(mat) > 50)
{ 
    mirna <- read.table(pipe("cut -f1 results.txt"), header=TRUE)   
    d = subset(d, mirem %in% mirna[,1])
}
write.table(d, file="matrix_cluster.txt", quote = FALSE, row.names = FALSE, sep = "\t")

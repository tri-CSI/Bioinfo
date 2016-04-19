x <- NULL
y <- NULL
z <- NULL
file <- read.table(file="listmap.txt", sep="\t", header=FALSE, skip = 1)
for (i in 1:dim(file)[1]){
	a = as.numeric(as.vector((strsplit(as.character(file$V2[i]),":"))[[1]]))
	b = phyper(a[4], a[1], a[2], a[3], log = FALSE, lower.tail = FALSE)[1]
	x[i] <- toString(file$V1[i])
	y[i] <- toString(file$V2[i])
	z[i] <- toString(b)
}
adj_p_val = p.adjust(as.numeric(z), method = "BH")
xy <- append(as.vector(x),as.vector(y))
xyz <- append(xy,as.vector(z))
final <- append(xyz,as.vector(adj_p_val))
pval_list <-matrix(data=final, nrow=dim(file)[1], ncol=4)
write.table(pval_list, file="listmap_w_pval.txt", sep="\t", quote = FALSE, row.names = FALSE, col.names=FALSE)

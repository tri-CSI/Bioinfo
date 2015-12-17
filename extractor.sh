# Extract variants' ids for comparison
# File names:
# GC113-0h-1-2_sort_rmdup.vcf
# GC117-0h-1-2_sort_rmdup.vcf
# GC117lgG-0h-1-2_sort_rmdup.vcf
# GC119-0h-1-2_sort_rmdup.vcf
# GC127-0h-1-2_sort_rmdup.vcf
# GC84-0h-1-2_sort_rmdup.vcf
# GC113-0h-1-2_S1.vcf
# GC117-0h-1-2_S1.vcf
# GC117lgG-0h-1-2_S1.vcf
# GC119-0h-1-2_S1.vcf
# GC127-0h-1-2_S1.vcf
# GC84-0h-1-2_S1.vcf

LCL="/12TBLVM/Data/MinhTri/KHKAnalysis/localAnalysisVCF/"
BSC="/12TBLVM/Data/MinhTri/KHKAnalysis/BaseSpaceVCF/"
LCL_vcf=("GC113-0h-1-2_sort_rmdup.vcf" "GC117-0h-1-2_sort_rmdup.vcf" "GC117lgG-0h-1-2_sort_rmdup.vcf" "GC119-0h-1-2_sort_rmdup.vcf" "GC127-0h-1-2_sort_rmdup.vcf" "GC84-0h-1-2_sort_rmdup.vcf")
BSC_vcf=("GC113-0h-1-2_S1.vcf" "GC117-0h-1-2_S1.vcf" "GC117lgG-0h-1-2_S1.vcf" "GC119-0h-1-2_S1.vcf" "GC127-0h-1-2_S1.vcf" "GC84-0h-1-2_S1.vcf")
LCL_dir="/12TBLVM/Data/MinhTri/KHKAnalysis/local_extracted/"
BSC_dir="/12TBLVM/Data/MinhTri/KHKAnalysis/khk_extracted/"
txt_names=("GC113" "GC117" "GC117lgG" "GC119" "GC127" "GC84")

for i in {0..5}
do
	ifile=${LCL}${LCL_vcf[$i]}
	ofile=${LCL_dir}${txt_names[$i]}"_local.txt"
	grep -v "#" $ifile | awk '{print $1,$2,$5}' > $ofile
done

for i in {0..5}
do
	ifile=${BSC}${BSC_vcf[$i]}
	ofile=${BSC_dir}${txt_names[$i]}"_basesp.txt"
	grep -v "#" $ifile | awk '{print $1,$2,$5}' > $ofile
done
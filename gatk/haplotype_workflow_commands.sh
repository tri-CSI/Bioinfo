#!/bin/bash

source /home/biotools/tri-scripts/pipeline_general.config 

$GATK -T HaplotypeCaller -R $HG_REF -I sample_1.bam -o sample_1.g.vcf -L $TARGET_REGIONS -ERC GVCF
$GATK -T GenotypeGVCFs -R $HG_REF -V sample_1.g.vcf -V sample_2.g.vcf [....] -o joint.vcf
$GATK -T VariantRecalibrator -R $HG_REF -input joint.vcf -resource:{asfd} -an DP -an QD -an MQRankSum {...} -mode SNP -recalFile raw.SNPs.recal -tranchesFile raw.SNPs.tranches -rscriptFile recal.plots.R
$GATK -T ApplyRecalibration -R $HG_REF -input joint.vcf -mode SNP -recalFile raw.SNPs.recal -tranchesFile raw.SNPs.tranches -o recal.SNPs.vcf -ts_filter_level 99.0
$GATK -T VariantRecalibrator -R $HG_REF -input recal.SNPs.vcf -resource:{asfd} -an DP -an QD -an MQRankSum {...} -mode INDEL -recalFile raw.INDELs.rINDEcoutl -tranchesFile raw.INDELs.tranches -rscriptFile recal.plots.R
$GATK -T ApplyRecalibration -R $HG_REF -input recal.SNPs.vcf -mode INDEL -recalFile raw.INDELs.recal -tranchesFile raw.INDELs.tranches -o recal.INDELs.vcf -ts_filter_level 99.0


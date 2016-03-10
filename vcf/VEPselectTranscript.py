#!/usr/bin/python3
###version 1.0.0
###Author: Feroz Omar
###Modified by Tran Minh Tri
###Organisation: CTRAD, CSI Singapore, NUS

version = '1.0.0' 

#Allele|Gene|Feature|Feature_type|Consequence|cDNA_position|CDS_position|Protein_position|Amino_acids|Codons|Existing_variation|EXON|INTRON|MOTIF_NAME|MOTIF_POS|HIGH_INF_POS|MOTIF_SCORE_CHANGE|DISTANCE|CLIN_SIG|CANONICAL|SYMBOL|SIFT|PolyPhen|GMAF|ENSP|DOMAINS|CCDS|AFR_MAF|AMR_MAF|ASN_MAF|EUR_MAF|PUBMED

#1)	Select annotations with Features only, if present, otherwise pass all annotations.
#2)	Select annotations with CCDS number only, if present, otherwise pass all annotations.
#3)	Select annotations that are canonical only, if present, otherwise pass all annotations.
#4)	Selects the annotations with the most severe consequence (based on Ensembl ranking)
#5)	If more than one annotation is still present, a single annotation is randomly selected
#6)	get rid of CSQ (done)
#7)	Replace "|" with "\t" (done)
#8) Add preferrential genes based on CTRAD designed panel and illumina TruSight Cancer panel
#9) add file to system 
#10) VEP75 compatibility
#11) Longest transcript selection before random annotation
#12) Accomodates full VCF files

#To add:
#1# Coding mutation bias


import random
import sys

try:
	inputFile=sys.argv[1]
	outputFile=sys.argv[2]
	transcript=sys.argv[3]
	proceed = True
	print('\nProgram: VEP Annotation Selector (VAS)\nVersion: {}\n'.format(version))
except:
	print('\nProgram: VEP Annotation Selector (VAS)\nVersion: {}\nVAS selects one annotation per variant from an Ensembl VEP output file\nThe VEP output must be in the vcf format, i.e. --vcf flag in VEF\nusage:\npython3 VEPAnnotationSelector_xx.py <input_vcf_file> <output_vcf_file> <transcript_name>\n\n\n\n'.format(version))
	proceed = False

if proceed == True:
	openfile =open(inputFile)
	savefile =open(outputFile,'w')

	def annoSelnPresent(column,tgt,oldAnnotation):
		featurePresent=False
		newAnnotations=[]
		for annotaion in oldAnnotation:#check if any annotation has a feature
			feature=annotaion.split("|")[column]
			if tgt in feature:
				featurePresent=True
				break

		if featurePresent==True:#check select only those with the feature
			for annotaion in oldAnnotation:
				feature=annotaion.split("|")[column]
				if tgt in feature:
					newAnnotations.append(annotaion)
		else:newAnnotations=list(oldAnnotation)

		return newAnnotations

	featurecol=None
	genecol=None
	CCDScol=None
	CanonicalCol=None
	ConsequenceCol=None
	cDNA_positionCol=None

	randomCallsCount=0

	scount=0
	for line in openfile:
		if line.startswith('#'):
			savefile.write(line)
			if '. Format:' in line:
				DescriptionColumns = line.split('Format: ')[1].strip('">').split('|')
				featurecol=DescriptionColumns.index('Feature')
				genecol=DescriptionColumns.index('SYMBOL')
#				CCDScol=DescriptionColumns.index('CCDS')
#				CanonicalCol=DescriptionColumns.index('CANONICAL')
				ConsequenceCol=DescriptionColumns.index('Consequence')
				cDNA_positionCol=DescriptionColumns.index('cDNA_position')
		else:
			scount+=1
			if scount % 10000==0:print(scount,'variants have been processed')#Print 

			AllINFO=line.strip().split('\t')[7] #Both original VCF info and Annotation
			if ';' in AllINFO:
				lastSemiColon = len(AllINFO) - AllINFO[::-1].index(';') -1
				VCFINFO = AllINFO.split('CSQ=')[0]
				INFO = AllINFO[AllINFO.find('CSQ='):].split(',')#each transcript into a list
			else:
				INFO = AllINFO.split(',')
				VCFINFO = ''

			for annotation in INFO:
				if transcript in annotation:
					chosenAnnotaion = annotation
					break
            
			try:
				temp=chosenAnnotaion.replace("|","\t")
				chosenAnnotaion=temp.replace("CSQ=","")
			except:
				continue
		
			#frontColumns='\t'.join(line.strip().split('\t')[:-1])
			frontColumns=line.strip().split('\t')
			frontColumns[7]=VCFINFO
			frontColumns='\t'.join(frontColumns)
			savefile.write(frontColumns+'\t'+chosenAnnotaion+'\n')

	print('The number of random calls is {}'.format(randomCallsCount))
	print(scount,'variants have been processed\n\n')
	openfile.close()
	savefile.close()

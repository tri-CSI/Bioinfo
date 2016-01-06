#!/opt/rh/python33/root/usr/bin/python3
###version 1.1.9
###Author: Feroz Omar
###Organisation: CTRAD, CSI Singapore, NUS

version = '1.1.9'

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
	proceed = True
	print('\nProgram: VEP Annotation Selector (VAS)\nVersion: {}\n'.format(version))
except:
	print('\nProgram: VEP Annotation Selector (VAS)\nVersion: {}\nVAS selects one annotation per variant from an Ensembl VEP output file\nThe VEP output must be in the vcf format, i.e. --vcf flag in VEF\nusage:\npython3 VEPAnnotationSelector_xx.py <input_vcf_file> <output_vcf_file>\n\n\n\n'.format(version))
	proceed = False

consequences=['transcript_ablation', 'splice_donor_variant', 'splice_acceptor_variant', 'stop_gained', 'frameshift_variant', 'stop_lost', 'initiator_codon_variant', 'inframe_insertion', 'inframe_deletion', 'missense_variant', 'transcript_amplification', 'splice_region_variant', 'incomplete_terminal_codon_variant', 'synonymous_variant', 'stop_retained_variant', 'coding_sequence_variant', 'mature_miRNA_variant', '5_prime_UTR_variant', '3_prime_UTR_variant', 'non_coding_exon_variant', 'nc_transcript_variant', 'intron_variant', 'NMD_transcript_variant', 'upstream_gene_variant', 'downstream_gene_variant', 'TFBS_ablation', 'TFBS_amplification', 'TF_binding_site_variant', 'regulatory_region_variant', 'regulatory_region_ablation', 'regulatory_region_amplification', 'feature_elongation', 'feature_truncation', 'intergenic_variant']

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
				CCDScol=DescriptionColumns.index('CCDS')
				CanonicalCol=DescriptionColumns.index('CANONICAL')
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

			#Start Feature present <--------------------------------
			featurePresent=False
			annotaionsWithFeature=[]
			for annotaion in INFO:#check if any annotation has a feature
				feature=annotaion.split("|")[featurecol]
				if feature != '':featurePresent=True
			if featurePresent==True:
				for annotaion in INFO:
					feature=annotaion.split("|")[featurecol]
					if feature != '':annotaionsWithFeature.append(annotaion)
			else:annotaionsWithFeature=list(INFO)
			#Annotations with features selected if present
			#End Feature present <**************************************

			#Select target gene <--------------------------------
			genesApproved=['ABL1', 'AIP', 'AKT1', 'ALK', 'APC', 'ATM', 'BAP1', 'BLM', 'BMPR1A', 'BRAF', 'BRCA1', 'BRCA2', 'BRIP1', 'BUB1B', 'CDC73', 'CDH1', 'CDK4', 'CDKN1C', 'CDKN2A', 'CEBPA', 'CEP57', 'CHEK2', 'CSF1R', 'CTNNB1', 'CYLD', 'DDB2', 'DICER1', 'DIS3L2', 'EGFR', 'EPCAM', 'ERBB2', 'ERBB4', 'ERCC2', 'ERCC3', 'ERCC4', 'ERCC5', 'EXT1', 'EXT2', 'EZH2', 'FANCA', 'FANCB', 'FANCC', 'FANCD2', 'FANCE', 'FANCF', 'FANCG', 'FANCI', 'FANCL', 'FANCM', 'FBXW7', 'FGFR1', 'FGFR2', 'FGFR3', 'FH', 'FLCN', 'FLT3', 'GATA2', 'GNA11', 'GNAQ', 'GNAS', 'GPC3', 'HNF1A', 'HRAS', 'IDH1', 'IDH2', 'JAK2', 'JAK3', 'KDR', 'KIT', 'KRAS', 'MAX', 'MEN1', 'MET', 'MLH1', 'MPL', 'MSH2', 'MSH6', 'MUTYH', 'NBN', 'NF1', 'NF2', 'NOTCH1', 'NPM1', 'NRAS', 'NSD1', 'PALB2', 'PDGFRA', 'PHOX2B', 'PIK3CA', 'PMS1', 'PMS2', 'PRF1', 'PRKAR1A', 'PTCH1', 'PTEN', 'PTPN11', 'RAD51C', 'RAD51D', 'RB1', 'RECQL4', 'RET', 'RHBDF2', 'RUNX1', 'SBDS', 'SDHAF2', 'SDHB', 'SDHC', 'SDHD', 'SLX4', 'SMAD4', 'SMARCB1', 'SMO', 'SRC', 'STK11', 'SUFU', 'TMEM127', 'TP53', 'TSC1', 'TSC2', 'VHL', 'WRN', 'WT1', 'XPA', 'XPC']
			#start->annotaionsWithFeature
			selectedGene=None
			for annotaionx in annotaionsWithFeature:
				for gene in genesApproved:
					if gene == annotaionx.split("|")[genecol]:
						selectedGene=gene
			#print(selectedGene)
			if selectedGene != None:
				SelectedGenesln=[]
				for annotaionx in annotaionsWithFeature:
					if selectedGene == annotaionx.split("|")[genecol]:
						SelectedGenesln.append(annotaionx)
			else:
				#print("Nothing")
				SelectedGenesln=list(annotaionsWithFeature)
			#End target gene <**************************************

			#Start CCDS <--------------------------------
			CCDSsln=annoSelnPresent(CCDScol,"CCDS",SelectedGenesln)
			#End CCDS <**************************************

			#Start Canonical <--------------------------------
			CanonicalSln=annoSelnPresent(CanonicalCol,"YES",CCDSsln)
			#End Canonical <**************************************

			#Start Most severe <--------------------------------
			annotaionswithMostSevereConsequence=[]
			MostSevereIdentified=False
			MostSevereConsequence=''
			for i in consequences:
				if MostSevereIdentified==False:
					for annotaion in CanonicalSln:
						consequence=annotaion.split("|")[ConsequenceCol]
						if i in consequence:
							MostSevereIdentified=True
							MostSevereConsequence=consequence
			#Most Severe Consequence identified
			for annotaion in CanonicalSln:
				consequence=annotaion.split("|")[ConsequenceCol]
				if MostSevereConsequence in consequence:annotaionswithMostSevereConsequence.append(annotaion)
			#Annotations with most severe consequence chosen
			#End Most severe <**************************************

			#Select longest transcript
			annotaionswithLongestTranscript=[]
			longestTranscript=0
			cDNAExists=False
			for annotaion in annotaionswithMostSevereConsequence:
				cDNA=annotaion.split("|")[cDNA_positionCol]
				if '/' in consequence:
					cDNAExists=True
					thisTranscript=int(cDNA.split('/')[1])
					if thisTranscript > longestTranscript:
						longestTranscript=thisTranscript
			if cDNAExists==True:
				for annotaion in annotaionswithMostSevereConsequence:
					cDNA=annotaion.split("|")[cDNA_positionCol]
					if '/' in consequence:
						thisTranscript=int(cDNA.split('/')[1])
						if thisTranscript == longestTranscript:
							annotaionswithLongestTranscript.append(annotaion)
			else:
				annotaionswithLongestTranscript=list(annotaionswithMostSevereConsequence)
			#End longest transcript <**************************************

			chosenAnnotaion=''
			try:
				if len(annotaionswithLongestTranscript)>1:
					chosenAnnotaion=random.choice(annotaionswithLongestTranscript)
					randomCallsCount+=1
					zz='1'
				else:
					chosenAnnotaion=annotaionswithLongestTranscript[0]
					zz='2'
			except:
				print('Error')
				print(line,'line')
				print(annotaionsWithFeature,'annotaionsWithFeature')
				print(MostSevereConsequence,'MostSevereConsequence')
				print(annotaionswithMostSevereConsequence,'annotaionswithMostSevereConsequence')
				print(zz,chosenAnnotaion,'chosenAnnotaion')
				#x=input()

			temp=chosenAnnotaion.replace("|","\t")
			chosenAnnotaion=temp.replace("CSQ=","")
		
			#frontColumns='\t'.join(line.strip().split('\t')[:-1])
			frontColumns=line.strip().split('\t')
			frontColumns[7]=VCFINFO
			frontColumns='\t'.join(frontColumns)
			savefile.write(frontColumns+'\t'+chosenAnnotaion+'\n')

	print('The number of random calls is {}'.format(randomCallsCount))
	print(scount,'variants have been processed\n\n')
	openfile.close()
	savefile.close()

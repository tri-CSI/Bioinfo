#!/opt/rh/python33/root/usr/bin/python3
###version 1.0.5
###Author: Feroz Omar
###Organisation: CTRAD, CSI Singapore, NUS

version = '1.0.5'


import sys



try:
	filein=sys.argv[1]
	fileout=sys.argv[2]
	proceed = True
	print('\nProgram: VAS Formatter (VF)\nVersion: {}\n\n'.format(version))
except:
	print('\nProgram: VAS Formatter (VF)\nVersion: {}\nVF formats the existing variants and amino acid columns of the VAS output \nusage:\npython3 divideExistingVarsIntoColumnsxx.py <input_txt_file> <output_txt_file>\n\n\n\n'.format(version))
	proceed = False

annoColumn = None
aapositionColumn = None
aaChangeColumn = None


if proceed == True:
	openfile = open(filein)
	savefile = open(fileout,'w')
	scount=1
	for line in openfile:
		if '##' in line:
			savefile.write(line)
			if '. Format:' in line:
				headerRegion=line[line.find('Format: ')+8:line.find('">')]
				colheads = headerRegion.split('|')
				annoColumn = colheads.index('Existing_variation')
				aapositionColumn = colheads.index('Protein_position')
				aaChangeColumn = colheads.index('Amino_acids')
				easmaf = colheads.index('EAS_MAF')
				sasmaf = colheads.index('SAS_MAF')
				allelleCol = colheads.index('Allele')
				headerRegion=headerRegion.replace('|','\t')
		elif '#' in line and '##' not in line:
			HeaderText=line.replace('\n','\t') #'\tDetails\n'
			#HeaderText.replace('\tBR','\t')
			existingCols = HeaderText.count('\t')##+1 or -1?
			annoColumn += existingCols
			aapositionColumn += existingCols
			aaChangeColumn += existingCols
			easmaf += existingCols
			sasmaf += existingCols
			allelleCol += existingCols
			savefile.write(HeaderText+headerRegion+'\tAminoAcidChange\tcosmic\tdbSNP\thgmds\tNRASbase\tothers\tEAS\tSAS\n')
		else:
			if scount % 10000==0:print(scount,'variants have been formatted')

			annos=line.strip('\n').split('\t')[annoColumn].split('&')#

			try:
				aaposition = line.strip('\n').split('\t')[aapositionColumn].split('/')[0]
			except:
				aaposition = ''

			try:
				aaRef = line.strip('\n').split('\t')[aaChangeColumn].split('/')[0]
			except:
				aaRef = ''

			try:
				aaChg = line.strip('\n').split('\t')[aaChangeColumn].split('/')[1]
			except:
				aaChg = ''
			
               #if line.strip('\n').split('\t')[aaChangeColumn] == ''
                   #pass
               #else:
			aminochangeCombined = aaRef+aaposition+aaChg
           

			savefile.write(line.strip('\n')+'\t'+aminochangeCombined) # write data to the file
			cosList=[]
			dbList=[]
			hgmds=[]
			NRASbase=[]
			othersList=[]
			for entry in annos:
				if 'COSM' in entry:cosList.append(entry)
				elif 'rs' in entry:dbList.append(entry)
				elif 'CM' in entry:hgmds.append(entry)
				elif 'NRASbase' in entry:NRASbase.append(entry)
				else: othersList.append(entry)
			savefile.write('\t')

			if len(cosList) > 0:
				for i in range(len(cosList)):
					savefile.write(cosList[i])
					if i !=len(cosList)-1:savefile.write('&')
			savefile.write('\t')

			if len(dbList) > 0:
				for i in range(len(dbList)):
					savefile.write(dbList[i])
					if i !=len(dbList)-1:savefile.write('&')
			savefile.write('\t')

	#hgmds
			if len(hgmds) > 0:
				for i in range(len(hgmds)):
					savefile.write(hgmds[i])
					if i !=len(hgmds)-1:savefile.write('&')
			savefile.write('\t')

	#NRASbase
			if len(NRASbase) > 0:
				for i in range(len(NRASbase)):
					savefile.write(NRASbase[i])
					if i !=len(NRASbase)-1:savefile.write('&')
			savefile.write('\t')


			if len(othersList) > 0:
				for i in range(len(othersList)):
					savefile.write(othersList[i])
					if i !=len(othersList)-1:savefile.write('&')

			##EAS and SAS formatting
			EAS = '0'
			if line.strip('\n').split('\t')[easmaf] != '':
				for entry in line.strip('\n').split('\t')[easmaf].split('&'):
					if entry.split(':')[0] == line.strip('\n').split('\t')[allelleCol]:
						EAS = entry.split(':')[1]

			SAS = '0'
			if  line.strip('\n').split('\t')[sasmaf] != '':
				for entry in line.strip('\n').split('\t')[sasmaf].split('&'):
					if entry.split(':')[0] == line.strip('\n').split('\t')[allelleCol]:
						SAS = entry.split(':')[1]




			savefile.write('\t'+EAS+'\t'+SAS)
			savefile.write('\n')
			scount += 1
	print(scount-1,'variants have been formatted')
	openfile.close()
	savefile.close()

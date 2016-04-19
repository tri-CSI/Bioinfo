import glob

def printb(string):
	return '{0:b}'.format(string).zfill(9)

output_file = "intersectCount.txt"
db_names = ['TargetScan(C)', 'TargetScan(NC)', 'Diana', 'mirDB', 'Miranda(C)', 'Miranda(NC)', 'Pictar', 'PITA', 'RNA22']
db_names.reverse()
count_dict = {}

allFiles = glob.glob('human_intersect_records/*.intersect.txt')
for efile in allFiles:
	num_lines = str(sum(1 for line in open(efile)))
	if num_lines == '0': continue
	bitmask = int(efile.split('.')[1], 2)

	for db_num, db_name in enumerate(db_names):
		db_mask = 1 << db_num
		if not db_mask & bitmask: continue
		count_dict[(db_name,bitmask)] = [num_lines, '0']

allFiles = glob.glob('mouse_intersect_records/*.intersect.txt')
for efile in allFiles:
	num_lines = str(sum(1 for line in open(efile)))
	if num_lines == '0': continue
	bitmask = int(efile.split('.')[1], 2)

	for db_num, db_name in enumerate(db_names):
		db_mask = 1 << db_num
		if not db_mask & bitmask: continue
		if (db_name,bitmask) in count_dict:
			count_dict[(db_name,bitmask)][1] = num_lines
		else:
			count_dict[(db_name,bitmask)] = ['0', num_lines]

with open(output_file, 'w') as report:
	for record in count_dict:
		report.write('\t'.join([record[0], printb(record[1])] + count_dict[record] + ['\n']))

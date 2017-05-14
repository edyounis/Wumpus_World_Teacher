import sys
import csv

args = sys.argv

reader = csv.reader(open(args[1]))
scoresSoFar = []
writeOut = []

copiedlist = []

for row in reader:
    copiedlist.append(row)


for row in copiedlist:
    scoresSoFar.append(row[int(args[2])])

for row in copiedlist:
    flag = ""
    if row[int(args[2])] == "" or row[int(args[2])].lower() == "nan":
        flag+="No valid score."
    if row[int(args[2])] in scoresSoFar:
        flag+="same score as another."
    if row[int(args[2])+1] == "0":
        flag+="Suspicious standard deviaiton."
    newRow = row[:-1]
    newRow.append(flag)
    writeOut.append(newRow)

writer = csv.writer(open(args[1], 'wt'), quoting=csv.QUOTE_NONNUMERIC)

for row in writeOut:
    writer.writerow(row)
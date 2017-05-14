import sys
import csv
import operator

args = sys.argv

reader = csv.reader(open(args[1]))

sortedlist = sorted(reader, key=operator.itemgetter(int(args[2])))

writer = csv.writer(open(args[1], 'wt'), quoting=csv.QUOTE_NONNUMERIC)

if args[2] == "6":
    writer.writerow(["UCINETID", "LASTNAME", "IDNUMBER", "SUBMNAME", "TEAMNAME", "LANGUAGE", "SCORE", "STDEV", "ERROR", "FATALERR", "FLAGS"])
else:
    writer.writerow(["TEAMNAME", "LANGUAGE", "SCORE", "STDEV", "ERROR", "FATALERR"])

for row in sortedlist:
    writer.writerow(row)
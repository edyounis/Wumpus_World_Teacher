import re
import os
import csv
import json
import subprocess
import configparser

from datetime import timedelta
from datetime import datetime

import urllib3
import certifi
import dateutil.parser

############################################################################
#
# 1. Tournament Configuration
#
############################################################################

# Read Config File
config = configparser.ConfigParser()
config.read('tournament.ini')

# HTTPS client setup
https = urllib3.PoolManager(cert_reqs='CERT_REQUIRED', ca_certs=certifi.where())

# Output Map
output = {}

# Get Assignment Info
url = "https://canvas.eee.uci.edu/api/v1/courses/"+ config['CANVAS']['courseID'] + "/assignments/" + config['CANVAS']['assignmentID']
response = https.request('GET', url, headers={'Authorization': 'Bearer ' + config['CANVAS']['accesstoken']})
AssignmentInfo = json.loads(response.data)

# Due Date
dueDate = dateutil.parser.parse(AssignmentInfo["due_at"])

############################################################################
#
# 2. Organize Canvas Submissions
#
# Adds team_name (from canvas submit) as key in 'output'
# Adds submit_name, submit_time, submit_download to 'output'
#
############################################################################

# Raw JSON Data
submit_data = []

# Get Raw Data
i = 1;
while True:
	url = "https://canvas.eee.uci.edu/api/v1/courses/"	\
			+ config['CANVAS']['courseID']				\
			+ "/assignments/"							\
			+ config['CANVAS']['assignmentID']			\
			+ "/submissions?per_page=100"				\
			+ "&page="									\
			+ str(i)

	response = https.request('GET', url, headers={'Authorization': 'Bearer ' + config['CANVAS']['accesstoken']})

	if len(response.data) <= 2:
		break

	submit_data += json.loads(response.data)
	i += 1;

# Valid Submissions
valid_submits = []

# Parse Raw Data
for j in submit_data:
	if "attachments" not in j.keys():
		continue
	for attachment in j["attachments"]:
		if attachment["content-type"] == "application/zip" or attachment["content-type"] == "application/x-zip-compressed":
			valid_submits.append( attachment )

# Parse Valid Submits
for submit in valid_submits:
	submit_name = submit["display_name"].split('_')[-1].split('.')[0]
	team_name   = submit_name.split('-')[0]
	submit_time = dateutil.parser.parse(submit["modified_at"])

	if team_name not in output.keys() or output[team_name][1] - submit_time < timedelta(0):
		output[team_name] = [submit_name, submit_time, submit["url"]]

############################################################################
#
# 3. Organize Student Data
#
############################################################################

# Raw JSON Data
student_data = []

# Parsed Student Names
student_names = set()

# Get Raw Data
i = 1;
while True:
	url = "https://canvas.eee.uci.edu/api/v1/courses/"	\
			+ config['CANVAS']['courseID']				\
			+ "/users?per_page=100" 					\
			+ "&page="									\
			+ str(i)

	response = https.request('GET', url, headers={'Authorization': 'Bearer ' + config['CANVAS']['accesstoken']})

	if len(response.data) <= 2:
		break

	student_data += json.loads(response.data)
	i += 1;

for j in student_data:
	student_names.add(j["name"])

############################################################################
#
# 4. Download Team Data
#
############################################################################

# Raw JSON Data
group_data = []
user_data  = []

# Parsed Valid Teams
valid_teams = {}

# Error Sets
teamNames         = set()
validTeamNames    = set()
repeatedTeamNames = set()
emptyTeamNames    = set()
Names             = set()
repeatedNames     = set()
allStudentNames   = set()

# Team Name Regex
teamNamePattern = re.compile(config['SETTINGS']['team_name_format'])

# Get Raw Data
i = 1;
while True:
	url = "https://canvas.eee.uci.edu/api/v1/"	\
			+ "group_categories/"				\
			+ config['CANVAS']['group_cat_id']	\
			+ "/groups?per_page=100"			\
			+ "&page="							\
			+ str(i)

	response = https.request('GET', url, headers={'Authorization': 'Bearer ' + config['CANVAS']['accesstoken']})

	if len(response.data) <= 2:
		break

	group_data += json.loads(response.data)
	i += 1;

# Parse teams
for j in group_data:
	if j["name"] in teamNames:
		repeatedTeamNames.add(j["name"])

	teamNames.add(j["name"])

	if teamNamePattern.match(j["name"]):
		validTeamNames.add(j["name"])
		valid_teams[j["id"]] = [j["name"]]

	if j["members_count"] == 0:
		emptyTeamNames.add(j["name"])

# Gather Member Data
for i in valid_teams.keys():
	url = "https://canvas.eee.uci.edu/api/v1/groups/"	\
			+ str(i)									\
			+ "/users?per_page=100"						\

	response = https.request('GET', url, headers={'Authorization': 'Bearer ' + config['CANVAS']['accesstoken']})
	user_data = json.loads(response.data)
	for j in user_data:
		valid_teams[i].append(j["sortable_name"])
		valid_teams[i].append(j["login_id"])

		if j["name"] in Names:
			repeatedNames.add(j["name"])
		Names.add(j["name"])


print ( "Invalid Team Names" )
print ( teamNames - validTeamNames )

print ( "Repeated Team Names" )
print ( repeatedTeamNames )

print ( "Empty Team Names" )
print ( emptyTeamNames )

print ( "Students in multiple Groups" )
print ( repeatedNames )

print ( "Students not in any Groups" )
print ( student_names - Names )

############################################################################
#
# 5. Link Team Data
#
############################################################################

# Error Sets
teams_with_no_submit = set()
teams_with_submit    = set()

for team in valid_teams.values():

	# If team_name has no submission
	if team[0] not in output.keys():
		output[team[0]] = ["", datetime(1,1,1), ""]
		teams_with_no_submit.add(team[0])
	else:
		teams_with_submit.add(team[0])

	for i in range(1, len(team)):
		output[team[0]].append(team[i])

	if len(team) == 3:
		output[team[0]].append("")
		output[team[0]].append("")

for k,v in output.items():
	if len(v) == 3:
		output[k].append("")
		output[k].append("")
		output[k].append("")
		output[k].append("")

print ( "Teams with no Submission" )
print ( teams_with_no_submit )

############################################################################
#
# 6. Download Submissions
#
############################################################################

for k,v in output.items():
		if v[2] == "":
			continue

		response = https.request('GET', v[2])

		if not os.path.exists("files/" + k):
			os.makedirs("files/" + k)

		f = open("files/" + k + "/" + k + ".zip", 'wb')
		f.write(response.data)
		f.close()

############################################################################
#
# 7. Extract Files
#
############################################################################

for k,v in output.items():
	zipfile_name = "files/" + k + "/" + k + ".zip"
	target_dir   = "files/" + k + "/" + "extracted_files"

	if not os.path.exists(zipfile_name):
		output[k].append("")
		output[k].append("No")
		output[k].append("No")
		output[k].append("")
		output[k].append("")
		continue

	if not os.path.exists(target_dir):
		os.makedirs(target_dir)

	bashCommand   = "unzip -nqq " + zipfile_name + " -d " + target_dir
	process       = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
	out, err = process.communicate()

############################################################################
#
# 8. Generate Worlds
#
############################################################################

bashCommand   = "bash" + " " \
					+ config['INTERNALS']['world_generator_script']	+ " "	\
					+ config['INTERNALS']['world_generator']		+ " "	\
					+ config['INTERNALS']['world_folder']

process       = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
out, err = process.communicate()

############################################################################
#
# 9. Run Submissions
#
############################################################################

for k,v in output.items():
	target_dir    = "files/" + k

	if not os.path.exists(target_dir + "/" + k + ".zip"):
		continue

	bashCommand   = "bash run_agent.sh"								+ " "	\
						+ target_dir								+ " "	\
						+ config['INTERNALS']['cpp_shell_src']		+ " "	\
						+ config['INTERNALS']['java_shell_src']		+ " "	\
						+ config['INTERNALS']['python_shell_src']	+ " "	\
						+ config['INTERNALS']['world_folder']		+ " "	\
						+ config['INTERNALS']['timeout_script']		+ " "	\
						+ config['SETTINGS']['timeout_seconds']

	process  = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	out, err = process.communicate()

	results = "".join(map(chr, out)).split('\n')

	# Write Language
	if "FATALERR" in results[0]:
		output[k].append("")
	else:
		output[k].append(results[0])

	# Write Report
	if len(results) < 2 or "ERROR" in results[1]:
		output[k].append("No")
	else:
		output[k].append("Yes")

	# Write Compiled
	if len(results) < 3 or "FATALERR" in results[2]:
		output[k].append("No")
	else:
		output[k].append("Yes")

	# Write Time-out
	if "Terminated" in "".join(map(chr, err)):
		output[k].append("Yes")
	else:
		output[k].append("No")

	# Write Score
	if len(results) < 5 or "FATALERR" in results[3]:
		output[k].append("")
		output[k].append("")
	else:
		output[k].append(results[3].split(" ")[-1])
		output[k].append(results[4].split(" ")[-1])

############################################################################
#
# 10. Grade Submission
#
############################################################################

# Error Sets
on_time_teams = set()
late_teams = set()

max_grade = int(config['SCORING']['execution_worth']) + int(config['SCORING']['compile_worth']) + int(config['SCORING']['report_worth'])

for k,v in output.items():
	if (v[0] == ""):
		continue;

	report     = v[-5] == "Yes"
	compiled   = v[-4] == "Yes"
	Executes   = v[-2].replace('.', '').isdigit()
	submitTime = v[1]
	grade = 0;

	if report:
		grade += int(config['SCORING']['report_worth'])

	if compiled:
		grade += int(config['SCORING']['compile_worth'])

	if Executes:
		score = float(v[-2])
		score = (score - int(config['SCORING']['score_requirement'])) * grade_loss_per_score
		if score >= 0:
			grade += int(config['SCORING']['execution_worth'])
		elif score > -int(config['SCORING']['execution_worth']):
			grade += int(config['SCORING']['execution_worth']) + int(score)

	time_dif = dueDate - submitTime

	if time_dif.total_seconds() > -59:
		on_time_teams.add(k)
	else:
		late_teams.add(k)

		grade += max_grade*0.1*float(time_dif.days)

	if grade < 0:
		grade = 0

	output[k].append(grade)

############################################################################
#
# 11. Print Scoreboard
#
############################################################################

with open('output.csv', 'w') as f:
	w = csv.writer(f)
	for i in output.keys():
		w.writerow([str(i)] + output[i])

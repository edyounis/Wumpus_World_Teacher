#!/bin/bash

write_Results_To_Meta()
{
	meta_folder=$1
	
	echo "WRITING RESULTS TO META FILES..."
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -e $ind_meta_folder/Results.txt ]
		then
			while IFS= read -r line
			do
				if [[ $line == "SCORE"* ]]
				then
					echo "SCORE   : ${line#*: }" >> $ind_meta_folder/META
				fi
				if [[ $line == "STDEV"* ]]
				then
					echo "STDEV   : ${line#*: }" >> $ind_meta_folder/META
				fi
			done < <(grep . "$ind_meta_folder/Results.txt")
		fi
	done
}

write_Student_Scoreboard()
{
	meta_folder=$1
	csv_student_file=$2
	
	
	echo "WRITING STUDENT SCOREBOARD..."
	
	echo -e "\"TEAMNAME\",\"LANGUAGE\",\"SCORE\",\"STDEV\",\"ERROR\",\"FATALERR\"," >> $csv_student_file
	rm -f $csv_student_file
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -e $ind_meta_folder/META ]
		then
			teamname=""
			language=""
			score=""
			stdev=""
			error=""
			fatalerr=""
			while IFS= read -r line
			do
				if [[ $line == "TEAMNAME"* ]]
				then
					teamname=${line#*: }
				fi
				if [[ $line == "LANGUAGE"* ]]
				then
					language=${line#*: }
				fi
				if [[ $line == "SCORE"* ]]
				then
					score=${line#*: }
				fi
				if [[ $line == "STDEV"* ]]
				then
					stdev=${line#*: }
				fi
				if [[ $line == "ERROR"* ]]
				then
					error="${line#*: }; ${error}"
				fi
				if [[ $line == "FATALERR: "* ]]
				then
					fatalerr="${line#*: }; ${fatalerr}"
				fi
			done <"$ind_meta_folder/META"
			echo -e "\"${teamname}\",\"${language}\",\"${score}\",\"${stdev}\",\"${error}\",\"${fatalerr}\"," >> $csv_student_file
		fi
	done
}

write_Teacher_Spreadsheet()
{
	meta_folder=$1
	csv_teacher_file=$2
	
	echo "WRITING TEACHER SPREADSHEET..."
	
	echo -e "\"UCINETID\",\"LASTNAME\",\"IDNUMBER\",\"SUBMNAME\",\"TEAMNAME\",\"LANGUAGE\",\"SCORE\",\"STDEV\",\"ERROR\",\"FATALERR\",\"FLAGS\"," >> $csv_teacher_file
	rm -f $csv_teacher_file
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -e $ind_meta_folder/META ]
		then
			submname=""
			ucinetid=""
			lastname=""
			idnumber=""
			teamname=""
			language=""
			score=""
			stdev=""
			error=""
			fatalerr=""
			while IFS= read -r line
			do
				if [[ $line == "SUBMNAME"* ]]
				then
					submname=${line#*: }
				fi
				if [[ $line == "UCINETID"* ]]
				then
					ucinetid=${line#*: }
				fi
				if [[ $line == "LASTNAME"* ]]
				then
					lastname=${line#*: }
				fi
				if [[ $line == "IDNUMBER"* ]]
				then
					idnumber=${line#*: }
				fi
				if [[ $line == "TEAMNAME"* ]]
				then
					teamname=${line#*: }
				fi
				if [[ $line == "LANGUAGE"* ]]
				then
					language=${line#*: }
				fi
				if [[ $line == "SCORE"* ]]
				then
					score=${line#*: }
				fi
				if [[ $line == "STDEV"* ]]
				then
					stdev=${line#*: }
				fi
				if [[ $line == "ERROR"* ]]
				then
					error="${line#*: }; ${error}"
				fi
				if [[ $line == "FATALERR: "* ]]
				then
					fatalerr="${line#*: }; ${fatalerr}"
				fi
			done <"$ind_meta_folder/META"
			echo -e "\"${ucinetid}\",\"${lastname}\",\"${idnumber}\",\"${submname}\",\"${teamname}\",\"${language}\",\"${score}\",\"${stdev}\",\"${error}\",\"${fatalerr}\",\"\"" >> $csv_teacher_file
		fi
	done
}

m_meta_folder=$1
m_csv_student_file=$2
m_csv_teacher_file=$3
m_sort_script=$4
m_verify_script=$5

write_Results_To_Meta $m_meta_folder
write_Student_Scoreboard $m_meta_folder $m_csv_student_file
write_Teacher_Spreadsheet $m_meta_folder $m_csv_teacher_file
python $m_verify_script $m_csv_teacher_file 6
python $m_sort_script $m_csv_student_file 2
python $m_sort_script $m_csv_teacher_file 6

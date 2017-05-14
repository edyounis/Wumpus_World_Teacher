#!bin/bash

EEE_Archive_Unpacker()
{
	input_file=$1
	output_folder=$2

	echo "EXTRACTING EEE ARCHIVE..."
		
	mkdir TEMP_EEE_EXTRACT
	unzip -nqq $input_file -d TEMP_EEE_EXTRACT
		
	if [ $? -ne 0 ]
	then
		echo "Failed to extract: "$input_file
		
	elif [ ! -d TEMP_EEE_EXTRACT/Files ]
	then
		echo "Invalid archive: "$input_file
		
	else
		cp -f TEMP_EEE_EXTRACT/Files/* $output_folder
	fi

	rm -rf TEMP_EEE_EXTRACT
}

Input_Collection()
{
	input_folder=$1
	output_folder=$2

	echo "COLLECTING INPUT..."

	if [ ! -d $output_folder ]
	then
		mkdir $output_folder
	fi

	for file in $input_folder/*
	do
		if [[ ${file##*/} == AssignmentSubmission* ]]
		then
			EEE_Archive_Unpacker $file $output_folder
		else
			cp -f $file $output_folder
		fi
	done
}

Meta_Folder_Creation()
{
	input_folder=$1
	meta_folder=$2
	
	echo "CREATING META FOLDERS..."
	
	rm -rf $meta_folder
	mkdir $meta_folder
	
	for submission_archive in $input_folder/*
	do
		archive_name=${submission_archive##*/}
		ucinetID=${archive_name%%_*}
		
		if [ ! -d ${meta_folder}/$ucinetID ]
		then
			mkdir ${meta_folder}/$ucinetID
		fi
		
		cp -f $submission_archive ${meta_folder}/$ucinetID
		touch ${meta_folder}/$ucinetID/META
		echo "SUBMNAME: "$archive_name >> ${meta_folder}/$ucinetID/META
	done
}

Validation()
{
	meta_folder=$1
	
	echo "VALIDATING ARCHIVES..."
	
	for ind_meta_folder in $meta_folder/*
	do
		for file in $ind_meta_folder/*
		do
			if [[ $file != $ind_meta_folder/META ]]
			then
				archive_name=${file##*/}
				archive_name_is_okay=1
				
				if [[ $archive_name != *".zip" ]]
				then
					echo "FATALERR: Submission is not in zip format." >> $ind_meta_folder/META
					archive_name_is_okay=0
				fi
				
				if [[ $(echo $archive_name | grep -o "_" | wc -l) != 3 ]]	# Tests for 3 underscores
				then
					echo "FATALERR: Submission is named incorrectly." >> $ind_meta_folder/META
					archive_name_is_okay=0
				fi
				
				if [[ $archive_name_is_okay == 0 ]]
				then
					echo "Invalid Archive: "$archive_name
					rm -rf $file
				else
					submission_name=${archive_name%.zip}
					uciNetID=$(echo $submission_name | cut -d'_' -f1)
					lastName=$(echo $submission_name | cut -d'_' -f2)
					idNumber=$(echo $submission_name | cut -d'_' -f3)
					teamName=$(echo $submission_name | cut -d'_' -f4)
					echo "UCINETID: "$uciNetID >> $ind_meta_folder/META
					echo "LASTNAME: "$lastName >> $ind_meta_folder/META
					echo "IDNUMBER: "$idNumber >> $ind_meta_folder/META
					echo "TEAMNAME: "$teamName >> $ind_meta_folder/META
				fi
			fi
		done
	done
}

Extraction()
{
	meta_folder=$1
	
	echo "EXTRACTING SUBMISSION ARCHIVES..."
	
	for ind_meta_folder in $meta_folder/*
	do
		for file in $ind_meta_folder/*
		do
			if [[ $file == *".zip" ]]
			then
				mkdir $ind_meta_folder/extracted_files
				unzip -nqq $file -d $ind_meta_folder/extracted_files
				
				if [ $? -ne 0 ]
				then
					echo "Error while extracting: "$file
					echo "FATALERR: Error extracting submission archive." >> $ind_meta_folder/META
					unzip -n $file -d $ind_meta_folder/extracted_files >> $ind_meta_folder/META 2>&1
					rm -rf $ind_meta_folder/extracted_files
				else
					for file in $(find ${ind_meta_folder}/extracted_files/ -name '*__MACOSX' -or -name '*.DS_Store')
					do
						rm -rf $file
					done
				fi
			fi
		done
	done
}

Verification()
{
	meta_folder=$1
	
	echo "FINALIZING PREPARATION..."
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -d $ind_meta_folder/extracted_files ]
		then
			mkdir $ind_meta_folder/doc
			OLDIFS="$IFS"
			IFS="$(echo -e "\n\r")"
			for file in $(find ${ind_meta_folder}/extracted_files/ -name '*.pdf')
			do
				cp -f $file $ind_meta_folder/doc
			done
			IFS=$OLDIFS
			if [[ ! $(ls -A ${ind_meta_folder}/doc) ]]
			then
				echo "ERROR   : Submission doesn't contain a pdf document." >> $ind_meta_folder/META
				rm -rf $ind_meta_folder/doc
			fi
			
			mkdir $ind_meta_folder/src
			for file in $(find ${ind_meta_folder}/extracted_files/ -name 'MyAI.hpp' -or -name 'MyAI.cpp')
			do
				cp -f $file $ind_meta_folder/src
			done
			for file in $(find ${ind_meta_folder}/extracted_files/ -name 'MyAI.java')
			do
				cp -f $file $ind_meta_folder/src
			done
			for file in $(find ${ind_meta_folder}/extracted_files/ -name 'MyAI.py')
			do
				cp -f $file $ind_meta_folder/src
			done
			if [ "$(find $ind_meta_folder/src -name '*.cpp')" ]
			then
				echo "LANGUAGE: C++" >> $ind_meta_folder/META
			elif [ "$(find $ind_meta_folder/src -name '*.java')" ]
			then
				echo "LANGUAGE: Java" >> $ind_meta_folder/META
			elif [ "$(find $ind_meta_folder/src -name '*.py')" ]
			then
				echo "LANGUAGE: Python" >> $ind_meta_folder/META
			else
				echo "FATALERR: Submission doesn't contain valid source code." >> $ind_meta_folder/META
				rm -rf $ind_meta_folder/src
			fi
		fi
	done
}

Compilation_Preparation()
{
	meta_folder=$1
	cpp_shell_src=$2
	java_shell_src=$3
	python_shell_src=$4
	
	echo "COPYING BLANK SHELLS..."
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -d $ind_meta_folder/src ]
		then
			if [ "$(find $ind_meta_folder/src -name '*.cpp')" ]
			then
				cp -a $cpp_shell_src/. $ind_meta_folder/src
			elif [ "$(find $ind_meta_folder/src -name '*.java')" ]
			then
				cp -a $java_shell_src/. $ind_meta_folder/src
			elif [ "$(find $ind_meta_folder/src -name '*.py')" ]
			then
				cp -a $python_shell_src/. $ind_meta_folder/src
			fi
		fi
	done
}

m_input_folder=$1
m_extraction_folder=$2
m_meta_folder=$3
m_cpp_shell_src=$4
m_java_shell_src=$5
m_python_shell_src=$6

Input_Collection $m_input_folder $m_extraction_folder
Meta_Folder_Creation $m_extraction_folder $m_meta_folder
Validation $m_meta_folder
Extraction $m_meta_folder
Verification $m_meta_folder
Compilation_Preparation $m_meta_folder $m_cpp_shell_src $m_java_shell_src $m_python_shell_src
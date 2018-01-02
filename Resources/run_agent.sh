#!bin/bash

submit_folder=$1
cpp_shell_src=$2
java_shell_src=$3
python_shell_src=$4
world_folder=$5
timeout_script=$6
timeout_value=$7

# Extract Source
mkdir -p ${submit_folder}"/src"

for srcFolder in $(find ${submit_folder}/extracted_files/ -name src -type d)
do
	for file in $(find "$srcFolder" -name 'MyAI.hpp' -or -name 'MyAI.cpp')
	do
		cp -f "$file" "$submit_folder/src"
	done
	for file in $(find "$srcFolder" -name 'MyAI.java')
	do
		cp -f "$file" "$submit_folder/src"
	done
	for file in $(find "$srcFolder" -name 'MyAI.py')
	do
		cp -f "$file" "$submit_folder/src"
	done
done

# Detect Language
if [ "$(find $submit_folder/src -name '*.cpp')" ]
then
	echo "C++"
elif [ "$(find $submit_folder/src -name '*.java')" ]
then
	echo "Java"
elif [ "$(find $submit_folder/src -name '*.py')" ]
then
	echo "Python"
else
	echo "FATALERR: No valid source code found."
	rm -rf "$submit_folder/src"
	exit -1
fi

# Extract Document
mkdir "$submit_folder/doc"

OLDIFS="$IFS"
IFS="$(echo -e "\n\r")"

for file in $(find ${submit_folder}/extracted_files/ -name '*.pdf')
do
	cp -f $file "$submit_folder/doc"
done

IFS=$OLDIFS

if [[ ! $(ls -A "${submit_folder}/doc") ]]
then
	echo "ERROR: No pdf document"
	rm -rf "$submit_folder/doc"
else
	echo "Report"
fi

# Copy Blank Shells
if [ -d "$submit_folder/src" ]
then
	if [ "$(find $submit_folder/src -name '*.cpp')" ]
	then
		cp -a "$cpp_shell_src/." "$submit_folder/src"
	elif [ "$(find $submit_folder/src -name '*.java')" ]
	then
		cp -a "$java_shell_src/." "$submit_folder/src"
	elif [ "$(find $submit_folder/src -name '*.py')" ]
	then
		cp -a "$python_shell_src/." "$submit_folder/src"
	fi
fi

# Compile
if [ -d $submit_folder/src ]
then
	if [ "$(find $submit_folder/src -name '*.cpp')" ]
	then
		mkdir $submit_folder/bin
		g++ -std=c++0x $submit_folder/src/*.cpp -o $submit_folder/bin/Wumpus_World &> /dev/null
	
		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to compile."
			rm -rf $submit_folder/bin
			exit -1
		else
			echo "Compiled"
		fi
	
	elif [ "$(find $submit_folder/src -name '*.java')" ]
	then
		mkdir $submit_folder/bin
		javac $submit_folder/src/*.java -d $submit_folder/bin &> /dev/null
	
		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to compile."
			rm -rf $submit_folder/bin
			exit -1
		else
			jar -cvfe $submit_folder/bin/Wumpus_World.jar Main -C $submit_folder/bin . &> /dev/null
			rm -rf $submit_folder/bin/*.class
			echo "Compiled"
		fi
	
	elif [ "$(find $submit_folder/src -name '*.py')" ]
	then
		mkdir $submit_folder/bin
		python3 -m compileall -q $submit_folder/src &> /dev/null
		
		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to compile."
			rm -rf $submit_folder/bin
			exit -1
		else
			cp -a $submit_folder/src/__pycache__/. $submit_folder/bin
			for file in $submit_folder/bin/*
			do
				mv $file ${file%%.*}.pyc
			done
			echo "Compiled"
		fi
		rm -rf $submit_folder/src/__pycache__
	fi
fi

# Execute
if [ -d $submit_folder/bin ]
then
	if [ -f $submit_folder/bin/Wumpus_World ]
	then
		$timeout_script -t $timeout_value $submit_folder/bin/Wumpus_World -f $world_folder $submit_folder/Results.txt &> /dev/null

		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to execute."
		else
			cat $submit_folder/Results.txt
		fi

	elif [ -f $submit_folder/bin/Wumpus_World.jar ]
	then
		$timeout_script -t $timeout_value java -jar $submit_folder/bin/Wumpus_World.jar -f $world_folder $submit_folder/Results.txt &> /dev/null

		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to execute."
		else
			cat $submit_folder/Results.txt
		fi

	elif [ -f $submit_folder/bin/Main.pyc ]
	then
		$timeout_script -t $timeout_value python3 $submit_folder/bin/Main.pyc -f $world_folder $submit_folder/Results.txt &> /dev/null

		if [ $? -ne 0 ]
		then
			echo "FATALERR: Failure to execute."
		else
			cat $submit_folder/Results.txt
		fi
	fi
fi

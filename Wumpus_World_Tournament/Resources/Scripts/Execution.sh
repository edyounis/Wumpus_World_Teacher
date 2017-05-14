#!bin/bash

World_Generation()
{
	world_generator=$1
	world_folder=$2
	
	echo "GENERATING WORLDS..."
	
	if [ ! -d $world_folder ]
	then
		mkdir $world_folder
		$world_generator $world_folder/TournamentWorld4x4 2500 4 4 &> /dev/null
		$world_generator $world_folder/TournamentWorld4x5 500 4 5 &> /dev/null
		$world_generator $world_folder/TournamentWorld4x6 500 4 6 &> /dev/null
		$world_generator $world_folder/TournamentWorld4x7 500 4 7 &> /dev/null
		$world_generator $world_folder/TournamentWorld5x4 500 5 4 &> /dev/null
		$world_generator $world_folder/TournamentWorld5x5 500 5 5 &> /dev/null
		$world_generator $world_folder/TournamentWorld5x6 500 5 6 &> /dev/null
		$world_generator $world_folder/TournamentWorld5x7 500 5 7 &> /dev/null
		$world_generator $world_folder/TournamentWorld6x4 500 6 4 &> /dev/null
		$world_generator $world_folder/TournamentWorld6x5 500 6 5 &> /dev/null
		$world_generator $world_folder/TournamentWorld6x6 500 6 6 &> /dev/null
		$world_generator $world_folder/TournamentWorld6x7 500 6 7 &> /dev/null
		$world_generator $world_folder/TournamentWorld7x4 500 7 4 &> /dev/null
		$world_generator $world_folder/TournamentWorld7x5 500 7 5 &> /dev/null
		$world_generator $world_folder/TournamentWorld7x6 500 7 6 &> /dev/null
		$world_generator $world_folder/TournamentWorld7x7 500 7 7 &> /dev/null
	else
		echo "World folder detecting; skipping world generation"
	fi
}

Compilation()
{
	meta_folder=$1
	
	echo "COMPILING..."
	
	for ind_meta_folder in $meta_folder/*
	do
		if [ -d $ind_meta_folder/src ]
		then
			if [ "$(find $ind_meta_folder/src -name '*.cpp')" ]
			then
				mkdir $ind_meta_folder/bin
				g++ -std=c++0x $ind_meta_folder/src/*.cpp $ind_meta_folder/src/*.hpp -o $ind_meta_folder/bin/Wumpus_World &> /dev/null
			
				if [ $? -ne 0 ]
				then
					echo "FATALERR: Failure to compile." >> $ind_meta_folder/META
					g++ -std=c++0x $ind_meta_folder/src/*.cpp $ind_meta_folder/src/*.hpp -o $ind_meta_folder/bin/Wumpus_World &>> $ind_meta_folder/META
					rm -rf $ind_meta_folder/bin
				fi
			
			elif [ "$(find $ind_meta_folder/src -name '*.java')" ]
			then
				mkdir $ind_meta_folder/bin
				javac $ind_meta_folder/src/*.java -d $ind_meta_folder/bin &> /dev/null
			
				if [ $? -ne 0 ]
				then
					echo "FATALERR: Failure to compile." >> $ind_meta_folder/META
					javac $ind_meta_folder/src/*.java -d $ind_meta_folder/bin &>> $ind_meta_folder/META
					rm -rf $ind_meta_folder/bin
				else
					jar -cvfe $ind_meta_folder/bin/Wumpus_World.jar Main -C $ind_meta_folder/bin . &> /dev/null
					rm -rf $ind_meta_folder/bin/*.class
				fi
			
			elif [ "$(find $ind_meta_folder/src -name '*.py')" ]
			then
				mkdir $ind_meta_folder/bin
				python3 -m compileall -q $ind_meta_folder/src &> /dev/null
				
				if [ $? -ne 0 ]
				then
					echo "FATALERR: Failure to compile." >> $ind_meta_folder/META
					python3 -m compileall $ind_meta_folder/src &>> $ind_meta_folder/META
					rm -rf $ind_meta_folder/bin
				else
					cp -a $ind_meta_folder/src/__pycache__/. $ind_meta_folder/bin
					for file in $ind_meta_folder/bin/*
					do
						mv $file ${file%%.*}.pyc
					done
				fi
				rm -rf $ind_meta_folder/src/__pycache__
			fi
		fi
	done
}

Execution()
{
	meta_folder=$1
	world_folder=$2
	timeout_script=$3
	timeout_value=$4
	
	echo "SCORING AGENTS..."
	
	pids=""
	for ind_meta_folder in $meta_folder/*
	do
		if [ -d $ind_meta_folder/bin ]
		then
			if [ -f $ind_meta_folder/bin/Wumpus_World ]
			then
				( $timeout_script -t $timeout_value $ind_meta_folder/bin/Wumpus_World -f $world_folder $ind_meta_folder/Results.txt ) & &> /dev/null
				pids="${pids} $!"
				pids="${pids}:"
				pids="${pids}$ind_meta_folder"

			elif [ -f $ind_meta_folder/bin/Wumpus_World.jar ]
			then
				( $timeout_script -t $timeout_value java -jar $ind_meta_folder/bin/Wumpus_World.jar -f $world_folder $ind_meta_folder/Results.txt ) & &> /dev/null
				pids="${pids} $!"
				pids="${pids}:"
				pids="${pids}$ind_meta_folder"
			
			elif [ -f $ind_meta_folder/bin/Main.pyc ]
			then
				( $timeout_script -t $timeout_value python3 $ind_meta_folder/bin/Main.pyc -f $world_folder $ind_meta_folder/Results.txt ) & &> /dev/null
				pids="${pids} $!"
				pids="${pids}:"
				pids="${pids}$ind_meta_folder"
			
			fi
		fi
	done
	
	for p in $pids
	do
		if ! wait ${p%%:*}
		then
			echo "FATALERR: Failure to execute." >> ${p##*:}/META
			rm -f ${p##*:}/Results.txt
		fi
	done
}

m_meta_folder=$1
m_world_generator=$2
m_world_folder=$3
m_timeout_script=$4
m_timeout_value=$5

module load python/3.5.2
World_Generation $m_world_generator $m_world_folder
Compilation $m_meta_folder
Execution $m_meta_folder $m_world_folder $m_timeout_script $m_timeout_value

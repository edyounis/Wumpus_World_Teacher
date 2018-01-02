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

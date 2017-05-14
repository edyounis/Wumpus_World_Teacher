TIMEOUT_SECONDS = 7200

all:
	@chmod -R 777 ./*
	@bash Resources/Scripts/Input_Preparation.sh Input Resources/Submission_Archives Resources/Meta_Files Resources/Blank_Cpp_Shell Resources/Blank_Java_Shell Resources/Blank_Python_Shell
	@bash Resources/Scripts/Execution.sh Resources/Meta_Files Resources/World_Generator/World_Generator Resources/Worlds Resources/Scripts/timeout3.sh $(TIMEOUT_SECONDS)
	@bash Resources/Scripts/Output_Preparation.sh Resources/Meta_Files Resources/Scoreboard.csv Resources/Spreadsheet.csv Resources/Scripts/sort.py Resources/Scripts/verify.py
	@cp -r Resources/Meta_Files Output
	@cp -r Resources/Worlds Output
	@cp Resources/Scoreboard.csv Output
	@cp Resources/Spreadsheet.csv Output
	@rm -rf Resources/Worlds
	@rm -rf Resources/Submission_Archives
	@rm -rf Resources/Meta_Files
	@rm -f Resources/Scoreboard.csv
	@rm -f Resources/Spreadsheet.csv
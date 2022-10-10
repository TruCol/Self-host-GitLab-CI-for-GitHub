#!/bin/bash
#source test/hardcoded_testdata.txt

create_file_with_three_lines_without_spaces() {
	touch $FILEPATH_WITHOUT_SPACES
	echo "firstline" > $FILEPATH_WITHOUT_SPACES
	echo "secondline" >> $FILEPATH_WITHOUT_SPACES
	echo "thirdline" >> $FILEPATH_WITHOUT_SPACES
	echo "CREATED FILE"
}

create_file_with_three_lines_with_spaces() {
		echo "first line" > $FILEPATH_WITH_SPACES
		echo "second line" >> $FILEPATH_WITH_SPACES
		echo "third line" >> $FILEPATH_WITH_SPACES
}
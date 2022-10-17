#!/bin/bash


# Returns the sha256 checksum of a file.
get_sha256_of_file() {
	filepath="$1"
	#checksum=$(tar -C "$filepath" -cf - --sort=name "$filepath" | sha256sum)
	checksum=$(sha256sum "$filepath")
	# Echo first substring till spacebar character occurs=sha256.
	echo "$checksum" | cut -d' ' -f1
}


# Returns the sha256 checksum of a folder.
get_sha256_of_folder() {
	dir_path="$1"
	if [ "$(dir_exists "$dir_path")" == "FOUND" ]; then
		
		# Get checksum of directory
		checksum=$(tar -C "$dir_path" -cf - --sort=name "$dir_path" | sha256sum)
		echo checksum="$checksum"
		
		# Echo first substring till spacebar character occurs=sha256.
		echo "$checksum" | cut -d' ' -f1
	else
		echo "ERROR, the directory does not exist locally."
		exit 1
	fi
}

two_folders_are_identical() {
	dirpath_one="$1"
	dirpath_two="$2"
	
	
	if [ "$(dir_exists "$dirpath_one")" == "FOUND" ]; then
		if [ "$(dir_exists "$dirpath_two")" == "FOUND" ]; then
			if [ "$(diff -r "$dirpath_one" "$dirpath_two")" == "" ]; then
				echo "IDENTICAL"
			else
				echo "DIFFERENT"
			fi
		else
			echo "ERROR, the directory $dirpath_two does not exist locally."
			exit 2
		fi
	else
		echo "ERROR, the directory $dirpath_one does not exist locally."
		exit 3
	fi
	
	
	#diff -r "test/sha256_tests/original" "test/sha256_tests/different_creation_date"
	#diff -r "test/sha256_tests/original" "test/sha256_tests/different_dot_dir_content"
	#diff -r "test/sha256_tests/original" "test/sha256_tests/different_dot_dir_content" -qr --exclude=".g"
}

two_folders_are_identical_excluding_subdir() {
	local dirpath_one="$1"
	local dirpath_two="$2"
	local excluding_subdir="$3"
	
	if [ "$(dir_exists "$dirpath_one")" == "FOUND" ]; then
		if [ "$(dir_exists "$dirpath_two")" == "FOUND" ]; then
			if [ "$(dir_exists "$excluding_subdir")" == "FOUND" ]; then
				if [ "$(diff -r "$dirpath_one" "$dirpath_two" -qr --exclude="$excluding_subdir")" == "" ]; then
					echo "IDENTICAL"
				else
					echo "DIFFERENT"
				fi
			else
				if [ "$(diff -r "$dirpath_one" "$dirpath_two" -qr)" == "" ]; then
					echo "IDENTICAL"
				else
					echo "DIFFERENT"
				fi
			fi
		else
			echo "ERROR, the directory $dirpath_two does not exist locally."
			exit 2
		fi
	else
		echo "ERROR, the directory $dirpath_one does not exist locally."
		exit 3
	fi
}
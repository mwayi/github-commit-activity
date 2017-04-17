#!/bin/bash

branch='development';
repository='Merlin';
organisation='mwayi';
activityPrefix='Merge pull';

while [[ $# -gt 0 ]]; do
	key="$1"
	case "$key" in
		# Branch
		-b=*)
		branch="${key#*=}"
		;;
		# Repository
		-r=*)
		repository="${key#*=}"
		;;
		# Branch prefix
		-bp=*)
		organisation="${key#*=}"
		;;
		# Branch prefix
		-ap=*)
		activityPrefix="${key#*=}"
		;;
		*)
		# Do whatever you want with extra options
		echo "Unknown option '$key'"
		;;
	esac
	# Shift after checking all the cases to get the next option
	shift;
done;
	
url='https://github.com/$organisation/$repository/issues';

declare -a features=();
declare -a deprecated=();
declare -a bugs=();
declare -a patches=();
declare -a misc=();

branchTypes=('feature' 'bug' 'patch' 'deprecate');

# git checkout $branch
# git pull

work=$(git log `git describe --tags --abbrev=0`..origin/$branch --grep="$activityPrefix" --pretty=format:"%s Date:(%cD) --- %b");


# Get issue number

function getIssueNumber () {
	line=$@;
	echo $line | grep -o "#\([0-9]\+\)" | grep -o "[0-9]\+";
}

# Get description

function getDescription () {
	line=$@;
	echo $line | grep -o "[-]\{3\} .*$" | cut -c 5-
}

# Get branch type

function getBranchType () {
	line=$@;

	for (( i=0; i<${#branchTypes[@]}; i++ ))
	do
		branchType="${branchTypes[$i]}";
		l=$(echo $line | grep -o "$organisation/$branchType[a-zA-Z-]\+");
		if [[ ! -z "$l" ]]; then echo $branchType ; return
		fi
	done;
	
	echo "misc";
}

# Get date

function getDate () {
	line=$@;
	echo $line | grep -o "Date\:(\(.*\))" | cut -c 7- | rev | cut -c 2- | rev
}

# Save current IFS
cachedIfs=$IFS;

IFS=$'\n'
lines=($work);
IFS=$cachedIfs;

for (( i=0; i<${#lines[@]}; i++ ))
do
	line="${lines[$i]}"

	branch=$(getBranchType $line);
	issueNumber=$(getIssueNumber $line);
	description=$(getDescription $line);
	when=$(getDate $line);

   	if [ $branch = "feature" ]; then
		features+=("- $description [#$issueNumber]($url/$issueNumber) ($when)");
	elif [ $branch = "bug" ]; then
		bugs+=("- $description [#$issueNumber]($url/$issueNumber) ($when)");
	elif [ $branch = "deprecate" ]; then
		deprecated+=("- $description [#$issueNumber]($url/$issueNumber) ($when)");
	elif [ $branch = "patch" ]; then
		patches+=("- $description [#$issueNumber]($url/$issueNumber) ($when)");
	elif [ $branch = "misc" ]; then
		misc+=("- $description [#$issueNumber]($url/$issueNumber) ($when)");
	fi;
done;


printf "\nSTART---------------------- \n";

# Features
if [ -n "$features" ]; then
	printf "\n### Features \n\n";
	printf '%s\n' "${features[@]}"
fi;

# Bugs
if [ -n "$bugs" ]; then
	printf "\n### Bug fixes \n\n";
	printf '%s\n' "${bugs[@]}"
fi;

# Patches
if [ -n "$patches" ]; then
	printf "\n### Patches \n\n";
	printf '%s\n' "${patches[@]}"
fi;

# Deprecated features
if [ -n "$deprecated" ]; then
	printf "\n### Deprecated features \n\n";
	printf '%s\n' "${deprecated[@]}"
fi;

# Misc
if [ -n "$misc" ]; then
	printf "\n### Misc \n\n";
	printf '%s\n' "${misc[@]}";
fi;

printf "\nEND---------------------- \n\n";

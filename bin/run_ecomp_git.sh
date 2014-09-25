#!/bin/bash

GIT_REPO=$1
FILE_GLOB=$2
EXCLUSION_LIST=$3
FORMATTED_EXCLUSIONS=""

# Calculate project name from GIT repository URL
PROJECT_NAME={$GIT_REPO##*/}
PROJECT_NAME={$PROJECT_NAME%.git*}

PROJECT_DIR=/home/jenkins/ecompGitRepos/$PROJECT_NAME
REPORT_DIRECTORY=/mnt/ecompjson/$PROJECT_NAME


ECOMP_DIR=`dirname $0`/../

if [ ! -z "$EXCLUSION_LIST" ]; then
	IFS=","
	SEP=""
	for EXCLUDED_GLOB in $EXCLUSION_LIST; do
		FORMATTED_EXCLUSIONS="$FORMATTED_EXCLUSIONS$SEP-e \"$EXCLUDED_GLOB\""
		SEP=" "
	done
fi
unset IFS

if [[ -z "$GIT_REPO" || -z "$PROJECT_DIR" || -z "$FILE_GLOB" ]]; then
  echo Usage: `basename $0` git_repository_url file_glob [csv_for_excluded_files]
  exit -1
fi

echo

if [ ! -d "$PROJECT_DIR" ]; then
	echo Performing initial git clone for revision range $SVN_REVISION - $END_SVN_REVISION
	git clone $GIT_REPO $PROJECT_DIR
	if [ $? != 0 ]; then
		echo There were errors checking out the project, please fix this before continuing
		echo The command used to checkout the repository was:
		echo git clone $GIT_REPO $PROJECT_DIR
		exit -1
	fi
	cd $PROJECT_DIR
else
	echo Updating project
	cd $PROJECT_DIR
	git checkout -f master
	git clean -x -f -d
	git pull
	if [ $? != 0 ]; then
  		echo There were errors updating the project, please fix this before continuing
  		echo This was ran in the $PROJECT_DIR directory
		exit -1;
	fi
fi

echo -n "Running metrics for $FILE_GLOB files"
if [ ! -z "$FORMATTED_EXCLUSIONS" ]; then
	echo " and excluding $FORMATTED_EXCLUSIONS"
else
	echo
fi

metrics $REPORT_DIRECTORY "$FILE_GLOB" $FORMATTED_EXCLUSIONS

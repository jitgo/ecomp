#!/bin/bash

GIT_REPO=$1
PROJECT_DIR=$2
FILE_GLOB=$3
EXCLUSION_LIST=$4
FORMATTED_EXCLUSIONS=""

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
  echo Usage: `basename $0` git_repository_url target_project_dir file_glob [csv_for_excluded_files]
  exit -1
fi

echo

ECOMP_DIR=`dirname $0`/../

REPORT_DIRECTORY=~/mnt/ecompjson/$PROJECT_DIR

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
	git rebase
	if [ $? != 0 ]; then
  		echo There were errors updating the project, please fix this before continuing
  		echo The command used to update the project was:
  		echo git rebase
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

../metrics $REPORT_DIRECTORY "$FILE_GLOB" $FORMATTED_EXCLUSIONS
if [ ! -e "$ECOMP_DIR/public/data/$PROJECT_DIR" ]; then
	echo Creating project report data symlink from $REPORT_DIRECTORY to $ECOMP_DIR/public/data/$PROJECT_DIR
	ln -sf $REPORT_DIRECTORY $ECOMP_DIR/public/data/$PROJECT_DIR
fi

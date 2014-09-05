#!/bin/bash

SVN_REPO=$1
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

if [[ -z "$SVN_REPO" || -z "$PROJECT_DIR" || -z "$FILE_GLOB" ]]; then
  echo Usage: `basename $0` svn_repository_url target_project_dir file_glob [csv_for_excluded_files]
  exit -1
fi

ECOMP_DIR=`dirname $0`/../

SVN_REVISION=$(svn log -r 1:HEAD -l 1 $SVN_REPO | tail -n+2 | head -n 1 | awk '{ print substr($1, 2) }')
if [ -z "$SVN_REVISION" ]; then
	echo Failed to retrieve SVN start revision from SVN log
	exit -1
fi

SVN_INFOOUTPUT=$(svn info $SVN_REPO)

if [ -z "$SVN_INFOOUTPUT" ]; then
	echo Failed to retrieve SVN end revision from SVN info
	exit -1
fi

END_SVN_REVISION=$(svn info $SVN_REPO | grep "^Last Changed Rev: " | awk '{ print $4 }')
TRANSLATE_AUTHOR=`which translate_bbc_username.pl`
REPORT_DIRECTORY=/mnt/ecompjson/$PROJECT_DIR

if [ ! -d "$PROJECT_DIR" ]; then
	echo Performing initial git svn clone for revision range $SVN_REVISION - $END_SVN_REVISION
	git svn clone --authors-prog $TRANSLATE_AUTHOR -r $SVN_REVISION:$END_SVN_REVISION $SVN_REPO $PROJECT_DIR
	if [ $? != 0 ]; then
		echo There were errors checking out the project, please fix this before continuing
		echo The command used to checkout the repository was:
		echo git svn clone --authors-prog $TRANSLATE_AUTHOR -r $SVN_REVISION:$END_SVN_REVISION $SVN_REPO $PROJECT_DIR
		exit -1
	fi
	cd $PROJECT_DIR
else
	cd $PROJECT_DIR
	git svn rebase --authors-prog $TRANSLATE_AUTHOR
	if [ $? != 0 ]; then
  		echo There were errors updating the project, please fix this before continuing
  		echo The command used to update the project was:
  		echo git svn rebase --authors-prog $TRANSLATE_AUTHOR
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
if [ ! -e "$ECOMP_DIR/public/data/$PROJECT_DIR" ]; then
	echo Creating project report data symlink from $REPORT_DIRECTORY to $ECOMP_DIR/public/data/$PROJECT_DIR
	ln -sf $REPORT_DIRECTORY $ECOMP_DIR/public/data/$PROJECT_DIR
fi

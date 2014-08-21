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

SVN_REVISION=`svn log -r 1:HEAD -l 1 $SVN_REPO | tail -n+2 | head -n 1 | awk '{ print substr($1, 2) }'`
END_SVN_REVISION=$(svn info $SVN_REPO | grep "^Last Changed Rev: " | awk '{ print $4 }')
TRANSLATE_AUTHOR=`which translate_bbc_username.pl`
REPORT_DIRECTORY=`pwd`/$PROJECT_DIR/reports

if [ ! -d "$PROJECT_DIR" ]; then
  git svn clone --authors-prog $TRANSLATE_AUTHOR -r $SVN_REVISION:$END_SVN_REVISION $SVN_REPO $PROJECT_DIR
  cd $PROJECT_DIR
else
  cd $PROJECT_DIR
  git svn rebase --authors-prog $TRANSLATE_AUTHOR
fi

if [ ! -d "reports" ]; then
  mkdir "reports"
fi

echo -n "Running metrics for $FILE_GLOB files"
if [ ! -z "$FORMATTED_EXCLUSIONS" ]; then
	echo " and excluding $FORMATTED_EXCLUSIONS"
else
	echo
fi

metrics $REPORT_DIRECTORY "$FILE_GLOB" $FORMATTED_EXCLUSIONS
ln -sf $REPORT_DIRECTORY $ECOMP_DIR/public/data/$PROJECT_DIR

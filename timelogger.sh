#!/bin/bash
#
# timelogger.sh - timelogging made easy
# 
# Copyright (c) 2014, Tino Rusch
#
# This file is released under the terms of the MIT license. You can find the
# complete text in the attached LICENSE file or online at:
#
# http://www.opensource.org/licenses/mit-license.php
# 
# @author: Tino Rusch (tino.rusch@webvariants.de)
#

NAME=""
REMOTE=""
BRANCH=""
PROJECT=""
HOURS=""
DESCRIPTION=""
DATE=""

if test -e ~/.timelogger/config; then
	source ~/.timelogger/config
fi

function setVariableFromCommandline {
	read -p "$1 = " $1
}

function init {
	read -r -n 1 -p "This will destroy your local logging repo! Are you sure? (Y|n)" reply
	if [[ ! $reply =~ ^(Y|y|J|j|)$ ]]; then
		echo "Abort!"
		return 1
	fi
	rm -rf ~/.timelogger
	setVariableFromCommandline NAME
	setVariableFromCommandline REMOTE
	setVariableFromCommandline BRANCH
	mkdir -p ~/.timelogger
	saveConfig
	pushd ~/.timelogger
	git clone $REMOTE repo
	pushd repo
	git checkout --track origin/$BRANCH -b $BRANCH
	git pull
	if [[ ! -e logs.csv ]]; then
		echo "timestamp,date,name,hours,project,description" > logs.csv
		git add logs.csv
		git commit -m "inital commit from $NAME;"
		git push 
	fi
	popd
	popd
}

function log {
	HOURS=$1
	PROJECT=$2
	DESCRIPTION=$3
	TIMESTAMP=$(date +%s)
	pushd ~/.timelogger/repo
	echo "$TIMESTAMP,$DATE,$NAME,$HOURS,$PROJECT,$DESCRIPTION" >> logs.csv
	git add logs.csv
	git commit -m "$NAME's timelogging for $DATE;"
	git push
}

function help {
	echo "usage: $0"
	echo "-u | --user       Your username"
	echo "-r | --remote     Timelogging repository"
	echo "-b | --branch     Userbranch"
	echo "-d | --date       Date of worklog"
	echo "-p | --project    Project you worked on"
	echo "-h | --hours      How many hours you worked"
	echo "-m | --message    The description of the worklog"
	echo "     --init            Initialize / reset your timelogger"
	echo "     --help            Print this help"
}


function completeVariables {
	if [[ $NAME == "" ]]; then
	setVariableFromCommandline NAME
	fi
	if [[ $REMOTE == "" ]]; then
		setVariableFromCommandline REMOTE
	fi
	if [[ $BRANCH == "" ]]; then
		setVariableFromCommandline BRANCH
	fi
	if [[ $PROJECT == "" ]]; then
		setVariableFromCommandline PROJECT
	fi
	if [[ $HOURS == "" ]]; then
		setVariableFromCommandline HOURS
	fi
	if [[ $DESCRIPTION == "" ]]; then
		setVariableFromCommandline DESCRIPTION
	fi
	if [[ "$DATE" == "" ]]; then
		DATE=$(date +%x)
	fi
}

function saveConfig {
	echo "# auto generated timelogger config" > ~/.timelogger/config
	echo "NAME=\"$NAME\"" >> ~/.timelogger/config
	echo "REMOTE=$REMOTE" >> ~/.timelogger/config
	echo "BRANCH=$BRANCH" >> ~/.timelogger/config
	echo "PROJECT=\"$PROJECT\"" >> ~/.timelogger/config
	echo "HOURS=$HOURS" >> ~/.timelogger/config
	echo "DESCRIPTION=\"$DESCRIPTION\"" >> ~/.timelogger/config
}

function askForLogging {
	echo "Your current timelog configuration:"
	echo "" 
	echo "PROJECT=\"$PROJECT\"" 
	echo "DATE=$DATE"
	echo "HOURS=$HOURS" 
	echo "DESCRIPTION=\"$DESCRIPTION\"" 
	echo "NAME=\"$NAME\"" 
	echo "REMOTE=$REMOTE" 
	echo "BRANCH=$BRANCH" 
	echo ""

	read -r -n 1 -p "Is this correct? (Y|n)" reply
	if [[ ! $reply =~ ^(Y|y|J|j|)$ ]]; then
		echo "Abort!"
		return 1
	fi
	return 0
}

function clearVars {
	PROJECT="" 
	HOURS="" 
	DESCRIPTION="" 
}

while [[ $# -gt 0 ]]; do
	opt="$1"
	shift;
	current_arg="$1"
	if [[ "$current_arg" =~ ^-{1,2}.* ]]; then
		echo "WARNING: You may have left an argument blank. Double check your command." 
		exit 1
	fi
	case "$opt" in
		"-u"|"--user"       ) NAME="$1"; shift;;
		"-r"|"--remote"     ) REMOTE="$1"; shift;;
		"-b"|"--branch"     ) BRANCH="$1"; shift;;
		"-d"|"--date"       ) DATE="$1"; shift;;
		"-p"|"--project"    ) PROJECT="$1"; shift;;
		"-h"|"--hours"      ) HOURS="$1"; shift;;
		"-m"|"--message"    ) DESCRIPTION="$1"; shift;;
		"--init"        	) init; exit $?;;
		"--help"        	) help; exit 0;;
		"--interactive"		) clearVars; shift;;
		*                   ) echo "ERROR: Invalid option: \""$opt"\"" >&2; exit 1;;
	esac
done

completeVariables
saveConfig
askForLogging || exit 1
log $HOURS "$PROJECT" "$DESCRIPTION"

exit $?

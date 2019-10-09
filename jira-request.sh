#!/bin/bash

. read_var.sh

FILE=$1
JIRA_HOST="issues.jboss.org"
USER='fgiorget'
#API_TOKEN=""
JIRA_PASS=""
TMPDIR="/tmp"

# expects file as 1st arg
[[ ! -f $FILE ]] && echo Use $0 json_file && exit 1

if [[ -z ${API_TOKEN} && -z ${JIRA_PASS} ]]; then
    while [[ -z ${JIRA_PASS} ]]; do
        echo "JIRA_PASS variable not set, please type Jira password for [${USER}]: "
        read -s JIRA_PASS
    done
fi

# If filename contains sub, consider creating subtasks
subtask=false
[[ ${FILE,,} =~ 'sub' ]] && subtask=true && moresubs=true

if [[ $subtask = true ]]; then
    read_var PARENT_TASK "Parent task" true
fi

# create a new issue on Jira
function create_issue() {

	# enter input till user is happy
	confirm=false
	while [[ $confirm = false ]]; do
		read_var SUMMARY "Summary" true
		
		echo "Description (press ctrl+d when done):"
		DESCRIPTION=$(</dev/stdin)
		DESCRIPTION="${DESCRIPTION//\"/&quot;}"
		DESCRIPTION="${DESCRIPTION//$'\n'/\\n}"
		
        if [[ $subtask = true ]]; then
            read_var ESTIMATE "Estimate" true
        fi

		echo "Summary is: $SUMMARY"
		echo "Description is:"
		echo "$DESCRIPTION"
	
        if [[ $subtask = true ]]; then
            echo "Estimate: $ESTIMATE"
        fi

	    echo
	    read_var PROCEED "Are you good with the summary and description?" true 'y' 'y' 'n' 
	    [[ ${PROCEED,,} = 'y' ]] && confirm=true
	done
	
	
	content="$(cat $FILE)"
	eval echo \""${content//\"/\\\"}"\" > ${TMPDIR}/data.tmp.$$
	
	# invoke it
    #AUTH_ARG="-u \"${USER}:${JIRA_PASS}\""
    AUTH_ARG="-u \\\"${USER}:${JIRA_PASS}\\\""
    if [[ -n ${API_TOKEN} ]]; then
        #AUTH_ARG="--header \"Authorization: Bearer ${API_TOKEN}\""
        AUTH_ARG="--header \\\"Authorization: Bearer ${API_TOKEN}\\\""
    fi

	#eval echo curl -s -v \
	eval echo curl -s \
	   -D- \
       ${AUTH_ARG} \
	   -X POST \
	   --data @${TMPDIR}/data.tmp.$$ \
	   --header \\\"Content-Type: application/json\\\" \
	   --url \\\"https://${JIRA_HOST}/rest/api/2/issue/\\\" | sh > ${TMPDIR}/result.tmp.$$
	   #--url \\\"https://${JIRA_HOST}/rest/api/2/issue/\\\"

    RESULT_JIRA=`egrep '(^HTTP\/1\.1 |{"id":")' ${TMPDIR}/result.tmp.$$ | sed -re 's/HTTP\/1\.1 ([0-9]+) .*/\1/g;s/\{"id".*"key":"([^\"]+)".*/\1/g'`
    echo "${RESULT_JIRA}" | while read -r CODE; do
        read -r JIRA
        if [[ ${CODE} != "201" ]]; then
            echo "Error creating new Jira."
            echo "Result:"
            echo
            cat ${TMPDIR}/result.tmp.$$
        fi
        echo "Jira has been created: https://${JIRA_HOST}/browse/${JIRA}"
    done        
	
    echo

}


# Loop while allows to continue
while [[ $subtask = false || $moresubs = true ]]; do

    # Create a new issue
    create_issue

    # When not creating sub-tasks, simply quit
    if [[ $subtask = false ]]; then
        break
    else
        read_var NEWSUB "Do you want to create more sub-tasks?" true 'y' 'y' 'n'
	    [[ ${NEWSUB,,} = 'n' ]] && moresubs=false
    fi

done

#!/bin/bash

. read_var.sh

FILE=$1
JIRA_HOST="issues.redhat.com"
#JIRA_USER=""
#JIRA_PASS=""
#API_TOKEN=""
TMPDIR="/tmp"

# sanity check
if [[ -z `which dialog 2> /dev/null` ]]; then
    echo "You must install 'dialog' before proceeding"
    exit 1
fi

# expects file as 1st arg
[[ ! -f $FILE ]] && echo Use $0 json_file && exit 1

while [[ -z ${JIRA_USER} ]]; do
    echo "JIRA_USER variable not set, please type Jira user: "
    read JIRA_USER
done
# read pass if not set
if [[ -z ${API_TOKEN} && -z ${JIRA_PASS} ]]; then
    while [[ -z ${JIRA_PASS} ]]; do
        echo "JIRA_PASS variable not set, please type Jira password for [${JIRA_USER}]: "
        read -s JIRA_PASS
    done
fi

# If filename contains sub, consider creating subtasks
subtask=false
[[ ${FILE,,} =~ 'sub' ]] && subtask=true && moresubs=true

if [[ $subtask = true ]]; then
    read_var PARENT_TASK "Parent task" true
    export PARENT_TASK
fi

# create a new issue on Jira
function create_issue() {

    # extracting variables from template
    content=`cat $FILE`
    template_vars=`envsubst -v "${content}"`
    vars_populated=()

    # if a parent task already provided, add it to vars_populated
    [[ -n ${PARENT_TASK} ]] && vars_populated+=(PARENT_TASK)

	# enter input till user is happy
	confirm=false
	while [[ $confirm = false ]]; do
        touch /tmp/empty.$$

        for variable in ${template_vars}; do
            # Ignoring variables already parsed
            if [[ " ${vars_populated[@]} " =~ " ${variable} " ]]; then
                continue
            fi
            touch /tmp/$variable.$$
            echo Reading $variable
            if [[ ${variable} =~ ^EDITBOX_.*$ ]]; then
                dialog --title "${variable:8} - using template: $FILE" --clear --editbox /tmp/empty.$$ 16 51  2> /tmp/$variable.$$
            else
                dialog --title "${variable} - using template: $FILE" --clear --inputbox "" 16 51  2> /tmp/$variable.$$
            fi
            if [[ $? -ne 0 ]]; then
                clear
                echo "Cancelled by user. Exiting."
                exit 0
            fi
            # replacing \n with literal '\n'
            sed -E -i ':a;N;$!ba;s/\r{0,1}\n/\\n/g' /tmp/$variable.$$
            # replacing " with literal &quot;
            sed -i 's/"/\&quot;/g' /tmp/$variable.$$
            eval export $variable=\$\(cat /tmp/$variable.$$\)
            vars_populated+=(${variable})
            # if a parent task already provided, add it to vars_populated
            [[ -n ${PARENT_TASK} ]] && vars_populated+=(PARENT_TASK)
        done

        clear
        echo Review the JIRA request content:
        echo
        cat "${FILE}" | envsubst
        echo
        
	    read_var PROCEED "Are you good with the content?" true 'y' 'y' 'n' 
	    [[ ${PROCEED,,} = 'y' ]] && confirm=true || vars_populated=()
	done
	
	content="$(cat $FILE | envsubst)"
	eval echo \""${content//\"/\\\"}"\" > ${TMPDIR}/data.tmp.$$
	
	# invoke it
    #AUTH_ARG="-u \"${JIRA_USER}:${JIRA_PASS}\""
    AUTH_ARG="-u \\\"${JIRA_USER}:${JIRA_PASS}\\\""
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

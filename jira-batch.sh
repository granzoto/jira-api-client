#!/bin/bash

. read_var.sh

JIRA_HOST="issues.redhat.com"
#JIRA_USER=""
#JIRA_PASS=""
#API_TOKEN=""
TMPDIR="/tmp"

function exit_error() {
    echo $*
    exit 1
}

[[ $# -lt 2 ]] && exit_error "Use: $0 csv template"

CSVFILE=$1
FILE=$2

# validate csv fileenvfile
[[ ! -f ${CSVFILE} ]] && exit_error "Invalid CSV file"
[[ ! -f ${FILE} ]] && exit_error "Invalid Template file"
declare -a CSV_VARS
IFS=', ' read -r -a CSV_VARS < <(head -1 ${CSVFILE})

# validate all variables from template are available
declare -A MISSING_VARS
[[ ! -f ${FILE} ]] && exit_error Invalid template: ${FILE}
for var in $(cat ${FILE} | egrep -o '\$\{[^}]+\}' | sed -re 's#^\$\{##g; s#\}$##g'); do
    found=false
    for csvvar in ${CSV_VARS[@]}; do
        [[ "${var}" == "${csvvar}" ]] && found=true && break
    done
    if ! $found; then
        MISSING_VARS[${var}]=""
    fi
done
[[ "${!MISSING_VARS[@]}x" != "x" ]] && exit_error "Missing CSV variables: ${!MISSING_VARS[@]}"

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

# create a new issue on Jira
function create_issue() {

	content="$(cat $FILE)"
	eval echo \""${content//\"/\\\"}"\" > ${TMPDIR}/data.tmp.$$
	
	# invoke it
    AUTH_ARG="-u \\\"${JIRA_USER}:${JIRA_PASS}\\\""
    if [[ -n ${API_TOKEN} ]]; then
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

}


# Loop through CSV data
[[ `wc -l ${CSVFILE} | awk '{print $1}'` -le 1 ]] && exit_error CSV file is empty
IFS=$'\n'
for line in `tail -n +2 ${CSVFILE}`; do

    # Ignoring comments
    [[ $line =~ ^# ]] && continue

    # Reading CSV data
    IFS=',' read -r -a CSV_VALUES <<< ${line}

    # Setting all CSV variables
    i=0
    for csvvar in ${CSV_VARS[@]}; do
        eval ${csvvar}=\$\{CSV_VALUES\[\$\{i\}\]\}
        ((i+=1))
    done

    # Create a new issue
    create_issue

done
echo

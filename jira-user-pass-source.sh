#!/bin/bash

# This has to be sourced in your bash session
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

export JIRA_USER
export JIRA_PASS

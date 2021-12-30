#!/usr/bin/env bash

# Name     : jenkins-cli-shell.sh
# Author   : Chris Bishop
# Date     : 21Dec2021
# Purpose  : Use the Jenkins CLI tool to install plugins manually or execute various other Jenkins CLI commands. See URL in Refs for details.
#            NOTE - This script will also check for ./jenkins-cli.jar in script directory, and download from JENKINS_URL if not exists.
# Refs     : https://www.jenkins.io/doc/book/managing/cli/
# Usage    : ./jenkins-cli-shell.sh "<YOUR_DESIRED_JENKINS_CLI_CMD_ARGS>"

JENKINS_CLI=jenkins-cli.jar
JENKINS_CJOC_URL=https://jenkins-new.knewknovel.com/
JENKINS_AUTH="/home/cbishop/.jenkins-cli"

if [ -z "$JENKINS_CJOC_URL" ]; then
    echo "Need to set environment variable JENKINS_CJOC_URL (Operations Center root URL)."
    exit 1
fi

if [ -z "$JENKINS_AUTH" ]; then
    echo "Need to set environment variable JENKINS_AUTH (format: 'userId:apiToken')."
    exit 1
fi


if [ -f "$JENKINS_CLI" ]
then
	echo "Using $JENKINS_CLI."
else
	wget -O "$JENKINS_CLI" $JENKINS_CJOC_URL/jnlpJars/jenkins-cli.jar
fi

java -jar $JENKINS_CLI -s $JENKINS_CJOC_URL -auth $JENKINS_AUTH list-masters | jq -r '.data.masters[] | select(.status == "ONLINE") | .url' | while read url; do
	java -jar $JENKINS_CLI -s $url -auth @$JENKINS_AUTH groovy = < configuration-script.groovy
	java -jar $JENKINS_CLI -s $url -auth @$JENKINS_AUTH install-plugin beer
done
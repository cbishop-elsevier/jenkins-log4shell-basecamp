#!/bin/bash

LOG_DEBUG="false";

# CONTAINER RUNTIME CONTEXT WORKSPACE
# NOTE - set this to our own variable so as not to keep performing env variable lookup evals for better efficiency
TOOLCHAIN_DIR="${GITHUB_WORKSPACE}/repo-scan-tools";
SCAN_DIR="${GITHUB_WORKSPACE}/repo-to-scan/sample-jars";

# RUNTIME ARGS - We will use these later, for now, just placeholder
SCAN_DIRS="";
[[ -n $DIRS_TO_SCAN ]] && declare -a SCAN_DIRS=("${DIRS_TO_SCAN}") || declare -a SCAN_DIRS=("${GITHUB_WORKSPACE}/repo-to-scan")

## func_Logger ()
function func_Logger () {
  TIMESTAMP="`date +%Y%m%d-%T`";
  echo "[${TIMESTAMP}] - $1";
}

func_Logger "-----------------------------------";
if [ "${LOG_DEBUG}" == "true" ]; then
  func_Logger "ENV VARS:";
  printenv
  func_Logger "-----------------------------------";
fi
func_Logger "RUNTIME_CONTEXT_DIR: ${GITHUB_WORKSPACE}"
func_Logger "-----------------------------------"
func_Logger "DIRS_TO_SCAN: ${DIRS_TO_SCAN}"
func_Logger "DIRS_TO_EXCLUDE: ${DIRS_TO_EXCLUDE}"
func_Logger "SCAN_DIRS: ${SCAN_DIRS}"
func_Logger "EXCL_DIRS: ${EXCL_DIRS}"
func_Logger "-----------------------------------"

if [ "${LOG_DEBUG}" == "true" ]; then
  func_Logger "SCAN_DIRS:";
  for d in ${SCAN_DIRS[@]}; do
    func_Logger "${SCAN_DIR}/${d}";
  done
  func_Logger "-----------------------------------";
fi

func_Logger "INIT - Scan against ${SCAN_DIR}";

func_Logger "NOTE - The combination of the following two search methods ensures matching on BOTH direct reference and transitive references by depedency):"

func_Logger "-----------------------------------"

func_Logger "CLASS CODE VERSION FINGERPRINT MATCHING:";

python ${TOOLCHAIN_DIR}/scan_log4j_versions.py ${SCAN_DIR}

func_Logger "-----------------------------------";

func_Logger "MATCH ANY CLASS WITH FOLLOWING REGEX PATTERNS IN NAMESPACE: org/apache/logging/log4j/Logger , .*Jndi(Manager|Lookup)))$ ";

python ${TOOLCHAIN_DIR}/scan_log4j_calls_jar.py --class_regex "((org/apache/logging/log4j/Logger)|(.*Jndi(Manager|Lookup)))$" --class_existence ${SCAN_DIR}

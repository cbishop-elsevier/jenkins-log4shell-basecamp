#!/bin/bash

# Enable more verbose logging, such as expanded / interpolated commands, etc
# NOTE - BE CAREFUL WITH THIS! DO NOT EXPOSE ANY COMMANDS WHICH ByVal REF GITHUB_TOKEN ENV VAR!
LOG_DEBUG="false";

# Number of CQL Async Threads for Ops That CAN Be Parallelized.
# NOTE - Default is 1 (single). Setting to 0 will use ALL available logical CPU/vCPU!
# See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system#analyzing-a-codeql-database
NUM_CQL_THREADS="0";

# Upload Scan Results Back to GitHub for Automated CodeQL Report, Issue, and Notification Creation?
# NOTE - THIS WILL ONLY WORK IF YOUR ACCOUNT AND THE RESPECTIVE REPOSITORY MEET ELIGIBILITY REQUIREMENTS!
# See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system#uploading-results-to-github
UPLOAD_SCAN_RESULTS_TO_GIT="true";

# CONTAINER RUNTIME CONTEXT WORKSPACE
# NOTE - set this to our own variable so as not to keep performing env variable lookup evals for better efficiency
TOOLCHAIN_BASE_URL="https://github.com/github/codeql-action/releases/latest/download";
TOOLCHAIN_TAR_FILE="codeql-bundle-linux64.tar.gz";
TOOLCHAIN_DIR="${GITHUB_WORKSPACE}/codeql";
TOOLCHAIN_DBS_DIR="${GITHUB_WORKSPACE}/codeql-dbs";
SCAN_DIR="${GITHUB_WORKSPACE}/repo-to-scan";

# RUNTIME ARGS - We will use these later, for now, just placeholder
SCAN_CMD="";
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

func_Logger "-----------------------------------";

# See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/installing-codeql-cli-in-your-ci-system

func_Logger "OBTAIN LATEST TOOLCHAIN BUNDLE:";

if [ -f "${TOOLCHAIN_TAR_FILE}" ]; then
  func_Logger "${TOOLCHAIN_TAR_FILE} exists, skipping remote artifact pull!";
else
  func_Logger "${TOOLCHAIN_TAR_FILE} does not exist, initiating remote artifact pull!";
  [[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="wget ${TOOLCHAIN_BASE_URL}/${TOOLCHAIN_TAR_FILE}" && func_Logger "${SCAN_CMD};" || SCAN_CMD="wget --quiet ${TOOLCHAIN_BASE_URL}/${TOOLCHAIN_TAR_FILE}";
  ${SCAN_CMD};
fi

func_Logger "-----------------------------------";

func_Logger "BOOTSTRAP AND SCAFFOLD TOOLCHAIN AND BUNDLED QLPACKS:";

if [ -f "${TOOLCHAIN_DIR}/codeql" ]; then
  func_Logger "${TOOLCHAIN_DIR}/codeql exists, skipping local toolchain bootstrap and scaffold!";
else
  func_Logger "${TOOLCHAIN_DIR}/codeql does not exist, initiating local toolchain bootstrap and scaffold!";
  [[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="tar -xszvf ${TOOLCHAIN_TAR_FILE}" && func_Logger "${SCAN_CMD};" || SCAN_CMD="tar -xszf ${TOOLCHAIN_TAR_FILE}";
  ${SCAN_CMD};
fi

func_Logger "-----------------------------------";

func_Logger "VALIDATE TOOLCHAIN BUNDLED QLPACKS:";

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="${TOOLCHAIN_DIR}/codeql resolve qlpacks --verbose" && func_Logger "${SCAN_CMD};" || SCAN_CMD="${TOOLCHAIN_DIR}/codeql resolve qlpacks";
${SCAN_CMD};

func_Logger "-----------------------------------";

# See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system

func_Logger "CLEAN LOCAL DB ARTIFACTS AND CREATE FRESH CQL DBS FOR REPO STATE:";

[[ -d "${TOOLCHAIN_DBS_DIR}" ]] && rm -rf ${TOOLCHAIN_DBS_DIR};

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="mkdir -p ${TOOLCHAIN_DBS_DIR}" && func_Logger "${SCAN_CMD};" || SCAN_CMD="mkdir -p ${TOOLCHAIN_DBS_DIR}";
${SCAN_CMD};

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="${TOOLCHAIN_DIR}/codeql database create --threads=${NUM_CQL_THREADS} --verbose ${TOOLCHAIN_DBS_DIR}/repo-to-scan --language=python --source-root ${SCAN_DIR}" \
  && func_Logger "${SCAN_CMD};" || SCAN_CMD="${TOOLCHAIN_DIR}/codeql database create --threads=${NUM_CQL_THREADS} ${TOOLCHAIN_DBS_DIR}/repo-to-scan --language=python --source-root ${SCAN_DIR}";
${SCAN_CMD};

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="ls -latr ${TOOLCHAIN_DBS_DIR}/*" && func_Logger "${SCAN_CMD};" && ${SCAN_CMD};

func_Logger "-----------------------------------";

# See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system

func_Logger "RUN ANALYSIS QUERIES FOR LANGUAGE (python) AGAINST FRESH DB FOR REPO:";

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="${TOOLCHAIN_DIR}/codeql database analyze --threads=${NUM_CQL_THREADS} --verbose ${TOOLCHAIN_DBS_DIR}/repo-to-scan --sarif-category=python --format=sarif-latest --output=/tmp/repo-to-scan-python.sarif" \
  && func_Logger "${SCAN_CMD};" || SCAN_CMD="${TOOLCHAIN_DIR}/codeql database analyze --threads=${NUM_CQL_THREADS} ${TOOLCHAIN_DBS_DIR}/repo-to-scan --sarif-category=python --format=sarif-latest --output=/tmp/repo-to-scan-python.sarif";
${SCAN_CMD};

[[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="ls -latr /tmp/*" && func_Logger "${SCAN_CMD};" && ${SCAN_CMD};

if [ "${LOG_DEBUG}" == "true" ]; then
  func_Logger "-----------------------------------";
  # See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system
  func_Logger "RESULT FILE DUMP:";
  func_Logger "cat /tmp/repo-to-scan-python.sarif;";
  func_Logger "-----------------------------------";
  cat /tmp/repo-to-scan-python.sarif;
fi

if [ "${UPLOAD_SCAN_RESULTS_TO_GIT}" == "true" ]; then
  func_Logger "-----------------------------------";
  # See: https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system#uploading-results-to-github
  func_Logger "UPLOAD SCAN RESULT SARIF FILE TO GIT:";
  func_Logger "${TOOLCHAIN_DIR}/codeql github upload-results --repository=${GITHUB_REPOSITORY} --ref=${GITHUB_REF} --commit=${GITHUB_SHA} --sarif=/tmp/repo-to-scan-python.sarif;";
  ${TOOLCHAIN_DIR}/codeql github upload-results --repository=${GITHUB_REPOSITORY} --ref=${GITHUB_REF} --commit=${GITHUB_SHA} --sarif=/tmp/repo-to-scan-python.sarif;

  [[ "${LOG_DEBUG}" == "true" ]] && SCAN_CMD="${TOOLCHAIN_DIR}/codeql github upload-results --verbose --repository=${GITHUB_REPOSITORY} --ref=${GITHUB_REF} --commit=${GITHUB_SHA} --sarif=/tmp/repo-to-scan-python.sarif --github-auth-stdin" \
    && func_Logger "${SCAN_CMD};" || SCAN_CMD="${TOOLCHAIN_DIR}/codeql github upload-results --repository=${GITHUB_REPOSITORY} --ref=${GITHUB_REF} --commit=${GITHUB_SHA} --sarif=/tmp/repo-to-scan-python.sarif --github-auth-stdin";
  echo $REPO_AUTH_TKN | ${SCAN_CMD};
fi

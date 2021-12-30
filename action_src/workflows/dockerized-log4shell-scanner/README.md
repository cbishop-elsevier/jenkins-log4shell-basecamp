```bash
Name: worklows/dockerized-log4shell-scanner
Author: Chris Bishop
Date: 23Dec2021
Purpose: Automatically runs log4shell detection scan (implements: JFrog OSS Log4Shell Scanning Utilz) against the repository root (default)
          or against a specified set of repository subdirectories passed as input (map) and create a new issue in repo on vulnerability found.
          The scan will run inside a custom "slim" Git Runner Container Instance - with base image built using ./Dockerfile
Implements: https://github.com/jfrog/log4j-tools
```
----

# Dockerzed `log4shell` Scanning

Automatically runs log4shell detection scan (implements: JFrog OSS Log4Shell Scanning Utilz) against the repository root (default)
or against a specified set of repository subdirectories passed as input (map) and create a new issue in repo on vulnerability found.
The scan will run inside a custom "slim" Git Runner Container Instance - with base image built using `actions/dockerized-log4shell-scan/Dockerfile`

## Configuration

## **ENVIRONMENT VARIABLE:** `DIRS_TO_SCAN` - **(FUTURE RELEASE - NOT IN USE YET)**

**Optional**

A space delimited list of repository **`RELATIVE`** subdirectories to **`INCLUDE`** in scan.

Default evaluates to: `"${{ env.GITHUB_WORKSPACE }}"`.

## Inputs

_NONE_

## Outputs

This action will create a New Issue in the source repository if any direct or indirect (transitive) vulnerabilities were discovered during the scan.

**NOTE:** For better visibility, you should configure the source repository to send email notifications or emit webhook events on New Issue creation.

See: [Github Docs - Configuring Notifications](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/configuring-notifications)

## Example usage in Workflow

```yaml
jobs:
  build:
    # what GitHub Hosted Runner (could be Self Hosted, Later) container base image to run on
    # See: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
    # TODO: Add ability to pass specific dirs for scan - this will require additional mods to scripts/runScan.sh!
    env:
      DIRS_TO_SCAN: "relative/sub/dir/num1 rel/sub/2"
    # Workflow Job Steps
    steps:

      # Use the Github default Checkout Action to checkout the repository to scan
      # See: https://github.com/actions/checkout#usage
      - name: Checkout Repository For Scanning
        uses: actions/checkout@v2
        with:
          repository: cbishop-elsevier/jenkins-log4shell-basecamp
          # this is a RELATIVE subdirectory BELOW env.GITHUB_WORKSPACE
          path: repo-to-scan

      # Use the Github default Checkout Action to checkout the scanning toolchain repository
      # See: https://github.com/jfrog/log4j-tools
      - name: Checkout Scanning Toolchain
        uses: actions/checkout@v2
        with:
          # this is the repository where the scanning toolchain assets should be obtained from
          repository: jfrog/log4j-tools
          # this is a RELATIVE subdirectory BELOW env.GITHUB_WORKSPACE
          path: repo-scan-tools

      # Setup custom Python 3.X environment on GitHub Hosted Runner Instance, cache all pip installed dependencies for better efficiency
      # See: https://github.com/actions/setup-python#usage
      - name: Config PyVE
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
          cache: 'pip'

      # Install Scan Toolchain Specific Dependencies
      - name: Instal Scan Toolchain Deps
        run: pip install -r repo-scan-tools/requirements.txt

      # Run Custom Bash Script
      - name: Run script file
        run: |
          chmod +x repo-to-scan/.github/workflows/scripts/runScan.sh
          repo-to-scan/.github/workflows/scripts/runScan.sh
```
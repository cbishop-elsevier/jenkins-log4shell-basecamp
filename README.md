## Knovel Jenkins `log4shell` Detection, Prevention, Mitigation Basecamp

<div style="width: 100%; display: inline-block; justify-content: center;">
<img alt="Willie Jenk!" width="280" src="assets/img/jenkins-willie-nelson.png" />
<img alt="Pesty Jenk!" width="250" src="assets/img/jenkins-pest-control.png" />
</div>

**This repository is intended to be a "container" for all notes, research, POCs, external and internal toolchains, etc - related to [Chris Bishop's](https://github.com/cbishop-elsevier "Github.com - cbishop-elsevier") Knovel Jenkins `log4shell` remediation work - NOT A SINGULAR SOURCE REPOSITORY TO BE BUILT AND RUN FROM ROOT!**

Solving the problem of `log4shell` within the context of Jenkins unfortunately isn't quite as simple as just running a simple filesystem `find /my/Java/Proj/Dir/lib -iname "log4j-core-2.*"` command and updating any discovered `jar, war, ear, sar` files in place to a non affected build of `log4j`.

We have to consider that Jenkins itself is SaaS / PaaS built on top of Java, it has its own DSL (domain specific language) implementation of Apache Groovy which also could be importing affected versions directly or indirectly through its ("transitive") dependencies, it has a complex plugin system built in by which some core components of Jenkins are imported (based on user specific CI server configuration), as well as what I consider to be the largest potential risk - **"third party plugins."** which can be implemented via Jenkins Jobs of all types (Pipeline, Declarative Pipeline, Matrix, Maven, etc) simplifying the build automation process for developers **at the cost of security, consistency, and standardization** across pipeline jobs. To make the plugins matter worse - anyone with access to modify Jenkins Pipeline Configuration files (`Jenkinsfile, Jenkinsfile.deploy`, etc.) in VCS can initiate install and implementation of plugins - **whether or not they have direct access and privileges to Jenkins Management Console** - simply by modifying the declarative pipeline job's configuration based on the way the Jenkins and Plugin developers have designed and integrated pipelines.

This effort to mitigate this problem in Jenkins is going to be an ongoing effort with lots of trial and error, testing, continued monitoring, etc required to continue beyond the scope and duration of just this initial Jira Story to mitigate.

- **JIRA: [PHN-40771 - Patch Jenkins Servers](https://elsevier.atlassian.net/browse/PHN-40771)**

It is therefore my honest opinion that the current `log4shell` remediation efforts taken in context with how many other existing known vulnerabilities that are known to exist in Jenkins Plugins (more scary are those we aren't aware of), highlights a much larger issue that I have been trying to raise awareness to for some time now - that the longer we continue to depend on self hosted and maintained Jenkins CI Server instances to perform our builds and deployments, the potential risk and liability those instances pose to the larger organization only grow exponentially.

----

### 23Dec2021 - CJB UPDATE - PROD Jenkins Post SCANS SUCCESS SUMMARY

- **PROD Jenkins** is **NOT** vulnerable either via direct or indirect (transitive) class references:

```bash
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools#
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools# python3 scan_log4j_calls_jar.py --class_existence --no_quickmatch /tmp/cjbtest/plugins-tmp/
Looking for presence of classes: .*log4j/Logger
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins-tmp/...
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 1/1 [00:00<00:00, 12.83it/s]
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools#
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools# python3 scan_log4j_calls_jar.py --class_regex ".*JndiManager$" --class_existence --no_quickmatch /tmp/cjbtest/plugins/
Looking for presence of classes: .*JndiManager$
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins/...
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 251/251 [00:27<00:00,  9.24it/s]
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools#
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools# python3 scan_log4j_calls_jar.py --class_regex ".*JndiLookup$" --class_existence --no_quickmatch /tmp/cjbtest/plugins/
Looking for presence of classes: .*JndiLookup$
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins/...
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 251/251 [00:29<00:00,  8.55it/s]
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools#
root@prod-us-east-1-jenkins-0:/tmp/cjbtest/log4j-tools#
```

----

### 21Dec2021 - CJB UPDATE - DEV Jenkins Post SCANS SUCCESS SUMMARY

- **JFrog Scanning Tools** were able to **COMPLETE SCANNING** for direct and indirect (transitive) references by Jenkins Plugins - Once could be run **off-peak** when DEV Jenkins usage at its lowest:
- **Most Relevant Scan Results Below:**
```bash
# the following scripts require install of the python3 dependencies in requirements.txt
pip3 install -r requirements.txt

# no specification of --class_regex "XXXXX" will use the default class regex: org/apache/logging/log4j/Logger
python3 scan_log4j_calls_jar.py --class_existence --no_quickmatch /tmp/cjbtest/plugins-tmp/

# specify --class_regex ".*JndiManager$" to report ANY reference to the Jndi Lookup class, regardless of the name of the class that implements it
python3 scan_log4j_calls_jar.py --class_regex ".*JndiManager$" --class_existence --no_quickmatch /tmp/cjbtest/plugins/
```

- **Direct Refs** to `log4j-core* , log4j-api*` classes
```bash
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]# python3 scan_log4j_calls_jar.py --class_existence --no_quickmatch /tmp/cjbtest/plugins/
Looking for presence of classes: org/apache/logging/log4j/Logger
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins/...



Processing .jar file:
checkmarx/WEB-INF/lib/log4j-api-2.13.3.jar

Classes found:
org/apache/logging/log4j/Logger
100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 906/906 [06:03<00:00,  2.49it/s]
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
```

- **Indirect Refs by ANY class to the `JndiManager , JndiLookup` classes**, which are the core of the vulnerability, to confirm **NO transitive vulnerabilities**
```bash
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]# python3 scan_log4j_calls_jar.py --class_regex ".*JndiManager$" --class_existence --no_quickmatch /tmp/cjbtest/plugins/
Looking for presence of classes: .*JndiManager$
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins/...



Processing .jar file:
checkmarx/WEB-INF/lib/log4j-core-2.13.3.jar

Classes found:
org/apache/logging/log4j/core/net/JndiManager
100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 906/906 [06:26<00:00,  2.35it/s]
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]# python3 scan_log4j_calls_jar.py --class_regex ".*JndiLookup$" --class_existence --no_quickmatch /tmp/cjbtest/plugins/
Looking for presence of classes: .*JndiLookup$
Scanning folder for .jar files
Walking /tmp/cjbtest/plugins/...



Processing .jar file:
checkmarx/WEB-INF/lib/log4j-core-2.13.3.jar

Classes found:
org/apache/logging/log4j/core/lookup/JndiLookup
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 906/906 [05:53<00:00,  2.57it/s]
[root@dev-us-east-1-jenkins-2-aws-lnx2 log4j-tools]#
```

- The **ONLY affected Plugin**:
  - [Jenkins Checkmarx Plugin](https://plugins.jenkins.io/checkmarx/)

- Checkmarx Plugin only used by the following 2 Jobs which have BOTH been failing consistently for more than 6 months.
  - https://jenkins-new.knewknovel.com/job/Sec-Analyze-API/
  - https://jenkins-new.knewknovel.com/job/Sec-Analyze-UI/
- **BOTH JOBS DISABLED**
- **PLUGIN UNINSTALLED**
- **JENKINS RESTARTED**
- **SUBSEQUENT `AFTER` SCANS `PASSED`**

### NEXT STEPS
- If all is well on Dev Jenkins over the rest of the week, we can schedule same efforts on PROD Jenkins
- Log additional stories for containerizing or Git Action adding these steps to run on regular schedule and send reports with results / findings

----

### Jenkins Official - Recommended Detection Method
- Jenkins.io Blog Post: [https://www.jenkins.io/blog/2021/12/10/log4j2-rce-CVE-2021-44228/](https://www.jenkins.io/blog/2021/12/10/log4j2-rce-CVE-2021-44228/)
- Per the above blog post's assertion (which parallels my own findings), Jenkins core classes themselves **are NOT** vulnerable - as Jenkins has its own purpose built Log Factory. The **bigger problem** however, are the vast Jenkins _"Official"_ and Third Party Plugins built for Jenkins integrations:
  - > **Log4j in Jenkins**
  - > The Jenkins security team has confirmed that Log4j is not used in Jenkins core. Jenkins plugins may be using Log4j ...
- Suggests performing the following:
  - Nav to: [https://jenkins-new.knewknovel.com/script](https://jenkins-new.knewknovel.com/script)
  - Enter the following class reference:
    - `org.apache.logging.log4j.core.lookup.JndiLookup.class.protectionDomain.codeSource`
  - Click **Run**
  - Below the script editor, you should receive results - you will see one of the following two options:
    - `groovy.lang.MissingPropertyException: No such property: org for class: Script1`
      - This means **None of the currently loaded plugins** that Jenkins has recently used (so are in its cache) have references to a `log4shell` vulnerable `log4j-core-2.X` version
    - `Result: (file:/var/lib/jenkins/plugins/checkmarx/WEB-INF/lib/log4j-core-2.13.3.jar <no signer certificates>)`
      - This is the **very first plugin with reference to vulnerable** `log4j-core-2.X` version, and the path on the filesystem to where the plugin is installed, including the location within the plugin's context where its offending `.jar` file exists. **IMPORTANT! THIS IS ONLY A SINGLE FINDING! THERE MAY BE MORE! THIS SCRIPT EDITOR APPROACH WILL EXIT UPON MAKING A SINGLE MATCH! WILL NEED TO CONTINUE TO RUN UNTIL RESULT LISTED IN THE FIRST OPTION IS RETURNED!**
- Need to find a simple way to automate the required iterative nature of the above. That automation has the following implications:
  - First, the above method will only ever return a single result at a time, so any automation needs to keep running until `groovy.lang.MissingPropertyException: No such property: org for class: Script1` result is returned
  - This script itself only reports on the very first match it finds, it **does NOT** take any sort of remediation action. Script will need additional lines of code (TBD) which at a minimum will disable, preferably uninstall any offending plugins found.
  - This approach will **only account for affected versions with an explicit filesystem .jar file object reference** - it **will not** account for 2nd or 3rd degree source imports where a plugin itself, or another plugin or library it references explicitly imports the source code or class files for a vulnerable `log4j-core-2.X..jar` file and exports within its own compiled class files or binaries. For those cases, we will need a better _"deep inspection"_ style scanning utility, like those provided by Jfrog, Lunasec, Snyk, etc. (those will come next)
- This approach may net us some quick wins initially while I am working out better options, but will **NOT** be sufficient on its own.
  - Jenkins CLI Commands: [https://jenkins-new.knewknovel.com/cli/](https://jenkins-new.knewknovel.com/cli/)
  - Obtain your API Token first, by going to [https://jenkins-new.knewknovel.com/me/configure](https://jenkins-new.knewknovel.com/me/configure) , then create a temporary file local to your workspace directory called `./.jenkins-cli` , within goes a single line in the following format: `usrId:apiTkn`
  - Download the Jenkins CLI runnable `.jar` file from the target Jenkins Instance to local filesystem (generally, would only need to do this if it does not already exist)
  ```bash
  wget -O "jenkins-cli.jar" http://localhost:8080/jnlpJars/jenkins-cli.jar
  ```
  - Testing with Jenkins CLI from `dev-us-east-1-jenkins-2-aws-lnx2` command shell does however seem to work (sort of). I can run the recommended command so far only within the context of a `groovysh` interactive command shell session started with the Jenkins CLI. Would be better if I could just use the `groovy` script command alias itself. Either way, since this command only returns one result at a time until you take remediation steps on that first match it makes anyway - if I have to start an interactive groovy shell to obtain the info I need, take mitigation action on that single file, terminate the interative groovy shell, rinse, repeat from my larger automation script - so be it.

  ```bash
  [root@dev-us-east-1-jenkins-2-aws-lnx2 cjbtest]#
  [root@dev-us-east-1-jenkins-2-aws-lnx2 cjbtest]# java -jar jenkins-cli.jar -s "http://localhost:8080/" -http -auth @.jenkins-cli groovysh
  Groovy Shell (2.4.12, JVM: 1.8.0_192)
  Type ':help' or ':h' for help.
  -------------------------------------------------------------------------------
  groovy:000> org.apache.logging.log4j.core.lookup.JndiLookup.class.protectionDomain.codeSource
  ===> (file:/var/lib/jenkins/plugins/checkmarx/WEB-INF/lib/log4j-core-2.13.3.jar <no signer certificates>)
  groovy:000>
  ```

  - **WORKS!**
  - Ref: [https://support.cloudbees.com/hc/en-us/articles/217509228-Execute-Groovy-script-in-Jenkins-remotely](https://support.cloudbees.com/hc/en-us/articles/217509228-Execute-Groovy-script-in-Jenkins-remotely)
  - Bypass Jenkins CLI and run with the following:

  ```bash
  # create temporary groovy script file in local dir - this could be multi-lined if needed
  echo "org.apache.logging.log4j.core.lookup.JndiLookup.class.protectionDomain.codeSource" > testCommand.groovy;

  # Read in from external script file, test command with verbose logging enabled
  curl -d "script=$(cat testCommand.groovy)" -v --user `cat .jenkins-cli` http://localhost:8080/scriptText

  # or in our case, verbose logging not needed, and our command is only single line, so this works well
  curl -d "script=org.apache.logging.log4j.core.lookup.JndiLookup.class.protectionDomain.codeSource" --user `cat .jenkins-cli` http://localhost:8080/scriptText

  # EXAMPLE OUTPUT:
  # [root@dev-us-east-1-jenkins-2-aws-lnx2 cjbtest]# curl -d "script=org.apache.logging.log4j.core.lookup.JndiLookup.class.protectionDomain.codeSource" --user `cat .jenkins-cli` http://localhost:8080/scriptText
  # Result: (file:/var/lib/jenkins/plugins/checkmarx/WEB-INF/lib/log4j-core-2.13.3.jar <no signer certificates>)
  # [root@dev-us-east-1-jenkins-2-aws-lnx2 cjbtest]#
  ```

  - So then, we can parse the filepath out from the response, take remediation action on it via parent calling script (zip it up, rename to something else, etc) and try running the command again to see if the output changes or not. May require a reboot of Jenkins Web Service in between to clear the already loaded plugin out of its runtime context - that would be an issue if we have a ton of them and have to reboot over and over again...

### Jenkins Jira - List of Known Affected Plugins Stories
- [https://issues.jenkins.io/browse/JENKINS-67361?jql=labels%20%3D%20CVE-2021-44228](https://issues.jenkins.io/browse/JENKINS-67361?jql=labels%20%3D%20CVE-2021-44228)

### JenkinsCI - Plugin Usage Plugin
- We have a **TON** of Jenkins "official" and 3rd party plugins installed on our Dev and Prod Jenkins Servers. We really need to determine whether they are used or not and remove any that aren't in use
- Plugin Usage Plugin Docs: [https://plugins.jenkins.io/plugin-usage-plugin/](https://plugins.jenkins.io/plugin-usage-plugin/)
- Plugin Usage Plugin Git: [https://github.com/jenkinsci/plugin-usage-plugin](https://github.com/jenkinsci/plugin-usage-plugin)
- PUP API Usage PR: [https://github.com/jenkinsci/plugin-usage-plugin/pull/18](https://github.com/jenkinsci/plugin-usage-plugin/pull/18)
- PUP API Example:
  - Note - the URL below returns JSON without issue when run in the browser with active authenticated session already existing in another tab.
    - `https://jenkins-new.knewknovel.com/pluginusage/api/json?tree=jobsPerPlugin[plugin[shortName],projects[fullName]]`
  - To run via cmd line on Jenkins host with cURL would need to handle auth by adding `userId:<API_TOKEN>` to URL for basic auth - something like the following:
    ```bash
    curl -X GET -H "Accept: text/json" https://userId:<API_TOKEN>.jenkins-new.knewknovel.com/pluginusage/api/json?tree=jobsPerPlugin[plugin[shortName],projects[fullName]]
    ```

### Trusted Vendor Curated Scanning Toolchains:
- **Lunasec.io** - [https://github.com/lunasec-io/lunasec/tree/master/tools/log4shell](https://github.com/lunasec-io/lunasec/tree/master/tools/log4shell)
  - Whats nice about these Lunasec curated tools is that they do not simply check the target filesystem based on string literal filenames for vulnerable versions, rather the Golang scripts perform SHA checksum calculations and lookup evaluation against a built in list of known SHA checksums for known vulnerable versions.
  - The list of SHA checksums for known vulnerable versions is contained within the following Golang source file, and could be exported / imported in to other toolchains / languages for use in combination with any other options I find which better meet our requirements:
    - [https://github.com/lunasec-io/lunasec/blob/master/tools/log4shell/constants/vulnerablehashes.go#L74-L135](https://github.com/lunasec-io/lunasec/blob/master/tools/log4shell/constants/vulnerablehashes.go#L74-L135)
  - The comments in this sourcefile give original attribution of the SHA checksum list to another trusted source (Mubix Git URL below), however the Lunasec.io Golang source file noted above has a more inclusive and extended list, so I only note the below txt file for reference / posterity:
    - [https://github.com/mubix/CVE-2021-44228-Log4Shell-Hashes/blob/main/sha256sums.txt](https://github.com/mubix/CVE-2021-44228-Log4Shell-Hashes/blob/main/sha256sums.txt)
  - Within later commits beyond the original head refs in this repository, Lunasec also included the SHA checksums along with other relevant metadata as an ORM to be used by later versions of their own tooling and to be easily sourced by anyone elses in the following Json file (Note the field `vulnerable_libraries[i].hash`):
    - [https://github.com/lunasec-io/lunasec/blob/master/tools/log4shell/log4j-library-hashes.json](https://github.com/lunasec-io/lunasec/blob/master/tools/log4shell/log4j-library-hashes.json)
- **JFrog.com**
  - Log4Shell Blog Post: [https://jfrog.com/press/jfrog-releases-oss-tools-to-identify-log4j-utilization-in-both-binaries-source-code/](https://jfrog.com/press/jfrog-releases-oss-tools-to-identify-log4j-utilization-in-both-binaries-source-code/)
  - Supporting Git Repo: [https://github.com/jfrog/log4j-tools](https://github.com/jfrog/log4j-tools)
    - **REVIEW IS WIP - MORE NOTES TO COME TOMORROW!**

### MISC - Other Tooling Which May Prove Useful Here or Elsewhere:
- GitHub Actions:
  - **GitHub Actions - AWS Actions:** [https://github.com/aws-actions](https://github.com/aws-actions)
  - **GitHub Actions - HashiCorp Terraform Actions:** [https://github.com/hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform)
- Serverless Framework:
  - **Serverless Framework - Examples:** [https://www.serverless.com/examples/](https://www.serverless.com/examples/)
  - **Serverless Framework - Git:** [https://github.com/serverless/examples](https://github.com/serverless/examples)

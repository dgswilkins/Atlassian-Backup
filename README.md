----

### update 16/3/2021
Automatic backup scheduling IS on Atlassian's list, although not in the very first horizon, as we are looking to completely overhaul the backup/restore experience.  Especially for those that have very large datasets.  With that said, there will be a mechanism available to automate this yourself, until we build that functionality into the UI. 

* https://community.atlassian.com/t5/Backup-Restore/gh-p/backupandrestore

Click the link, click request access, and we should get you in within 24 hours to review our strategy and provide feedback as we go. 

----

### DESCRIPTION

In here you find sample backup scripts for taking automatic Cloud backups. 

Please notice that the scripts in here are not officially supported and this project is currently community maintained. Make sure your read and understand what the provided scripts are doing before executing them.

For details see [How to Automate Backups for JIRA Cloud applications](https://confluence.atlassian.com/display/JIRAKB/How+to+Automate+Backups+for+JIRA+Cloud+applications).


### Alternative Solutions

In case the scripts in here don't fit your need, there are a number of alternative solution you can explore:

 - [PowerShell scripts by Sebastian Claesson](https://bitbucket.org/sebastianclaesson/atlassian-cloud-backup/src/master/backup/)
 - [CLI tool to manage backups for Atlassian Cloud sites by Steffen Müller](https://bitbucket.org/addcraftio/atlascloud-backup/src/master/) (based on Node.js, features OpsGenie integration and backup rotation)


Another option is to use [Automation for Jira](https://docs.automationforjira.com/), as explained in the Atlassian Community Article: [Automate online site-backups for Jira and Confluence without programming](https://community.atlassian.com/t5/Jira-articles/Automate-online-site-backups-for-Jira-and-Confluence-without/ba-p/1271317)


Please notice none of above solutions is officially supported.
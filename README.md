# Events Platform Scripts

This repository is meant for the scripts used for the Events Platform Team.

## Steps to request access to non-prod clusters on Confluent Cloud:

1. Clone the repo: `https://github.com/DigitalInnovation/events-platform-scripts.git`
2. Create a new branch.
3. Navigate to the `users.txt` file in the `scripts` folder.
4. Delete any existing entries.
5. Add new user email addresses (1 email address per line).
6. Raise a new Pull Request (PR) to merge the changes in your branch into the main branch. This PR will automatically notify the Events Platform team.
7. Once the PR is reviewed and merged by the Events Platform, this will kick-off the automated scripts and add the new users to all non-prod clusters.
8. By default, new users are provided cluster admin roles.
9. For requesting any additional or escalated role(s), please raise a Jira ticket explaining:
    1. Escalated Role required.
    2. Cluster you need the escalated role for; and
    3. The reason for the escalated role.
10. Please assign the above Jira ticket to any one of the below from the Events Platform Team:
    1. Abhilash.y.Nair@mnscorp.net
    2. Fraz.Ahmad@mnscorp.net
    3. Ushnish.Mukherjee@mnscorp.net
    4. Amit.Vij@mnscorp.net

Confluence Link: https://confluence.marksandspencer.app/display/CGE/Onboarding#Onboarding-Stepstorequestaccesstonon-prodclustersonConfluentCloud

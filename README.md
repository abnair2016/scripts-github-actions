# Github actions pipeline to add user accounts to all clusters in Confluent Cloud account

This is an automated github actions pipeline to add user accounts with CloudClusterAdmin access to all clusters in a specified Confuent Cloud account

## Add multiple users to Confluent Cloud account:

1. Clone the repo: `https://github.com/abnair2016/scripts-github-actions.git`
2. Create a new branch.
3. Navigate to the `users.txt` file in the `scripts` folder.
4. Delete any existing entries.
5. Add new user email addresses (1 email address per line).
6. Raise a new Pull Request (PR) to merge the changes in your branch into the main branch.
7. Once the PR is reviewed and merged, this will kick-off an automated pipeline to add the user to all the clusters in all the environments for the specified Confluent Cloud account.
8. By default, new users will be provided with `CloudClusterAdmin` role.
9. For roles like `OrganizationAdmin`, `EnvironmentAdmin` or `MetricsViewer` roles, please run the manual workflow instead by providing the email address or multiple email addresses separated by semi-colons and one of the aforementioned 3 roles

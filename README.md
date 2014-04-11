notes
=====

Gem to create release notes from git logs

### Getting Started
```
gem install https://github.com/vu-ngo/notes.git
```

### Running notes
- Change directory to your local git repository
- Generate a release note: `notes create --from=<previous-tag> --to=<latest-tag> --file=<html-file>`
- Send the release note: `notes sendmail --to=<send-to email> --file=<html-file>`

### Example
```
$ notes create --from=previous_git_tag --to=latest_git_tag
  create  release_notes.html
$ notes sendmail --to=vu_ngo@yahoo.com --subject="Daily release 2013/03/15 notes"
  Send to vu_ngo@yahoo.com
```

---
Run `notes usage` to see a list of all available commands

Various configuration setting defaults

            @logger = Logger.new(STDOUT)
            @logger.level = Logger:WARN
            @jira_auth_type = 'admin'
            @jira_password = 'password'
            @jira_url = 'https://jira.yourcompany.com'
            @jira_api_version = 'latest'
            @jira_auth_type = 'basic'


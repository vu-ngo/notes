module Notes
  class Helper
    require 'set'

    def self.configure_jira!
        return if @jira_configured
        Jiralicious.configure do |config|
          config.username = Notes.configuration.jira_user
          config.password = Notes.configuration.jira_password
          config.uri = Notes.configuration.jira_uri
          config.api_version = Notes.configuration.jira_api_version
          config.auth_type = Notes.configuration.jira_auth_type
        end
        @jira_configured = true
    end

    def self.configure_pivotal!
        return if @pivotal_configured
        PivotalTracker::Client.token = Notes.configuration.pivotal_token 
        PivotalTracker::Client.use_ssl = true

        @pivotal_projects = []

        @pivotal_projects << PivotalTracker::Project.find(Notes.configuration.pivotal_projects)
    end

    def self.determine_issue_type(id)
        :jira
    end

    def self.get_issue_summary(id)
        if self.determine_issue_type(id) == :jira
            self.configure_jira!
            Jiralicious::Issue.find(id).summary
        end
    end

    def self.github
      return @github if @github
      @github = Github.new endpoint: 'https://api.github.com', site: 'https://github.com'
    end

    def self.generate_email (from, to, user, repo)

      self.github
      self.configure_jira!
      self.configure_pivotal!

      #TODO move all of this stuff to a config somewhere
      commits = github.repos.commits.compare user, repo, from, to

      git_url = github.site
      git_url = git_url.gsub(/git\@github.com/, 'https://github.com')
      git_url = git_url.gsub(/github.com:/, 'github.com/')


      html = <<-EOS
      <pre>
      Previous: #{from}
      Latest: #{to}
      Link: #{git_url}/#{user}/#{repo}/compare/#{from}...#{to}
      </pre>
      EOS
      commit_rows = []
      jira_tickets = []
      pivotal_tickets = []
      jira_set = Set[]
      pull_requests = []

      commits.body.commits.collect do |c|
        message = c.commit.message
        message = message.sub(/(JIRA-\d+)/i,"<a href='https://wiki.yourcompany.com/browse/#{'\1'}'>#{'\1'}</a>")
        date     = c.commit.date
        sha      = c.sha
        short_sha= sha.slice(0, 7)
        sha_url  = "#{git_url}/#{user}/#{repo}/commit/#{sha}"
        author   = c.commit.author.name
        amail    = c.commit.author.email
        sha_link    = "<a href='#{sha_url}'>#{short_sha}</a>"
        author_link = "<a href='mailto:#{amail}'>#{author}</a>"
        if message =~ /Merge pull request #(\d+)/
          pull     = $1
          pull_url = "#{git_url}/#{user}/#{repo}/pull/#{pull}"
          message  = message.sub(/Merge pull request #\d+ from \S+\s*\n/, '')
          # append the pull request description to commit message
          if pull
            begin
              pull_request = github.pull_requests.get user, repo, pull
              description = pull_request.body_text
              if !(description && description.length > 0)
                  description = nil
              end
              message += ":\n " + ( description || "No description given")
            rescue NoMethodError
            end
          end
          pull_link   = "<a href='#{pull_url}'>#{pull}</a>"
          #Fields are Developer, Pull Request, Description, Sha
          pull_requests << [author_link, pull_link,message.gsub(/\n/,'<br>'),sha_link]
        else
          #Fields are Developer, Description, SHA
          commit_rows << [author_link, message.gsub(/\n/, '<br>'),sha_link]
        end

        #pull out jira tickets
        ticket = message.match(/TA-?(\d+)/i)
        if ticket
            project = 'TA'
            issue = ticket[1]
            ticket_id = "#{project}-#{issue}"
            if !jira_set.include?(ticket_id)
                begin
                    #Fields are Ticket, Summary
                    jira_tickets << ["<a href='https://wiki.yourcompany.com/browse/#{ticket_id}'>#{ticket_id}</a>",
                        self.get_issue_summary(ticket_id)]
                    jira_set.add(ticket_id)
                rescue
                    Notes.logger.warn  "Error fetching data from ticket #{ticket_id}"
                end
            end
        end

        ticket = message.match(/#(\d{8})/i)
        if ticket
            ticket = ticket[1]
            @pivotal_projects.each do |project|
                story = project.stories.find(ticket)
                if story
                    url = story.url
                    type = story.story_type
                    id = story.id

                    pivotal_tickets << [
                        type,
                        "<a href='#{url}'>#{id}</a>",
                        story.name
                    ]

                end
            end
        end
      end
      #generate rows
      unless jira_tickets.empty?
        html << self.make_table('jira_table', ['Ticket Number', 'Summary'], jira_tickets, 'Jira Tickets:')
      end

      unless pivotal_tickets.empty?
        html << self.make_table('pivotal_table', ['Type','Story', 'Description'], pivotal_tickets, 'Pivotal Stories:')
      end

      unless pull_requests.empty?
        html << self.make_table('pulls_table', ['Developer', 'Pull Request', 'Description', 'SHA'], pull_requests, 'Pull Requests:')
      end

      unless commit_rows.empty?
        html << self.make_table('commit_table', ['Developer', 'Description','SHA'], commit_rows, 'Commits:')
      end

      return html
    end

    def self.make_table (table_id, columns, data, intro)
      table_html = <<-EOS
      <h5>#{intro}</h5>
      <table id='#{table_id}' class='tablesorter' border='1' cellspacing='0' cellpadding='0' valign='top'>
      <thead style='text-align: center; white-space: nowrap'>
      <tr class='border-bottom'>
      EOS
      #Print table columns
      columns.each {|title| table_html << "<th>#{title}</th>" }
      table_html << "</thead>"
      table_html << "<tbody style='text-align: justify;'>"

      data.each { |row|
        table_html << "<tr>"
        row.each {|d| table_html << "<td>#{d}</td>"}
        table_html << "</tr>"
      }
      table_html << <<-EOS
      </tbody>
      </table>
      EOS
      return table_html
    end

    def self.sendmail(from, to, subject, text)

      Mail.defaults do
        delivery_method :smtp, :address => "mail.yourcompany.com"
      end
      mail = Mail.new do
        from    "#{from}"
        to      "#{to}"
        subject "#{subject}"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body  text
        end
      end
      mail.deliver
    end
  end
end

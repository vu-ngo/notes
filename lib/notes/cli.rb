module Notes
  class CLI < Thor
    include Thor::Actions

    desc "create", "Create a release notes and optionally send it"
    method_options from: :string, to: :string, file: "release_notes.html"
    def create
      from, to, file = options[:from], options[:to], options[:file]
      from = ask("Enter previous release tag:") unless from
      to   = ask("Enter latest release tag:") unless to
      raise Thor::Error, "Abort, --from or --to cannot be empty." if from.empty? or to.empty?
      org = 'vu-ngo'
      repo = 'web'

      html = Notes::Helper.generate_email(from, to, org, repo)

      create_file "#{file}" do
        html
      end
    end

    desc "usage", "The default task to run when no command is given"
    def usage
      puts ""
      puts "Usage: notes create --from=<previous tag> --to=<latest tag> [ --file=<notes html file> ]"
      puts "Usage: notes sendmail --to=<to email> --subject=<email subject> [ --file=<notes html file> ]"
      puts ""
    end

    desc "sendmail", "Send mail"
    method_options from: "vu_ngo@yahoo.com", to: :string, subject: :string, file: "release_notes.html"
    def sendmail
      from, to, subject, file = options[:from], options[:to], options[:subject], options[:file]
      to        = ask("Enter send-to email:") unless to
      subject   = ask("Enter send-to Subject:") unless  subject
      raise Thor::Error, "Abort, --to or --subject cannot be empty." if to.empty? or subject.empty?

      Notes::Helper.sendmail(from, to, subject, File.read(file))   
   end

    no_tasks do
      def open_git
        git = Git.open('.')
        git.fetch
        git.log.size # this will raise if not in git repo or no log
        git
      rescue ArgumentError
        say 'Not in git repo', :red
      rescue Git::GitExecuteError
        say 'No log found', :red
      end
    end

    default_task :usage

  end

end

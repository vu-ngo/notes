require "logger"
module Notes
    class << self
        attr_accessor :configuration, :logger, :config
    end

    def self.configure 
        self.config ||= Configuration.new
        yield(config) if block_given?
    end

    def self.configuration
        if self.config == nil
            self.configure
        end
        return self.config
    end

    def self.logger
        self.config.logger
    end

    class Configuration
        attr_accessor :logger, :jira_user, :jira_password, :jira_uri, :jira_api_version, :jira_auth_type, :pivotal_token, :pivotal_project_id
        
        def initialize 
            @logger = Logger.new(STDOUT)
            @logger.level = Logger::WARN
            @jira_user = 'admin'
            @jira_password = 'password'
            @jira_uri = 'https://jira.yourcompany.com'
            @jira_api_version = 'latest'
            @jira_auth_type = 'basic'
            @pivotal_token = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
            @pivotal_projects = 'xxxxx'
            @github_endpoint = 'https://api.github.com'
            @github_site = 'https://github.com'
        end
    end
end

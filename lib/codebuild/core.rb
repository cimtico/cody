require 'pathname'
require 'yaml'
require 'active_support/core_ext/string'

module Codebuild
  module Core
    extend Memoist

    def root
      path = ENV['CB_ROOT'] || '.'
      Pathname.new(path)
    end

    def env
      # 2-way binding
      cb_env = env_from_profile || 'development'
      cb_env = ENV['CB_ENV'] if ENV['CB_ENV'] # highest precedence
      ActiveSupport::StringInquirer.new(cb_env)
    end
    memoize :env

    def env_extra
      env_extra = ENV['CB_ENV_EXTRA'] if ENV['CB_ENV_EXTRA'] # highest precedence
      return if env_extra&.empty?
      env_extra
    end
    memoize :env_extra

    # Overrides AWS_PROFILE based on the Codebuild.env if set in configs/settings.yml
    # 2-way binding.
    def set_aws_profile!
      return if ENV['TEST']
      return unless File.exist?("#{Codebuild.root}/.codebuild/settings.yml") # for rake docs
      return unless settings # Only load if within Codebuild project and there's a settings.yml
      data = settings[Codebuild.env] || {}
      if data["aws_profile"]
        puts "Using AWS_PROFILE=#{data["aws_profile"]} from CB_ENV=#{Codebuild.env} in config/settings.yml"
        ENV['AWS_PROFILE'] = data["aws_profile"]
      end
    end

    def settings
      Setting.new.data
    end
    memoize :settings

    def check_codebuild_project!
      check_path = "#{Codebuild.root}/.codebuild"
      unless File.exist?(check_path)
        puts "ERROR: No .codebuild folder found.  Are you sure you are in a project with codebuild setup?".color(:red)
        puts "Current directory: #{Dir.pwd}"
        puts "If you want to set up codebuild for this prjoect, please create a settings file via: codebuild init"
        exit 1 unless ENV['TEST']
      end
    end

  private
    def env_from_profile
      Codebuild::Setting.new.cb_env
    end
  end
end

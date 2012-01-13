require 'clamp'

require 'pom2spec/logger'
require 'pom2spec/metadata'
require 'pom2spec/pom'
require "rexml/document"
require 'open-uri'

class CleanLog < Logger::Formatter
  # Provide a call() method that returns the formatted message.
  def call(severity, time, program_name, message)
    return message +"\n"
  end
end

# Initialize global logger
Pom2spec.logger = ::Logger.new(STDOUT)
Pom2spec.logger.datetime_format = "%Y-%m-%d %H:%M "
Pom2spec.logger.level = ::Logger::INFO
Pom2spec.logger.formatter = CleanLog.new
log = Pom2spec.logger

module Pom2spec

  class CommandBase < Clamp::Command
    def log
      Pom2spec.logger
    end
  end

  class GenerateCommand < Pom2spec::CommandBase

    parameter "GROUP", "group identifier"
    parameter "NAME", "artefact name"
    parameter "[VERSION]", "artefact version"

    def execute
      puts "hello"
      meta = Pom2spec::Metadata.new(group, name)

      versions = meta.versions

      pom = meta.pom_for(versions.first)
      puts pom

      #exit(0)
      if version
        unless versions.include?(version)
          log.fatal("requested version #{version} is not in metadata") and exit(1)
        end
      else
        log.info "call again and specify the exact version, one of:"
        versions.map { |x| " - #{x}"}.each do |x|
          log.info x
        end
        exit(1)
      end
    end
  end

  class MainCommand < Pom2spec::CommandBase

    self.description = %{
      pom2spec!!
    }

    option ["-d", "--debug"], :flag, "debug mode", :default => false

    def debug=(debug)
      Pom2spec.logger.level = ::Logger::DEBUG if debug
    end

    subcommand 'generate', 'Generate rpm sources for a given artefact', Pom2spec::GenerateCommand
  end

end
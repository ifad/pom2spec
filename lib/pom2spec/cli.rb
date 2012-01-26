require 'clamp'

require 'pom2spec/logger'
require 'pom2spec/maven_search'
require 'pom2spec/pom'
require 'pom2spec/spec_adapter'
require "rexml/document"
require 'open-uri'

class CleanLog < Logger::Formatter
  # Provide a call() method that returns the formatted message.
  def call(severity, time, program_name, message)
    return message +"\n"
  end
end

# Initialize global logger
Pom2spec.logger = ::Logger.new(STDERR)
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

    option ['-b', '--binary'], :flag, "Creates a binary package (sets suffix to -bin)"
    option ['-s', '--bootstrap'], :flag, "Creates a bootstrap package. Like binary but with -bootstrap suffix."    

    option ['-d', '--download'], :flag, 'Download referenced sources'
    option ['--[no-]legacy-symlinks'], :flag, 'Add symlinks to /usr/share/java', :default => true

    parameter "KEY", "artifact identifier (group:artifact-id[:version])"
    
    def execute
      pom_key = Pom::Key.new(key)
      meta = Pom2spec::MavenSearch.metadata_for(pom_key)

      versions = meta.versions

      if not pom_key.has_version?
        log.info "#{key} : using version #{meta.newest_version}"
      else
        unless versions.include?(pom_key.version)
          log.fatal("requested version #{version} is not in metadata")
          log.info "call again and specify the exact version, one of:"
          versions.map { |x| " - #{x}"}.each do |x|
            log.info x
          end
          exit(1)
        end
      end
      pom = Pom2spec::MavenSearch.pom_for(pom_key)

      adapter = Pom2spec::SpecAdapter.new(pom)

      if binary? && bootstrap?
        log.warn "binary can't be used together with bootstrap"
        return 1
      end

      adapter.binary = binary?
      adapter.legacy_symlinks = legacy_symlinks?

      filename = "#{adapter.name_with_suffix}.spec"
      log.info "Writing #{filename}"

      File.open(filename, "w") do |f|
        f << adapter.to_spec
      end

      log.info "Done"

      if download?
        system("/usr/lib/build/spectool --source --download *.spec")
      end

    end
  end

  class ScanRepositoryCommand < Pom2spec::CommandBase

    parameter "PATH", "Repository path" do |path|
      raise(ArgumentError, "#{path} does not exist") if not File.directory?(path)
      path
    end

    def execute

      Dir.glob(File.join(path, "/**/*.pom")).map do |pom_path|
        begin
          next Pom2spec::Pom.open(pom_path)
        rescue Exception => e
          log.error "Error when reading '#{pom_path}': #{e.message}"
        end
      end.map do |pom|
        "#{pom.group_id}:#{pom.artifact_id}"
      end.uniq.each do |key|
        puts key
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

    subcommand 'generate', 'Generate rpm sources for a given groupId:artifactId[:version] key', Pom2spec::GenerateCommand
    subcommand 'scan-repository', 'List groupId:artifactId[:version] keys in a repository', Pom2spec::ScanRepositoryCommand
  end

end
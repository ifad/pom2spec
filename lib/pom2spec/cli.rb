require 'clamp'

require 'pom2spec/logger'
require 'pom2spec/maven_search'
require 'pom2spec/pom'
require 'pom2spec/spec_adapter'
require 'pom2spec/multi_package_spec_adapter'
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

    option ['-j', '--jpp'], :flag, "Adds metadata for jpp repositories"    
    option ['-f', '--fmvn'], :flag, "Adds metadata for fmvn repositories"    

    option ['-d', '--download'], :flag, 'Download referenced sources'
    option ['--[no-]legacy-symlinks'], :flag, 'Add symlinks to /usr/share/java', :default => true
    option ['-n', '--package-name'], 'NAME', 'name for the package. Only used for multiple artifacts', :default => nil
    option ['-p', '--pom-file'], 'POMFILE', 'pom.xml local path. Will skip search on maven repo.', :default => nil

    parameter "KEY ...", "artifact identifiers (group:artifact-id[:version])"
    
    def execute

      adapters = []

      key_list.each do |key|

        pom_key = Pom::Key.new(key)

        unless pom_file
        begin
          meta = Pom2spec::MavenSearch.metadata_for(pom_key)

          versions = meta.versions

          if not pom_key.has_version?
            log.info "#{key} : using version #{meta.newest_version}"
          else
            unless versions.include?(pom_key.version)
              log.warn("requested version #{pom_key.version} is not in metadata")
              log.warn "Server reports available versions:"
              versions.map { |x| " - #{x}"}.each do |x|
                log.warn x
              end
            end
          end
        rescue Exception => e
          if pom_key.has_version?
            log.warn e.message
          else
            log.error e.message
            log.error "... and version not specified. Please specify version."
            return 1
          end
        end
        end

        pom = Pom2spec::MavenSearch.pom_for(pom_key, pom_file)

        adapter = Pom2spec::SpecAdapter.new(pom, :binary => binary?,
          :bootstrap => bootstrap?, :jpp => jpp?, :fmvn => fmvn?)

        adapter.legacy_symlinks = legacy_symlinks?

        adapters << adapter
      end

      target = case 
        when adapters.size > 1 then MultiPackageSpecAdapter.new(adapters,
          :binary => binary?, :bootstrap => bootstrap?, :jpp => jpp?, :fmvn => fmvn?)
        else adapters.first
      end

      if package_name
        target.name = package_name
      end

      target.write_files(Dir.pwd)
      
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
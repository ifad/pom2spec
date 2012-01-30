require 'erb'
require 'uri'

module Pom2spec

  class MultiPackageSpecAdapter

    attr_writer :name
    attr_accessor :pkgs

    def initialize(pkgs, opts={})
      @pkgs = pkgs
    end

    def name
      @name ? @name : "example"
    end

    def name_suffix
      @pkgs.map(&:name_suffix).select do |x|
        x
      end.first
    end

    def name_with_suffix
      "#{name}#{name_suffix}"
    end

    def version
      "0.1"
    end

    def license
      pkgs.map(&:license).uniq.join(" and ")
    end

    def summary
      "Bootstrap package"
    end

    def description
      "Bootstrap package for #{pkgs.map(&:name).join(", ")}"
    end

    # @return True 
    # information
    def legacy_symlinks?
      pkgs.map(&:"legacy_symlinks?").any?
    end

    def to_spec
      template_path = File.join(File.dirname(__FILE__), 'templates', 'multi.erb')
      template = File.read(template_path)
      message = ERB.new(template, 0, "<>")
      message.result(binding)
    end

    def write_spec_file(path)
      filename = File.join(path, "#{name_with_suffix}.spec")
      Pom2spec.logger.info "Writing #{filename}"

      File.open(filename, "w") do |f|
        f << to_spec
      end
      Pom2spec.logger.info "Done"
    end

    def write_files(path)
      write_spec_file(path)
      pkgs.each do |pkg|
        pkg.write_metadata_files(path)
      end
    end

  end

end
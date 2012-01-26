require 'erb'
require 'uri'

module Pom2spec

  class SpecAdapter

    LICENSE_FIX_FILE_URL = 'https://github.com/openSUSE/obs-service-format_spec_file/blob/master/licenses_changes.txt'
    LOCAL_MAVEN_REPOSITORY = '%{_datadir}/maven/repository/'

    attr_reader :pom

    attr_writer :name

    # If set, BuildRequires will not be
    # added to the spec file
    attr_writer :binary

    # @return True is the spec will not build
    # from source.
    #
    # This means no BuildRequires will be added
    # to the spec.
    def binary?
      @binary
    end

    # @return True 
    # information
    def legacy_symlinks?
      @legacy_symlinks
    end

    attr_writer :name_suffix
    attr_writer :legacy_symlinks

    @@license_table = Hash.new
    # Load licenses
    open(LICENSE_FIX_FILE_URL) do |f|
      f.each_line do |line|
        spdx, orig = line.split(' ', 2)
        @@license_table[orig] = spdx
      end
    end

    def initialize(pom, opts={})
      @pom = pom
      
      opts[:binary] ||= false
      @binary = opts[:binary]
    end

    def name
      @name ? @name : pom.artifact_id
    end

    def name_suffix
      return @name_suffix if @name_suffix
      return '-bin' if binary?
    end

    def name_with_suffix
      "#{name}#{name_suffix}"
    end

    def license
      orig = pom.licenses
      if @@license_table.has_key?(orig)
        return @@license_table[orig]
      end
      return "#{orig}"
    end

    def modules
      if not @modules
        @modules = pom.modules.map do |m|
          SpecAdapter.new(m, :binary => binary?)
        end
      end
      @modules
    end

    def summary
      pom.name
    end

    def description
      pom.description
    end

    def url_for(fmt)
      pom.url_for(fmt).gsub(/#{pom.version}/, "%{version}")
    end

    def install_path_for(fmt)
      LOCAL_MAVEN_REPOSITORY + File.join([*pom.group_id.split('.'), pom.artifact_id, File.basename(URI.parse(pom.url_for(fmt)).path)])
    end

    def to_spec

      template_path = File.join(File.dirname(__FILE__), 'templates', 'default.erb')
      template = File.read(template_path)
      puts template_path
      message = ERB.new(template, 0, "<>")
      message.result(binding)
    end

  end

end
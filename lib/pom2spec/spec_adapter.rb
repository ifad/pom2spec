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
      
      #opts[:binary] ||= false
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

    def url_for(fmt, opts={})
      opts = {:version_macro => true}.merge(opts)
      
      ret = pom.url_for(fmt)
      ret = ret.gsub(/#{pom.version}/, "%{version}") if opts[:version_macro]
      ret
    end

    def metadata_source_filename
      "#{pom.group_id}-#{pom.artifact_id}-metadata.xml"
    end

    def artifacts_base_install_path
      LOCAL_MAVEN_REPOSITORY + File.join([*pom.group_id.split('.'), pom.artifact_id])
    end

    def install_path_for(fmt)
      File.join([artifacts_base_install_path, pom.version, File.basename(URI.parse(pom.url_for(fmt)).path)])
    end

    def to_spec
      template_path = File.join(File.dirname(__FILE__), 'templates', 'default.erb')
      template = File.read(template_path)
      message = ERB.new(template, 0, "<>")
      message.result(binding)
    end

    def to_maven_metadata
      template_path = File.join(File.dirname(__FILE__), 'templates', 'maven-metadata.xml.erb')
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

    def write_metadata_files(path)
      [self, *self.modules].each do |mod|
        filename = mod.metadata_source_filename
        Pom2spec.logger.info "Writing #{filename}"

        File.open(filename, "w") do |f|
          f << mod.to_maven_metadata
        end
        Pom2spec.logger.info "Done"
      end
    end

    def write_files(path)
      write_spec_file(path)
      write_metadata_files(path)      
    end

  end

end
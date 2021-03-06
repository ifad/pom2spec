require 'erb'
require 'uri'

module Pom2spec

  class SpecAdapter

    LICENSE_FIX_FILE_URL = 'https://github.com/openSUSE/obs-service-format_spec_file/blob/master/licenses_changes.txt'
    FMVN_LOCAL_MAVEN_REPOSITORY = '%{_datadir}/maven/repository'
    JAVADIR = '%{_javadir}'
    POMDIR = '%{_mavenpomdir}'

    attr_reader :pom

    attr_writer :name

    # @return True is the spec will not build
    # from source.
    #
    # This means no BuildRequires will be added
    # to the spec.
    def binary?
      @binary
    end

    def bootstrap?
      @bootstrap
    end

    def fmvn?
      @fmvn
    end

    def jpp?
      @jpp
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
      
      opts = {:binary => false, :bootstrap => :false, :jpp => true, :fmvn => false}.merge(opts)

      #opts[:binary] ||= false
      @binary = opts[:binary] || opts[:bootstrap]
      @bootstrap = opts[:bootstrap]
      @jpp = opts[:jpp]
      @fmvn = opts[:fmvn]
    end

    def name
      @name ? @name : pom.artifact_id
    end

    def name_suffix
      return @name_suffix if @name_suffix
      return '-bootstrap' if bootstrap?
      return '-bin' if binary?
    end

    def name_with_suffix
      "#{name}#{name_suffix}"
    end

    def version
      pom.version
    end

    def url
      pom.url.strip
    end

    def group
      "Development/Languages/Java"
    end

    def license
      orig = pom.licenses
      return "FIXME" if not orig
      if @@license_table.has_key?(orig)
        return @@license_table[orig]
      end
      return "#{orig}"
    end

    def modules
      if not @modules
        @modules = pom.modules.map do |m|
          SpecAdapter.new(m, :binary => binary?, :jpp => jpp?, :fmvn => fmvn?)
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

    def fmvn_metadata_source_filename
      "#{pom.group_id}-#{pom.artifact_id}-metadata.xml"
    end

    def fmvn_artifacts_base_install_path
      FMVN_LOCAL_MAVEN_REPOSITORY + "/" + File.join([*pom.group_id.split('.'), pom.artifact_id])
    end

    def fmvn_install_path_for(fmt)
      File.join([fmvn_artifacts_base_install_path, pom.version, File.basename(URI.parse(pom.url_for(fmt)).path)])
    end

    def install_path_for(fmt)
      case fmt
      when :jar then File.join(JAVADIR, "#{name}.jar")
      when :pom then File.join(POMDIR, "JPP-#{name}.pom")
      else raise "Unknown format #{fmt}"
      end
    end

    def symlinks
      links = []
      if fmvn?
        links << [install_path_for(:jar), fmvn_install_path_for(:jar)]
        links << [install_path_for(:pom), fmvn_install_path_for(:pom) ]
      end
      links
    end

    def owned_directories
      dir = File.dirname(install_path_for(:pom))
      dirs = []
      while dir != LOCAL_MAVEN_REPOSITORY
        dirs << dir
        dir = File.dirname(dir)
      end
      dirs << LOCAL_MAVEN_REPOSITORY
      dirs << File.dirname(LOCAL_MAVEN_REPOSITORY) if bootstrap?
      dirs
    end

    def to_spec
      template = case
        when jpp? then 'jpp.erb'
        when fmvn? then 'fmvn.erb'
        else raise "Select either jpp or fmvn"
      end
      template_path = File.join(File.dirname(__FILE__), 'templates', 'jpp.erb')
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
      if fmvn?
        [self, *self.modules].each do |mod|
          filename = mod.fmvn_metadata_source_filename
          Pom2spec.logger.info "Writing #{filename}"

          File.open(filename, "w") do |f|
            f << mod.to_maven_metadata
          end
          Pom2spec.logger.info "Done"
        end
      end
    end

    def write_files(path)
      write_spec_file(path)
      write_metadata_files(path)      
    end

  end

end
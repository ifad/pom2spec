require 'open-uri/cached'
require 'rexml/document'
require 'pom2spec/maven_search'

module Pom2spec

  # A Maven project descriptor
  class Pom

    # Helper class to parse keys, we use it internally
    # but APIs get strings
    class Key 
      attr_accessor :artifact_id, :group_id, :version

      def initialize(*args)
        case args.size
          when 1
            case args[0]
              when Key
                @group_id = args[0].group_id
                @artifact_id = args[0].artifact_id
                @version = args[0].version
              else
                # g:a:v
                @group_id, @artifact_id, @version = args[0].to_s.split(":", 3)
            end 
          when 2
            @group_id, @artifact_id = args[0], args[1]
          when 3
            @group_id, @artifact_id, @version = args[0], args[1], args[2]
          else raise(ArgumentError, 'Unknown number of arguments')
        end

        raise(ArgumentError, 'group_id and artifact_id are required') if not valid?

      end

      def valid?
        group_id && artifact_id
      end

      def has_version?
        !@version.nil?
      end

      def to_s_without_version
        "#{group_id}:#{artifact_id}"
      end

      def to_s
        ret = to_s_without_version
        if has_version?
          ret = "#{ret}:#{version}"
        end
        ret
      end
    end

    # @param [String] url url or path
    def self.open(url)
      #Pom2spec.logger.info "Reading pom from '#{url}'"
      Pom.new(Kernel::open(url))
    end

    # Constructs a POM
    # @param [IO] io pom file
    def initialize(io)
      @doc = Nokogiri::XML(io)
    end

    def key
      Pom::Key.new(group_id, artifact_id, version)
    end

    def parent
      return @parent if @parent
      if not @doc.xpath("/xmlns:project/xmlns:parent").empty?
        a = @doc.xpath("/xmlns:project/xmlns:parent/xmlns:artifactId").text.to_s
        g = @doc.xpath("/xmlns:project/xmlns:parent/xmlns:groupId").text.to_s
        v = @doc.xpath("/xmlns:project/xmlns:parent/xmlns:version").text.to_s
        @parent = MavenSearch.pom_for(Pom::Key.new(g, a, v))
        return @parent
      end
      nil
    end

    # @return [String] packaging for this project
    def packaging
      node = @doc.xpath("/xmlns:project/xmlns:packaging")
      node.empty? ? 'jar' : node.text
    end

    def module_names
      return [] if packaging != 'pom'
      @doc.xpath("/xmlns:project/xmlns:modules/xmlns:module").map(&:text)    
    end

    # @return [Array<Pom>] Modules for this project, if packaging is of pom type
    def modules
      module_names.map do |name|
        MavenSearch.pom_for(Pom::Key.new(group_id, name))
      end
    end

    # @return [String] the group id for the project
    def group_id
      project_attribute('groupId')
    end

    # @return [String] id for the artifact
    def artifact_id
      @doc.xpath("/xmlns:project/xmlns:artifactId").text
    end 

    # @return [String] artifact's version
    def version
      project_attribute("version")
    end

    # @return [String] license description
    def licenses
      elements = @doc.xpath('/xmlns:project/xmlns:licenses//xmlns:name')
      return elements.to_a.join(",") if not elements.empty?
      parent_licenses = parent.licenses
      return parent_licenses if parent_licenses
      nil
    end

    # @return [String] project's url
    def url
      project_attribute("url")
    end

    # @return [String] artifact description
    def description
      project_attribute("description")
    end

    # @return [String] artifact name
    def name
      project_attribute("name")
    end

    # @return [String] attribute project/attrname
    # @visibility private
    def project_attribute(name)
      value = @doc.xpath("/xmlns:project/xmlns:#{name}").first
      return expand_properties(value.text) if value
      return parent.project_attribute(name) if parent
      raise "Attribute #{name} not defined in project and no parent to ask for it"
    end

    def project_array_attribute(name)
      elements = @doc.xpath("/xmlns:project/xmlns:#{name}").map(&:text)
      return parent.project_array_attribute(name) if parent
      raise "Attribute #{name} not defined in project and no parent to ask for it"
    end

    # return [Array<ArtifactIdentifier>] artifact dependencies
    def dependencies
      @doc.xpath("/xmlns:project/xmlns:dependencies/xmlns:dependency").map do |dep|
        Key.new(dep.xpath('./xmlns:groupId').text,
                dep.xpath('./xmlns:artifactId').text,
                expand_properties(dep.xpath('./xmlns:version').text))
      end
    end

    # @return [String] return property of given name. Looks in parent if
    #   not defined. 
    def property(name)
      element = @doc.xpath("/xmlns:project/xmlns:properties/xmlns:#{name}")
      ret = nil
      if element
        return element.text.to_s
      end
      return parent.property(name) if parent
      nil
    end

    def expand_properties(text)
      ret = text.gsub(/\$\{([a-zA-Z1-9\.]+)\}/) do
        "#{property($1)}"
      end
      case ret =~ /\$\{([a-zA-Z1-9\.]+)\}/
        when true then expand_properties(ret)
        else ret
      end
    end

    def url_for(fmt)
      MavenSearch.artifact_url_for(Key.new(group_id, artifact_id, version), fmt)
    end

  end
end
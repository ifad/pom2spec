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

      def to_s
        ret = "#{group_id}:#{artifact_id}"
        if has_version?
          ret = "#{ret}:#{version}"
        end
        ret
      end
    end

    # @param [String] url url or path
    def self.open(url)
      Pom2spec.logger.info "Reading pom from '#{url}'"
      Pom.new(Kernel::open(url))
    end

    # Constructs a POM
    # @param [IO] io pom file
    def initialize(io)
      @doc = REXML::Document.new(io)
    end

    def parent
      return @parent if @parent
      if @doc.elements["/project/parent"]
        a = @doc.elements["/project/parent/artifactId"].text.to_s
        g = @doc.elements["/project/parent/groupId"].text.to_s
        v = @doc.elements["/project/parent/version"].text.to_s
        @parent = MavenSearch.pom_for(Pom::Key.new(g, a, v))
        return @parent
      end
      nil
    end

    # @return [String] packaging for this project
    def packaging
      node = @doc.elements["/project/packaging"]
      node ? node.text : 'jar'
    end

    def module_names
      project_array_attribute("modules")
    end

    def modules
    end

    # @return [String] the group id for the project
    def group_id
      @doc.elements["/project/groupId"].text
    end

    # @return [String] id for the artifact
    def artifact_id
      @doc.elements["/project/artifactId"].text
    end 

    # @return [String] artifact's version
    def version
      project_attribute("version")
    end

    # @return [String] license description
    def licenses
      elements = @doc.elements['/project/licenses//name']
      return elements.to_a.join(",") if elements
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
      value = @doc.elements["/project/#{name}"]
      return expand_properties(value.text) if value
      return parent.project_attribute(name) if parent
      raise "Attribute #{name} not defined in project and no parent to ask for it"
    end

    def project_array_attribute(name)
      elements = @doc.elements["/project/#{name}"]  
      return elements.select do |x| 
        !x.is_a?(REXML::Text)
      end.map(&:text) if elements
      return parent.project_array_attribute if parent
      raise "Attribute #{name} not defined in project and no parent to ask for it"
    end

    # return [Array<ArtifactIdentifier>] artifact dependencies
    def dependencies
      @doc.elements['/project/dependencies'].select do |x| 
        !x.is_a?(REXML::Text)
      end.map do |dep|
        Key.new(dep.elements['./groupId'].text, dep.elements['./artifactId'].text, dep.elements['./version'].text)
      end.map(&:to_s).map do |x|
        expand_properties(x)
      end
    end

    # @return [String] return property of given name. Looks in parent if
    #   not defined. 
    def property(name)
      element = @doc.elements["/project/properties/#{name}"]
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

  end
end
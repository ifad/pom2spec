require 'open-uri'
require 'rexml/document'

module Pom2spec

  class Pom

    attr_accessor :group_id, :artifact_id, :versions

    def initialize(url)
      Pom2spec.logger.info url
      f = open(url)
      @doc = REXML::Document.new(f)
    end

    def group_id
      @doc.elements["/project/groupId"].text
    end

    def artifact_id
      @doc.elements["/project/artifactId"].text
    end 

    def version
      @version = @doc.elements["/project/version"].text
    end

    def licenses
      elements = @doc.elements['/project/licenses//name']
      return elements.each.to_a.join(",") if elements
      nil
    end

    def url
      @doc.elements['/project/url'].text
    end

    def description
      @doc.elements['/project/description'].text
    end

    def name
      @doc.elements['/project/name'].text
    end

    def dependencies
      @doc.elements['/project/dependencies'].select do |x| 
        !x.is_a?(REXML::Text)
      end.map do |dep|
        ArtefactIdentifier.new(dep.elements['./groupId'].text, dep.elements['./artifactId'].text, dep.elements['./version'].text)
      end
    end

  end
end
require 'pom2spec'
require 'open-uri'

module Pom2spec

  class Metadata

    #REPO_URL = "http://search.maven.org/remotecontent?filepath="
    REPO_URL = "http://repo1.maven.org/maven2/"

    def initialize(group_id, artifact_id)
      
      pgroup = group_id.gsub(/\./, '/')
      @path = "#{pgroup}/#{artifact_id}"

      url = "#{REPO_URL}#{@path}/maven-metadata.xml"
      Pom2spec.logger.warn url
      f = open(url)
      @doc = REXML::Document.new(f)
      @group_id = @doc.elements["/metadata/groupId"].first
      @artifact_id = @doc.elements["/metadata/artifactId"].first

      Pom2spec.logger.warn "groupId in maven-metadata.xml file is #{@group_id}" if group_id != @group_id

      @versions = []
      @doc.elements["/metadata/versioning/versions"].elements.each('version') do |vel|
        versions << vel.text.to_s
      end
    end


    def pom_for(version)
      url = "#{REPO_URL}#{@path}/#{version}/#{@artifact_id}-#{version}.pom"
      return Pom.new(url)      
    end

    def versions
      @versions
    end

  end
end
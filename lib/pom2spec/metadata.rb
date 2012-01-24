require 'pom2spec'
require 'open-uri/cached'
#require 'rubygems'
require 'versionomy'

module Pom2spec

  class Metadata

    #REPO_URL = "http://search.maven.org/remotecontent?filepath="

    def self.open(url)
      Pom2spec.logger.info "Reading metadata from '#{url}'"
      Metadata.new(Kernel::open(url))
    end

    def initialize(io)
      @doc = REXML::Document.new(io)
    end

    def group_id
      @doc.elements["/metadata/groupId"].first
    end

    def artifact_id
      @doc.elements["/metadata/artifactId"].first
    end

    # @return [Array<String>] versions for +key+
    def versions
      Pom2spec.logger.warn "groupId in maven-metadata.xml file is #{group_id}" if group_id != @group_id

      versions = []
      @doc.elements["/metadata/versioning/versions"].elements.each('version') do |vel|
        versions << vel.text.to_s
      end
      versions
    end

    def newest_version
      versions.sort do |v1, v2|
        # FIXME add the maven schema to versionomy
        begin
          #Gem::Version.new(v1) <=> Gem::Version.new(v2)
          next Versionomy.parse(v1) <=> Versionomy.parse(v2)
        #rescue ArgumentError => e
        rescue Versionomy::Errors::ParseError => e
          #puts "#{v1} #{v2}"
          next 0
        end
      end.reverse.first
    end

  end
end
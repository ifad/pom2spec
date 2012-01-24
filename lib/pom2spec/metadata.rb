require 'pom2spec'
require 'open-uri/cached'
#require 'rubygems'
require 'versionomy'
require 'nokogiri'

module Pom2spec

  class Metadata

    #REPO_URL = "http://search.maven.org/remotecontent?filepath="

    def self.open(url)
      #Pom2spec.logger.info "Reading metadata from '#{url}'"
      Metadata.new(Kernel::open(url))
    end

    def initialize(io)
      @doc = Nokogiri::XML(io)
    end

    def group_id
      @doc.xpath("/metadata/groupId").text
    end

    def artifact_id
      @doc.xpath("/metadata/artifactId").text
    end

    # @return [Array<String>] versions for +key+
    def versions
      #Pom2spec.logger.warn "groupId in maven-metadata.xml file is #{group_id} vs #{@group_id}" if group_id != @group_id

      versions = []
      @doc.xpath("/metadata/versioning/versions/version").each do |vel|
        versions << vel.text
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
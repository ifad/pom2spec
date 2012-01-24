require 'pom2spec/metadata'

module Pom2spec

  class MavenSearch

    REPO_URL = "http://repo1.maven.org/maven2/"

    def self.metadata_for(key)
      key = Pom::Key.new(key)
      Pom2spec.logger.info key.to_s

      pgroup = key.group_id.gsub(/\./, '/')
      path = "#{pgroup}/#{key.artifact_id}"

      url = "#{REPO_URL}#{path}/maven-metadata.xml"
      Metadata.open(url)
    end

    def self.pom_for(key)
      key = Pom::Key.new(key)

      version = key.version
      if not key.has_version?
        meta = metadata_for(key)
        version = meta.newest_version
      end

      pgroup = key.group_id.gsub(/\./, '/')
      path = "#{pgroup}/#{key.artifact_id}"

      url = "#{REPO_URL}#{path}/#{version}/#{key.artifact_id}-#{version}.pom"
      return Pom.open(url)      
    end

  end

end

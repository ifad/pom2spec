require 'pom2spec/metadata'

module Pom2spec

  class MavenSearch

    REPO_URL = "http://repo1.maven.org/maven2/"

    def self.metadata_for(key)
      key = Pom::Key.new(key)

      pgroup = key.group_id.gsub(/\./, '/')
      path = "#{pgroup}/#{key.artifact_id}"

      url = "#{REPO_URL}#{path}/maven-metadata.xml"
      begin 
        return Metadata.open(url)
      rescue
        Pom2spec.logger.error "Can't download metadata for #{key} at '#{url}'"
        exit(1)
      end
    end

    def self.pom_for(key, url = nil)
      url ||= artifact_url_for(key, 'pom')
      begin 
        return Pom.open(url)
      rescue
        Pom2spec.logger.error "Can't download pom for #{key} at '#{url}'"
        exit(1)
      end
    end

    def self.artifact_url_for(key, fmt)
      key = Pom::Key.new(key)

      version = key.version
      if not key.has_version?
        meta = metadata_for(key)
        version = meta.newest_version
      end

      pgroup = key.group_id.gsub(/\./, '/')
      path = "#{pgroup}/#{key.artifact_id}"

      url = "#{REPO_URL}#{path}/#{version}/#{key.artifact_id}-#{version}.#{fmt}"
    end

  end

end

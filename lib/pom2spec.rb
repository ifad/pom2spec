require "pom2spec/version"
require "pom2spec/metadata"
require "pom2spec/artefact_identifier"
require "pom2spec/pom"
require 'logger'

module Pom2spec
  # Your code goes here...
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= ::Logger.new('/dev/null')
  end

  def logger
    Pom2spec.logger
  end
  
end

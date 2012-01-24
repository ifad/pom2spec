require "pom2spec/version"
require "pom2spec/metadata"
require "pom2spec/pom"
require "pom2spec/spec_adapter"
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

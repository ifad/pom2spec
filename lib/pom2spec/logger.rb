require 'logger'

module Pom2spec
  module Logger

    def self.logger=(logger)
      @logger = logger
    end

    def self.logger
      @logger ||= Logger.new('/dev/null')
    end

    def logger
      Logging.logger
    end

  end
end
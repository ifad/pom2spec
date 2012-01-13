$: << File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'pom2spec'

if ENV["DEBUG"]
  Pom2spec::Logging.logger = Logger.new(STDERR)
  Pom2spec::Logging.logger.level = Logger::DEBUG
end

def fixture(name)
  File.join(File.dirname(__FILE__), 'data', name)
end


require File.join(File.dirname(__FILE__), 'helper')

class Pom_test < Test::Unit::TestCase

  def test_pom
    pom = Pom2spec::Pom.new("/space/git/pom2spec/test/data/groovy-all-2.0.0-beta-1.pom")
    assert_equal nil, pom.licenses
    pom = Pom2spec::Pom.new("/space/git/pom2spec/test/data/vaadin-6.7.2.pom")
    assert_equal "Apache License Version 2.0", pom.licenses
  end

  def test_commons_pom
  	pom = Pom2spec::Pom.new(fixture("commons-logging-1.1.1.pom"))
  	assert_equal("http://commons.apache.org/logging", pom.url)
  	assert_equal("Commons Logging", pom.name)
  	assert_equal("1.1.1", pom.version)
  	assert_nil(pom.licenses)
  	assert_equal("commons-logging", pom.group_id)
  	assert_equal("commons-logging", pom.artifact_id)

  	assert_equal([], pom.dependencies)
  end
end

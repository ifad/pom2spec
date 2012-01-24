require File.join(File.dirname(__FILE__), 'helper')

class Pom_test < Test::Unit::TestCase

  def test_pom
    pom = Pom2spec::Pom.open("/space/git/pom2spec/test/data/groovy-all-2.0.0-beta-1.pom")
    assert_equal nil, pom.licenses
    pom = Pom2spec::Pom.new(open("/space/git/pom2spec/test/data/vaadin-6.7.2.pom"))
    assert_equal "Apache License Version 2.0", pom.licenses
  end

  def test_commons_pom
  	pom = Pom2spec::Pom.open(fixture("commons-logging-1.1.1.pom"))
  	assert_equal("http://commons.apache.org/logging", pom.url)
  	assert_equal("Commons Logging", pom.name)
  	assert_equal("1.1.1", pom.version)
  	assert_nil(pom.licenses)
  	assert_equal("commons-logging", pom.group_id)
  	assert_equal("commons-logging", pom.artifact_id)
    assert_equal('jar', pom.packaging)

    deps = ['junit:junit:3.8.1',
            'log4j:log4j:1.2.12',
            'logkit:logkit:1.0.1',
            'avalon-framework:avalon-framework:4.1.3',
            'javax.servlet:servlet-api:2.3']
  	assert_equal(deps, pom.dependencies.map(&:to_s))

    assert_equal('1.2', pom.property('maven.compile.source'))
    assert_equal('Hello 1.2 and ', pom.expand_properties('Hello ${maven.compile.source} and ${undefined}'))

    assert_kind_of(Pom2spec::Pom, pom.parent)
    assert_equal('commons-parent', pom.parent.artifact_id)
    assert_equal('org.apache.commons', pom.parent.group_id)
    assert_equal('5', pom.parent.version)

  end

  def test_pom_with_submodules
    pom = Pom2spec::Pom.open(fixture('surefire-2.11.pom'))
    assert_equal('pom', pom.packaging)
    modules = ["surefire-shadefire",
               "surefire-api",
              "surefire-booter",
              "surefire-providers",
              "maven-surefire-common",
              "maven-surefire-plugin",
              "maven-failsafe-plugin",
              "maven-surefire-report-plugin",
              "surefire-setup-integration-tests",
              "surefire-integration-tests"]
    assert_equal(modules, pom.module_names)
  end

  def test_key_helper

    key = Pom2spec::Pom::Key.new('org.foo.bar:bar')
    assert_equal 'org.foo.bar', key.group_id
    assert_equal 'bar', key.artifact_id
    assert_nil key.version
    assert !key.has_version?
    assert_equal 'org.foo.bar:bar', key.to_s

    # Construct from a key instead of String
    key = Pom2spec::Pom::Key.new(key)
    assert_equal 'org.foo.bar:bar', key.to_s

    key = Pom2spec::Pom::Key.new('org.foo.bar:bar:1.1.3')
    assert_equal 'org.foo.bar', key.group_id
    assert_equal 'bar', key.artifact_id
    assert_equal '1.1.3', key.version
    assert key.has_version?
    assert_equal 'org.foo.bar:bar:1.1.3', key.to_s


  end

end

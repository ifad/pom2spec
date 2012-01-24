require File.join(File.dirname(__FILE__), 'helper')

class SpecAdapter_test < Test::Unit::TestCase

  def test_adapter_basic

  	pom = Pom2spec::Pom.open(fixture("commons-logging-1.1.1.pom"))
    adapter = Pom2spec::SpecAdapter.new(pom)

    assert_equal adapter.name, pom.artifact_id

    adapter.name = "#{pom.artifact_id}"

    adapter.name_suffix = '-bin'
    assert_equal adapter.name, "#{pom.artifact_id}-bin"

    adapter.name = 'foo'
    assert_equal adapter.name, "foo-bin"

    puts adapter.to_spec
  end
end

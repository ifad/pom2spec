
module Pom2spec
 
  class ArtefactIdentifier

  	attr_accessor :name, :group_id, :version

  	def initialize(name, group_id, version=nil)
  	  @name = name
  	  @group_id = group_id
  	  @version = version
  	end

  	def has_version?
  	  !@version.nil?
  	end

  end
 
end
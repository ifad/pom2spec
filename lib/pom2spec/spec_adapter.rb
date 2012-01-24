require 'erb'

module Pom2spec

  class SpecAdapter

    attr_reader :pom

    attr_writer :name

    # If set, BuildRequires will not be
    # added to the spec file
    attr_writer :binary

    # @return True is the spec will not build
    # from source.
    #
    # This means no BuildRequires will be added
    # to the spec.
    def binary?
      @binary
    end

    attr_accessor :name_suffix

    def initialize(pom)
      @pom = pom
      @binary = false
    end

    def name
      ret = @name ? @name : pom.artifact_id
      "#{ret}#{name_suffix}"
    end

    def print_tree
      raise "Only"
    end

    def to_spec

      template = %q{
Name:     <%= name %>
Version:  <%= pom.version %>
Release:  0
License:  <%= pom.licenses ? pom.licenses : "FIXME" %>
Url:      <%= pom.url %>
Summary:  <%= pom.name %>

<% if binary? %>
<% pom.dependencies.each do |dep| %>
BuildRequires: java(<%= dep %>)
<% end %>
<% end %>
<% pom.dependencies.each do |dep| %>
Requires: java(<%= dep %>)
<% end %>

%description
<%= pom.description %>

      }
      message = ERB.new(template, 0, "<>")
      puts message.result(binding)
    end

  end

end
require 'erb'
require 'uri'

module Pom2spec

  class SpecAdapter

    LICENSE_FIX_FILE_URL = 'https://github.com/openSUSE/obs-service-format_spec_file/blob/master/licenses_changes.txt'

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

    # @return True is the spec will contain JPP
    # information
    def jpp?
      @jpp
    end

    attr_writer :name_suffix
    attr_writer :jpp

    @@license_table = Hash.new
    # Load licenses
    open(LICENSE_FIX_FILE_URL) do |f|
      f.each_line do |line|
        spdx, orig = line.split(' ', 2)
        @@license_table[orig] = spdx
      end
    end

    def initialize(pom, opts={})
      @pom = pom
      
      opts[:binary] ||= false
      @binary = opts[:binary]
    end

    def name
      @name ? @name : pom.artifact_id
    end

    def name_suffix
      return @name_suffix if @name_suffix
      return '-bin' if binary?
    end

    def name_with_suffix
      "#{name}#{name_suffix}"
    end

    def license
      orig = pom.licenses
      if @@license_table.has_key?(orig)
        return @@license_table[orig]
      end
      return "#{orig}"
    end

    def modules
      if not @modules
        @modules = pom.modules.map do |m|
          SpecAdapter.new(m, :binary => binary?)
        end
      end
      @modules
    end

    def summary
      pom.name
    end

    def description
      pom.description
    end

    def jar_url
      pom.jar_url.gsub(/#{pom.version}/, "%{version}")
    end

    def pom_url
      pom.pom_url.gsub(/#{pom.version}/, "%{version}")
    end

    def to_spec

      template = %q{
Name:     <%= name_with_suffix %>
Version:  <%= pom.version %>
Release:  0
License:  <%= license %>
Url:      <%= pom.url %>
Group:    Development/Libraries/Java
Summary:  <%= summary %>

<% [self, *modules].each_with_index do |modul, index| %>
# <%= modul.name_with_suffix %>
Provides: java(<%= pom.key.to_s_without_version %>)
<% if jpp? %>
Provides: mvn(<%= pom.key.to_s_without_version %>)
<% end %>
<% unless modul.pom.packaging == 'pom' %>
Source<%= index*10 + 0 %>:  <%= modul.jar_url %>
<% end %>
Source<%= index*10 + 1 %>:  <%= modul.pom_url %>
<% end %>

<% if name_with_suffix != name %>
Provides:  <%= name %>
<% end %>

<% unless binary? %>
<% pom.dependencies.each do |dep| %>
BuildRequires: java(<%= dep %>)
<% end %>
<% end %>
<% pom.dependencies.each do |dep| %>
Requires: java(<%= dep %>)
<% if jpp? %>
Requires: mvn(<%= dep %>)
<% end %>  
<% end %>

<% modules.each do |modul| %>
# <%= modul.name_with_suffix %>
<% if modul.name_with_suffix != modul.name %>
Provides:  <%= modul.name %>
<% end %>
<% modul.pom.dependencies.each do |dep| %>
Requires: java(<%= dep.to_s_without_version %>)
<% end %>
<% end %>


%description
<%= pom.description %>


%prep

%build

%install

# jars
install -d -m 0755 %{buildroot}%{_javadir}

<% [self, *modules].each_with_index do |modul, index| %>
<% unless modul.pom.packaging == 'pom' %>
install -m 644 %{SOURCE<%= index*10 + 0 %>} %{buildroot}%{_javadir}/<%= modul.name %>.jar  
<% end %>

<% end %>
<% if jpp? %>
# poms
install -d -m 755 %{buildroot}%{_mavenpomdir}

<% [self, *modules].each_with_index do |modul, index| %>
install -pm 644 %{SOURCE<%= index*10 + 1 %>} \
    %{buildroot}%{_mavenpomdir}/JPP-<%= modul.name %>.pom
<% unless modul.pom.packaging == 'pom' %>
%add_maven_depmap JPP-<%= modul.name %>.pom <%= modul.name %>.jar
<% end %>

<% end %>
<% end %>

%files
%defattr(-,root,root,0755)
%{_javadir}/*
<% if jpp? %>
%{_mavenpomdir}/*
<% end %>


      }

      message = ERB.new(template, 0, "<>")
      message.result(binding)
    end

  end

end
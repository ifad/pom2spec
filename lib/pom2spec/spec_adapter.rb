require 'erb'
require 'uri'

module Pom2spec

  class SpecAdapter

    LICENSE_FIX_FILE_URL = 'https://github.com/openSUSE/obs-service-format_spec_file/blob/master/licenses_changes.txt'
    LOCAL_MAVEN_REPOSITORY = '%{_datadir}/maven/repository/'

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

    # @return True 
    # information
    def legacy_symlinks?
      @legacy_symlinks
    end

    attr_writer :name_suffix
    attr_writer :legacy_symlinks

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

    def url_for(fmt)
      pom.url_for(fmt).gsub(/#{pom.version}/, "%{version}")
    end

    def install_path_for(fmt)
      LOCAL_MAVEN_REPOSITORY + File.join([*pom.group_id.split('.'), pom.artifact_id, File.basename(URI.parse(pom.url_for(fmt)).path)])
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

<% unless modul.pom.packaging == 'pom' %>
Source<%= index*10 + 0 %>:  <%= modul.url_for(:jar) %>
<% end %>
Source<%= index*10 + 1 %>:  <%= modul.url_for(:jar) %>
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

<% if legacy_symlinks? %>
install -d -m 0755 %{buildroot}%{_javadir}
<% end %>

<% [self, *modules].each_with_index do |modul, index| %>

<% unless modul.pom.packaging == 'pom' %>
%{__install} -Dm 644 %{SOURCE<%= index*10 + 0 %>} %{buildroot}<%= modul.install_path_for(:jar) %>

<% if legacy_symlinks? %>
%{__ln_s} <%= modul.install_path_for(:jar) %> %{buildroot}%{_javadir}/<%= modul.name %>.jar
<% end %>

<% end %>

<% end %>


# poms
<% [self, *modules].each_with_index do |modul, index| %>
%{__install} -Dpm 644 %{SOURCE<%= index*10 + 1 %>} %{buildroot}<%= modul.install_path_for(:pom) %>
<% end %>

%files
%defattr(-,root,root,0755)
%dir %{_datadir}/maven/repository
%{_datadir}/maven/repository/*
<% if legacy_symlinks? %>
%{_javadir}/*
<% end %>

      }

      message = ERB.new(template, 0, "<>")
      message.result(binding)
    end

  end

end
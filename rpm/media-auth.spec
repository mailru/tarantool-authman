Name: tarantool-media-auth
Version: 0.0.1
Release: 1
Summary: Tarantool auth module
Group: Applications/Databases
License: MAILRU

BuildArch: noarch
BuildRequires: git
Requires: tarantool >= 1.7.0
# Requires: tarantool-curl >= 2.2.6


%description
media-auth for tarantool

%prep
git clone ssh://git@stash.mail.ru:2222/portal/media-auth.git

%clean
rm -rf %{buildroot}/%{name}-%{version}

%install
install -d %{buildroot}%{_datarootdir}/tarantool/
install -m 0644 shard.lua %{buildroot}%{_datarootdir}/tarantool/

%files
%{_datarootdir}/*.lua
%doc README.md

%changelog
* Wen Feb 15 2017 0.0.1
- Initial version of the RPM spec
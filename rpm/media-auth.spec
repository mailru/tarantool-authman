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
git clone ssh://git@stash.mail.ru:2222/portal/media-auth.git %{_builddir}/%{name}-%{version}
rm -rf %{_builddir}/%{name}-%{version}/.git
rm -rf %{_builddir}/%{name}-%{version}/rpm


%define luapkgdir %{_datadir}/media-auth/

%install
rm -rf %{buildroot}/%{name}-%{version}

%{__mkdir_p} %{buildroot}/%{luapkgdir}/
cp -pR %{_builddir}/%{name}-%{version}/* %{buildroot}/%{luapkgdir}/


%clean
rm -rf $RPM_BUILD_ROOT


%files
%dir %{luapkgdir}
%{luapkgdir}/*.lua
%{luapkgdir}/model/*.lua
%{luapkgdir}/test/*.lua
%{luapkgdir}/util/*.lua
%{luapkgdir}/requirenments.txt
%doc %{luapkgdir}/README.md

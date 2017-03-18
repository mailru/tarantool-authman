Name: tarantool-auth
Version: 0.0.8
Release: 1
Summary: Tarantool auth module
Group: Applications/Databases
License: MAILRU

BuildArch: noarch
BuildRequires: git
Requires: tarantool >= 1.7.0
Requires: tarantool-curl >= 2.2.7


%description
auth lib for tarantool


%prep
%{__rm} -rf %{_builddir}/%{name}-%{version}

git clone ssh://git@stash.mail.ru:2222/portal/media-auth.git %{_builddir}/%{name}-%{version}

%define luapkgdir %{_datadir}/tarantool/auth

%install
rm -rf %{buildroot}/%{name}-%{version}

%{__mkdir_p} %{buildroot}/%{luapkgdir}/
cp -pR %{_builddir}/%{name}-%{version}/auth/* %{buildroot}/%{luapkgdir}/
cp -pR %{_builddir}/%{name}-%{version}/README.md %{buildroot}/%{luapkgdir}/README.md

%clean
rm -rf %{buildroot}


%files
%dir %{luapkgdir}
%dir %{luapkgdir}/model
%dir %{luapkgdir}/utils
%{luapkgdir}/*.lua
%{luapkgdir}/model/*.lua
%{luapkgdir}/utils/*.lua
%doc %{luapkgdir}/README.md

Name: tarantool-authman
Version: 1.0.0
Release: 1
Summary: Tarantool auth module
Group: Applications/Databases
License: BSD

URL: https://github.com/mailru/tarantool-authman
Source0: https://github.com/mailru/%{name}/archive/%{version}/%{name}-%{version}.tar.gz

BuildArch: noarch
Requires: tarantool >= 1.7.4.168

%description
auth lib for tarantool


%prep
%setup -q -n %{name}-%{version}

%define luapkgdir %{_datadir}/tarantool/authman

%install
rm -rf %{buildroot}/%{name}-%{version}

%{__mkdir_p} %{buildroot}/%{luapkgdir}/
cp -pR %{_builddir}/%{name}-%{version}/authman/* %{buildroot}/%{luapkgdir}/
cp -pR %{_builddir}/%{name}-%{version}/README.md %{buildroot}/%{luapkgdir}/README.md
cp -pR %{_builddir}/%{name}-%{version}/doc/ %{buildroot}/%{luapkgdir}/doc/


%clean
rm -rf %{buildroot}


%files
%dir %{luapkgdir}
%dir %{luapkgdir}/model
%dir %{luapkgdir}/utils
%{luapkgdir}/*.lua
%{luapkgdir}/model/*.lua
%{luapkgdir}/model/oauth/*.lua
%{luapkgdir}/model/oauth/consumer/*.lua
%{luapkgdir}/utils/*.lua
%{luapkgdir}/migrations/*.lua
%{luapkgdir}/oauth/*.lua
%doc %{luapkgdir}/README.md
%doc %{luapkgdir}/doc/*.md

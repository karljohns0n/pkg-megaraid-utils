Name:			megaraid-utils
Version:		1.8
Release:		2%{?dist}
Summary:		LSI megacli/storcli tools

Group:			Applications/System
License:		LSI Logic Corporation
URL:			http://www.lsi.com
Source0:		megacli-8.07.14
Source1:		storcli-1.23.02
Source2:		libstorelibir-2.so.14.07-0
Source3:		lsireport.sh
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires: mutt

%description
MegaCLI and StorCLI are used to manage SAS RAID controllers. It also includes a report scripts of your controller status.

%prep
%setup -q -c -T
%install

install -d -m 0755 $RPM_BUILD_ROOT/opt/megaraid
install -m 0700 %{SOURCE0} $RPM_BUILD_ROOT/opt/megaraid/megacli
install -m 0700 %{SOURCE1} $RPM_BUILD_ROOT/opt/megaraid/storcli
install -p -m 0644 %{SOURCE2} $RPM_BUILD_ROOT/opt/megaraid
install -p -m 0700 %{SOURCE3} $RPM_BUILD_ROOT/opt/megaraid

%clean
rm -rf $RPM_BUILD_ROOT

%post
if [ "$1" = "1" ];
then
	echo ""
	echo "Megacli and StorCLI have been installed. We recommend adding the following to your profile:"
	echo "alias megacli=\"/opt/megaraid/megacli\""
	echo "alias storcli=\"/opt/megaraid/storcli\""
	echo ""
fi

%files
%defattr(-,root,root,-)
%dir /opt/megaraid
/opt/megaraid/*

%changelog
* Thu Nov 30 2017 Karl Johnson <karljohnson.it@gmail.com> - 1.8-2
- Fix model name in lsireport.sh for recent LSI card.

* Thu Nov 30 2017 Karl Johnson <karljohnson.it@gmail.com> - 1.8-1
- Bump StorCLI to 1.23.02. Cleanup lsireport.sh script.

* Tue Apr 25 2017 Karl Johnson <kjohnson@aerisnetwork.com> - 1.7-1
- Bump StorCLI to 1.21.06. Add support for StorCLI in lsireport.sh script.

* Wed Nov 16 2016 Karl Johnson <kjohnson@aerisnetwork.com> - 1.6-1
- Bump StorCLI to 1.20.15. Enhance LSI script for SATA drives. 

* Thu Jan 14 2016 Karl Johnson <kjohnson@aerisnetwork.com> - 1.5-1
- Bump StorCLI to 1.18.05

* Fri Apr 24 2015 Karl Johnson <kjohnson@aerisnetwork.com> - 1.4-1
- Bump StorCLI to 1.15.05

* Mon Feb 02 2015 Karl Johnson <kjohnson@aerisnetwork.com> - 1.3-1
- Bump StorCLI to 1.14.12

* Mon Sep 22 2014 Karl Johnson <kjohnson@aerisnetwork.com> - 1.2-1
- Add StorCLI 1.13.06

* Mon Sep 22 2014 Karl Johnson <kjohnson@aerisnetwork.com> - 1.1-1
- Add lsireport.sh v1.0

* Wed Sep 17 2014 Karl Johnson <kjohnson@aerisnetwork.com> - 1.0-1
- First release with MegaCLI 8.07.14

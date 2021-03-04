;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014, 2015, 2019, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2016, 2021 Leo Famulari <leo@famulari.name>
;;; Copyright © 2017, 2018, 2019 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2019 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2020 Lars-Dominik Braun <ldb@leibniz-psychology.org>
;;; Copyright © 2020 Efraim Flashner <efraim@flashner.co.il>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages openldap)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module (gnu packages dbm)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages password-utils)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages rsync)
  #:use-module (gnu packages selinux)
  #:use-module (gnu packages time)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:select (openldap2.8 lgpl2.1+ gpl3+ psfl expat))
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python))

(define-public openldap
  (package
   (name "openldap")
   (replacement openldap-2.4.57)
   (version "2.4.50")
   (source (origin
             (method url-fetch)
             ;; See <http://www.openldap.org/software/download/> for a list of
             ;; mirrors.
             (uri (list (string-append
                         "ftp://mirror.switch.ch/mirror/OpenLDAP/"
                         "openldap-release/openldap-" version ".tgz")
                        (string-append
                         "https://www.openldap.org/software/download/OpenLDAP/"
                         "openldap-release/openldap-" version ".tgz")
                        (string-append
                         "ftp://ftp.dti.ad.jp/pub/net/OpenLDAP/"
                         "openldap-release/openldap-" version ".tgz")))
             (sha256
              (base32
               "1f46nlfwmys110j36sifm7ah8m8f3s10c3vaiikmmigmifapvdaw"))))
   (build-system gnu-build-system)
   (inputs `(("bdb" ,bdb-5.3)
             ("cyrus-sasl" ,cyrus-sasl)
             ("gnutls" ,gnutls)
             ("libgcrypt" ,libgcrypt)
             ("zlib" ,zlib)))
   (native-inputs `(("libtool" ,libtool)
                    ("groff" ,groff)
                    ("bdb" ,bdb-5.3)))
   (arguments
    `(#:tests? #f
      #:configure-flags
      '("--disable-static"
        ,@(if (%current-target-system)
              '("--with-yielding_select=yes"
                "ac_cv_func_memcmp_working=yes")
              '()))
      ;; Disable install stripping as it breaks cross-compiling.
      #:make-flags '("STRIP=")
      #:phases
      (modify-phases %standard-phases
        ,@(if (%current-target-system)
              '((add-before 'configure 'fix-cross-gcc
                  (lambda* (#:key target #:allow-other-keys)
                    (setenv "CC" (string-append target "-gcc"))
                    #t)))
              '())
        (add-after 'install 'patch-sasl-path
          ;; Give -L arguments for cyrus-sasl to avoid propagation.
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let ((out (assoc-ref outputs "out"))
                  (krb5 (assoc-ref inputs "mit-krb5"))) ;propagated from cyrus-sasl

              ;; The ancient Libtool bundled with OpenLDAP copies the linker flags
              ;; from Cyrus-SASL and embeds them into its own .la files.  Add an
              ;; absolute reference to Kerberos so it does not have to be propagated.
              (substitute* (map (lambda (f) (string-append out "/" f))
                                '("lib/libldap.la" "lib/libldap_r.la"))
                (("-lkrb5" lib)
                 (string-append "-L" krb5 "/lib " lib)))
              #t))))))
   (synopsis "Implementation of the Lightweight Directory Access Protocol")
   (description
    "OpenLDAP is a free implementation of the Lightweight Directory Access Protocol.")
   (license openldap2.8)
   (home-page "https://www.openldap.org/")))

(define-public openldap-2.4.57
  (package
    (inherit openldap)
    (version "2.4.57")
    (source (origin
              (method url-fetch)
              ;; See <http://www.openldap.org/software/download/> for a list of
              ;; mirrors.
              (uri (list (string-append
                          "ftp://mirror.switch.ch/mirror/OpenLDAP/"
                          "openldap-release/openldap-" version ".tgz")
                         (string-append
                          "https://www.openldap.org/software/download/OpenLDAP/"
                          "openldap-release/openldap-" version ".tgz")
                         (string-append
                          "ftp://ftp.dti.ad.jp/pub/net/OpenLDAP/"
                          "openldap-release/openldap-" version ".tgz")))
              (sha256
               (base32
                "0nmlyqhc52v24b4awh914sczmvxbazgq2cnlycvb9dgcwvhlgfn7"))))))

(define-public nss-pam-ldapd
  (package
    (name "nss-pam-ldapd")
    (version "0.9.11")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://arthurdejong.org/nss-pam-ldapd/"
                                  "nss-pam-ldapd-" version ".tar.gz"))
              (sha256
               (base32
                "1dna3r0q6sjhhlkhcp8x2zkslrd4y7701kk6fl5r940sdph1pmyh"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       (list (string-append "--with-pam-seclib-dir="
                            (assoc-ref %outputs "out") "/lib/security/")
             ;; nslcd cannot be convinced to look at run-time for its
             ;; configuration file at a location that differs from the
             ;; configured location.
             "--with-ldap-conf-file=/etc/nslcd.conf")
       #:phases
       (modify-phases %standard-phases
         ;; This is necessary because we tell nslcd with configure flags that
         ;; it should look for its configuration file at /etc/nslcd.conf.  The
         ;; build system tries to install a default configuration to that very
         ;; location.
         (add-after 'unpack 'override-nslcd.conf-install-path
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "Makefile.in"
               (("\\$\\(DESTDIR\\)\\$\\(NSLCD_CONF_PATH\\)")
                (string-append (assoc-ref outputs "out")
                               "/etc/nslcd.conf.example")))
             #t)))))
    (inputs
     `(("linux-pam" ,linux-pam)
       ("openldap" ,openldap)
       ("mit-krb5" ,mit-krb5)
       ("python" ,python)))
    (home-page "https://arthurdejong.org/nss-pam-ldapd")
    (synopsis "NSS and PAM modules for LDAP")
    (description "nss-pam-ldapd provides a @dfn{Name Service Switch} (NSS)
module that allows your LDAP server to provide user account, group, host name,
alias, netgroup, and basically any other information that you would normally
get from @file{/etc} flat files or NIS.  It also provides a @dfn{Pluggable
Authentication Module} (PAM) to do identity and authentication management with
an LDAP server.")
    (license lgpl2.1+)))

(define-public python-ldap
  (package
    (name "python-ldap")
    (version "3.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "python-ldap" version))
       (sha256
        (base32
         "198as30xy6p760niqps2zdvq2xcmr765h06pmda8fa9y077wl4a7"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'configure-openldap-locations
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((openldap (assoc-ref inputs "openldap")))
               (setenv "SLAPD"
                       (string-append openldap
                                      "/libexec/slapd"))
               (setenv "SCHEMA"
                       (string-append openldap
                                      "/etc/openldap/schema/")))
             #t)))))
    (inputs
     `(("openldap" ,openldap)
       ("cyrus-sasl" ,cyrus-sasl)
       ("mit-krb5" ,mit-krb5)))
    (propagated-inputs
     `(("python-pyasn1" ,python-pyasn1)
       ("python-pyasn1-modules" ,python-pyasn1-modules)))
    (home-page "https://www.python-ldap.org/")
    (synopsis "Python modules for implementing LDAP clients")
    (description
     "This package provides an object-oriented API to access LDAP directory
servers from Python programs.")
    (license psfl)))

(define-public 389-ds-base
  (package
    (name "389-ds-base")
    (version "1.4.0.31")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://releases.pagure.org/389-ds-base/"
                                  "389-ds-base-" version ".tar.bz2"))
              (sha256
               (base32
                "1rs218iqxyclccsdqb529favdsmz88zw785lsxd9ln43ja3x3l65"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((srfi srfi-1)
                  (guix build gnu-build-system)
                  ((guix build python-build-system)
                   #:select (python-version))
                  (guix build utils))
       #:imported-modules ((guix build python-build-system)
                           ,@%gnu-build-system-modules)
       #:configure-flags
       (list (string-append "--with-db="
                            (assoc-ref %build-inputs "bdb"))
             (string-append "--with-sasl="
                            (assoc-ref %build-inputs "cyrus-sasl"))
             (string-append "--with-netsnmp="
                            (assoc-ref %build-inputs "net-snmp"))
             (string-append "--with-pcre="
                            (assoc-ref %build-inputs "pcre"))
             (string-append "--with-selinux="
                            (assoc-ref %build-inputs "libselinux"))
             "--localstatedir=/var"
             "--with-instconfigdir=/etc/dirsrv"
             ;; The Perl scripts are being removed in the 1.4.0 release.
             ;; Building them would require packaging of the outdated Mozilla
             ;; LDAP SDK (instead of OpenLDAP) and PerLDAP.
             "--disable-perl")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-references
           (lambda _
             (substitute* "include/ldaputil/certmap.h"
               (("nss3/cert.h") "nss/cert.h"))
             (substitute* "src/lib389/lib389/nss_ssl.py"
               (("'/usr/bin/certutil'")
                (string-append "'" (which "certutil") "'"))
               (("'/usr/bin/c_rehash'")
                (string-append "'" (which "perl") "', '" (which "c_rehash") "'")))
             #t))
         (add-after 'unpack 'overwrite-default-locations
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (substitute* "src/lib389/lib389/paths.py"
                 (("/usr/share/dirsrv/inf/defaults.inf")
                  (string-append out "/share/dirsrv/inf/defaults.inf")))
               ;; This directory can only be specified relative to sysconfdir.  This
               ;; is used to determine where to look for installed directory
               ;; servers, so in the absence of a search path it needs to be global.
               (substitute* "ldap/admin/src/defaults.inf.in"
                 (("^initconfig_dir =.*")
                  "initconfig_dir = /etc/dirsrv/registry\n"))
               ;; This is used to determine where to write certificate files
               ;; when installing new directory server instances.
               (substitute* '("src/lib389/lib389/instance/setup.py"
                              "src/lib389/lib389/instance/remove.py")
                 (("etc_dirsrv_path = .*")
                  "etc_dirsrv_path = '/etc/dirsrv/'\n"))
               #t)))
         (add-after 'unpack 'fix-install-location-of-python-tools
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (pythondir (string-append
                                out "/lib/python"
                                (python-version (assoc-ref inputs "python"))
                                "/site-packages/")))
               ;; Install directory must be on PYTHONPATH.
               (setenv "PYTHONPATH"
                       (string-append (getenv "PYTHONPATH")
                                      ":" pythondir))
               ;; Install directory must exist.
               (mkdir-p pythondir)
               (substitute* "src/lib389/setup.py"
                 (("/usr") out))
               (substitute* "Makefile.am"
                 (("setup.py install --skip-build" m)
                  (string-append m " --prefix=" out
                                 " --root=/ --single-version-externally-managed"))))
             #t))
         (add-after 'build 'build-python-tools
           (lambda* (#:key make-flags #:allow-other-keys)
             ;; Set DETERMINISTIC_BUILD to override the embedded mtime in pyc
             ;; files.
             (setenv "DETERMINISTIC_BUILD" "1")
             ;; Use deterministic hashes for strings, bytes, and datetime
             ;; objects.
             (setenv "PYTHONHASHSEED" "0")
             (apply invoke "make" "lib389" make-flags)
             #t))
         (add-after 'install 'install-python-tools
           (lambda* (#:key make-flags #:allow-other-keys)
             (apply invoke "make" "lib389-install" make-flags)
             #t))
         (add-after 'install-python-tools 'wrap-python-tools
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out  (assoc-ref outputs "out"))
                    (path (getenv "PYTHONPATH")))
               (for-each (lambda (file)
                           (wrap-program (string-append out file)
                             `("PYTHONPATH" ":" prefix (,path))))
                         '("/sbin/dsconf"
                           "/sbin/dscreate"
                           "/sbin/dsctl"
                           "/sbin/dsidm"
                           "/bin/ds-logpipe.py"
                           "/bin/ds-replcheck"
                           "/bin/readnsstate")))
             #t)))))
    (inputs
     `(("bdb" ,bdb)
       ("cracklib" ,cracklib)
       ("cyrus-sasl" ,cyrus-sasl)
       ("gnutls" ,gnutls)
       ("httpd" ,httpd)
       ("icu4c" ,icu4c)
       ("libevent" ,libevent)
       ("libselinux" ,libselinux)
       ("linux-pam" ,linux-pam)
       ("mit-krb5" ,mit-krb5)
       ("net-snmp" ,net-snmp)
       ("nspr" ,nspr)
       ("nss" ,nss)
       ("nss:bin" ,nss "bin") ; for certutil
       ("openldap" ,openldap)
       ("openssl" ,openssl)             ; #included by net-snmp
       ("pcre" ,pcre)
       ("perl" ,perl)
       ("python" ,python)
       ("python-pyasn1" ,python-pyasn1)
       ("python-pyasn1-modules" ,python-pyasn1-modules)
       ("python-pytest" ,python-pytest)
       ("python-dateutil" ,python-dateutil)
       ("python-six" ,python-six)
       ("python-argcomplete" ,python-argcomplete)
       ("python-argparse-manpage" ,python-argparse-manpage)
       ("python-ldap" ,python-ldap)))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("doxygen" ,doxygen)
       ("gettext" ,gettext-minimal)
       ("libtool" ,libtool)
       ("rsync" ,rsync)
       ("pkg-config" ,pkg-config)))
    (home-page "https://directory.fedoraproject.org")
    (synopsis "Enterprise-class LDAP server")
    (description "389ds is an enterprise-class LDAP server.  It is hardened by
real-world use, is full-featured, and supports multi-master replication.

Other features include:

@enumerate
@item Online, zero downtime, LDAP-based update of schema, configuration, and
  management including @dfn{Access Control Information} (ACIs);
@item Asynchronous Multi-Master Replication, to provide fault tolerance and
  high write performance;
@item Extensive documentation;
@item Secure authentication and transport (TLS, and SASL);
@item LDAPv3 compliant server.
@end enumerate\n")
    ;; GPLv3+ with OpenSSL linking exception.
    (license gpl3+)))

(define-public python-bonsai
  (package
    (name "python-bonsai")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "bonsai" version))
       (sha256
        (base32
         "013bl6h1m3f7vg1lk89d4vi28wbf31zdcs4f9g8css7ngx63v6px"))))
    (build-system python-build-system)
    (inputs
     `(("mit-krb5" ,mit-krb5)
       ("cyrus-sasl" ,cyrus-sasl)
       ("openldap" ,openldap)))
    ;; disabling tests, since they require docker and extensive setup
    (arguments `(#:tests? #f))
    (home-page "https://github.com/noirello/bonsai")
    (synopsis "Access LDAP directory servers from Python")
    (description
     "This is a module for handling LDAP operations in Python.  LDAP entries
are mapped to a special Python case-insensitive dictionary, tracking the
changes of the dictionary to modify the entry on the server easily.")
    (license expat)))


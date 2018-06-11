;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016, 2017, 2018 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages selinux)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages swig)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages xml))

;; Update the SELinux packages together!

(define-public libsepol
  (package
    (name "libsepol")
    (version "2.7")
    (source (let ((release "20170804"))
              (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/SELinuxProject/selinux.git")
                      (commit release)))
                (file-name (string-append "selinux-" release "-checkout"))
                (sha256
                 (base32
                  "1l1nn8bx08v4cxkw5kb0wgr61rfqj5ra9dh1dy5jslillj93vivq")))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; tests require checkpolicy, which requires libsepol
       #:test-target "test"
       #:make-flags
       (let ((out (assoc-ref %outputs "out")))
         (list (string-append "PREFIX=" out)
               (string-append "DESTDIR=" out)
               (string-append "MAN3DIR=" out "/share/man/man3")
               (string-append "MAN5DIR=" out "/share/man/man5")
               (string-append "MAN8DIR=" out "/share/man/man8")
               (string-append "LDFLAGS=-Wl,-rpath=" out "/lib")
               "CC=gcc"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'unpack 'enter-dir
           (lambda _ (chdir ,name) #t))
         (add-after 'enter-dir 'portability
           (lambda _
             (substitute* "src/ibpkeys.c"
               (("#include \"ibpkey_internal.h\"" line)
                (string-append line "\n#include <inttypes.h>\n"))
               (("%#lx") "%#\" PRIx64 \""))
             #t)))))
    (native-inputs
     `(("flex" ,flex)))
    (home-page "https://selinuxproject.org/")
    (synopsis "Library for manipulating SELinux policies")
    (description
     "The libsepol library provides an API for the manipulation of SELinux
binary policies.  It is used by @code{checkpolicy} (the policy compiler) and
similar tools, and programs such as @code{load_policy}, which must perform
specific transformations on binary policies (for example, customizing policy
boolean settings).")
    (license license:lgpl2.1+)))

(define-public checkpolicy
  (package (inherit libsepol)
    (name "checkpolicy")
    (arguments
     `(#:tests? #f ; there is no check target
       #:make-flags
       (let ((out (assoc-ref %outputs "out")))
         (list (string-append "PREFIX=" out)
               (string-append "LIBSEPOLA="
                              (assoc-ref %build-inputs "libsepol")
                              "/lib/libsepol.a")
               "CC=gcc"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'portability)
         (add-after 'unpack 'enter-dir
           (lambda _ (chdir ,name) #t)))))
    (inputs
     `(("libsepol" ,libsepol)))
    (native-inputs
     `(("bison" ,bison)
       ("flex" ,flex)))
    (synopsis "Check SELinux security policy configurations and modules")
    (description
     "This package provides the tools \"checkpolicy\" and \"checkmodule\".
Checkpolicy is a program that checks and compiles a SELinux security policy
configuration into a binary representation that can be loaded into the kernel.
Checkmodule is a program that checks and compiles a SELinux security policy
module into a binary representation.")
    ;; GPLv2 only
    (license license:gpl2)))

(define-public libselinux
  (package (inherit libsepol)
    (name "libselinux")
    (arguments
     (substitute-keyword-arguments (package-arguments libsepol)
       ((#:make-flags flags)
        `(cons* "PYTHON=python3"
                (string-append "LIBSEPOLA="
                              (assoc-ref %build-inputs "libsepol")
                              "/lib/libsepol.a")
                (string-append "PYSITEDIR="
                               (assoc-ref %outputs "out")
                               "/lib/python"
                               ,(version-major+minor (package-version python))
                               "/site-packages/")
                ,flags))
       ((#:phases phases)
        `(modify-phases ,phases
           (delete 'portability)
           (replace 'enter-dir
             (lambda _ (chdir ,name) #t))
           (add-after 'enter-dir 'remove-Werror
             (lambda _
               ;; GCC complains about the fact that the output does not (yet)
               ;; have an "include" directory, even though it is referenced.
               (substitute* '("src/Makefile"
                              "utils/Makefile")
                 (("-Werror ") ""))
               #t))
           (add-after 'build 'pywrap
             (lambda* (#:key make-flags #:allow-other-keys)
               (apply invoke "make" "pywrap" make-flags)))
           (add-after 'install 'install-pywrap
             (lambda* (#:key make-flags #:allow-other-keys)
               (apply invoke "make" "install-pywrap" make-flags)))))))
    ;; These libraries are in "Requires.private" in libselinux.pc.
    (propagated-inputs
     `(("libsepol" ,libsepol)
       ("pcre" ,pcre)))
    ;; For pywrap phase
    (inputs
     `(("python" ,python-wrapper)))
    ;; These inputs are only needed for the pywrap phase.
    (native-inputs
     `(("swig" ,swig)
       ("pkg-config" ,pkg-config)))
    (synopsis "SELinux core libraries and utilities")
    (description
     "The libselinux library provides an API for SELinux applications to get
and set process and file security contexts, and to obtain security policy
decisions.  It is required for any applications that use the SELinux API, and
used by all applications that are SELinux-aware.  This package also includes
the core SELinux management utilities.")
    (license license:public-domain)))

(define-public libsemanage
  (package (inherit libsepol)
    (name "libsemanage")
    (arguments
     (substitute-keyword-arguments (package-arguments libsepol)
       ((#:make-flags flags)
        `(cons* "PYTHON=python3"
                (string-append "PYSITEDIR="
                               (assoc-ref %outputs "out")
                               "/lib/python"
                               ,(version-major+minor (package-version python))
                               "/site-packages/")
                ,flags))
       ((#:phases phases)
        `(modify-phases ,phases
           (delete 'portability)
           (replace 'enter-dir
             (lambda _ (chdir ,name) #t))
           (add-after 'build 'pywrap
             (lambda* (#:key make-flags #:allow-other-keys)
               (zero? (apply system* "make" "pywrap" make-flags))))
           (add-after 'install 'install-pywrap
             (lambda* (#:key make-flags #:allow-other-keys)
               (zero? (apply system* "make" "install-pywrap" make-flags))))))))
    (inputs
     `(("libsepol" ,libsepol)
       ("libselinux" ,libselinux)
       ("audit" ,audit)
       ("ustr" ,ustr)
       ;; For pywrap phase
       ("python" ,python-wrapper)))
    (native-inputs
     `(("bison" ,bison)
       ("flex" ,flex)
       ;; For pywrap phase
       ("swig" ,swig)
       ("pkg-config" ,pkg-config)))
    (synopsis "SELinux policy management libraries")
    (description
     "The libsemanage library provides an API for the manipulation of SELinux
binary policies.")
    (license license:lgpl2.1+)))

(define-public secilc
  (package (inherit libsepol)
    (name "secilc")
    (arguments
     (substitute-keyword-arguments (package-arguments libsepol)
       ((#:make-flags flags)
        `(let ((docbook (assoc-ref %build-inputs "docbook-xsl")))
           (cons (string-append "XMLTO=xmlto --skip-validation -x "
                                docbook "/xml/xsl/docbook-xsl-"
                                ,(package-version docbook-xsl)
                                "/manpages/docbook.xsl")
                 ,flags)))
       ((#:phases phases)
        `(modify-phases ,phases
           (delete 'portability)
           (replace 'enter-dir
             (lambda _ (chdir ,name) #t))))))
    (inputs
     `(("libsepol" ,libsepol)))
    (native-inputs
     `(("xmlto" ,xmlto)
       ("docbook-xsl" ,docbook-xsl)))
    (synopsis "SELinux common intermediate language (CIL) compiler")
    (description "The SELinux CIL compiler is a compiler that converts the
@dfn{common intermediate language} (CIL) into a kernel binary policy file.")
    (license license:bsd-2)))

(define-public python-sepolgen
  (package (inherit libsepol)
    (name "python-sepolgen")
    (arguments
     `(#:modules ((srfi srfi-1)
                  (guix build gnu-build-system)
                  (guix build utils))
       ,@(substitute-keyword-arguments (package-arguments libsepol)
           ((#:phases phases)
            `(modify-phases ,phases
               (delete 'portability)
               (replace 'enter-dir
                 (lambda _ (chdir "python/sepolgen") #t))
               ;; By default all Python files would be installed to
               ;; $out/gnu/store/...-python-.../, so we override the
               ;; PACKAGEDIR to fix this.
               (add-after 'enter-dir 'fix-target-path
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (let ((get-python-version
                          ;; FIXME: copied from python-build-system
                          (lambda (python)
                            (let* ((version     (last (string-split python #\-)))
                                   (components  (string-split version #\.))
                                   (major+minor (take components 2)))
                              (string-join major+minor ".")))))
                     (substitute* "src/sepolgen/Makefile"
                       (("^PACKAGEDIR.*")
                        (string-append "PACKAGEDIR="
                                       (assoc-ref outputs "out")
                                       "/lib/python"
                                       (get-python-version
                                        (assoc-ref inputs "python"))
                                       "/site-packages/sepolgen")))
                     (substitute* "src/share/Makefile"
                       (("\\$\\(DESTDIR\\)") (assoc-ref outputs "out"))))
                   #t)))))))
    (inputs
     `(("python" ,python-wrapper)))
    (native-inputs '())
    (synopsis "Python module for generating SELinux policies")
    (description
     "This package contains a Python module that forms the core of
@code{audit2allow}, a part of the package @code{policycoreutils}.  The
sepolgen library contains: Reference Policy Representation, which are Objects
for representing policies and the reference policy interfaces.  It has objects
and algorithms for representing access and sets of access in an abstract way
and searching that access.  It also has a parser for reference policy
\"headers\".  It contains infrastructure for parsing SELinux related messages
as produced by the audit system.  It has facilities for generating policy
based on required access.")
    ;; GPLv2 only
    (license license:gpl2)))

(define-public python-setools
  (package
    (name "python-setools")
    (version "4.1.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/TresysTechnology/setools.git")
                    (commit version)))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32
                "0459xxly6zzqc5azcwk3rbbcxvj60dq08f8z6xr05y7dsbb16cg6"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f ; the test target causes a rebuild
       #:phases
       (modify-phases %standard-phases
         (delete 'portability)
         (add-after 'unpack 'set-SEPOL-variable
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "SEPOL"
                     (string-append (assoc-ref inputs "libsepol")
                                    "/lib/libsepol.a"))))
         (add-after 'unpack 'remove-Werror
           (lambda _
             (substitute* "setup.py"
               (("'-Werror',") ""))
             #t))
         (add-after 'unpack 'fix-target-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "setup.py"
               (("join\\(sys.prefix")
                (string-append "join(\"" (assoc-ref outputs "out") "/\"")))
             #t)))))
    (propagated-inputs
     `(("python-networkx" ,python-networkx)))
    (inputs
     `(("libsepol" ,libsepol)
       ("libselinux" ,libselinux)))
    (native-inputs
     `(("bison" ,bison)
       ("flex" ,flex)
       ("swig" ,swig)))
    (home-page "https://github.com/TresysTechnology/setools")
    (synopsis "Tools for SELinux policy analysis")
    (description "SETools is a collection of graphical tools, command-line
tools, and libraries designed to facilitate SELinux policy analysis.")
    ;; Some programs are under GPL, all libraries under LGPL.
    (license (list license:lgpl2.1+
                   license:gpl2+))))

(define-public policycoreutils
  (package (inherit libsepol)
    (name "policycoreutils")
    (arguments
     `(#:test-target "test"
       #:make-flags
       (let ((out (assoc-ref %outputs "out")))
         (list "CC=gcc"
               (string-append "PREFIX=" out)
               (string-append "LOCALEDIR=" out "/share/locale")
               (string-append "BASHCOMPLETIONDIR=" out
                              "/share/bash-completion/completions")
               "INSTALL=install -c -p"
               "INSTALL_DIR=install -d"
               ;; These ones are needed because some Makefiles define the
               ;; directories relative to DESTDIR, not relative to PREFIX.
               (string-append "SBINDIR=" out "/sbin")
               (string-append "ETCDIR=" out "/etc")
               (string-append "SYSCONFDIR=" out "/etc/sysconfig")
               (string-append "MAN5DIR=" out "/share/man/man5")
               (string-append "INSTALL_NLS_DIR=" out "/share/locale")
               (string-append "AUTOSTARTDIR=" out "/etc/xdg/autostart")
               (string-append "DBUSSERVICEDIR=" out "/share/dbus-1/services")
               (string-append "SYSTEMDDIR=" out "/lib/systemd")
               (string-append "INITDIR=" out "/etc/rc.d/init.d")
               (string-append "SELINUXDIR=" out "/etc/selinux")))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'portability)
         (add-after 'unpack 'enter-dir
           (lambda _ (chdir ,name) #t))
         (add-after 'enter-dir 'ignore-/usr-tests
           (lambda* (#:key inputs #:allow-other-keys)
             ;; The Makefile decides to build restorecond only if it finds the
             ;; inotify header somewhere under /usr.
             (substitute* "Makefile"
               (("ifeq.*") "")
               (("endif.*") ""))
             ;; Rewrite lookup paths for header files.
             (substitute* '("newrole/Makefile"
                            "setfiles/Makefile"
                            "run_init/Makefile")
               (("/usr(/include/security/pam_appl.h)" _ file)
                (string-append (assoc-ref inputs "pam") file))
               (("/usr(/include/libaudit.h)" _ file)
                (string-append (assoc-ref inputs "audit") file)))
             #t)))))
    (inputs
     `(("audit" ,audit)
       ("pam" ,linux-pam)
       ("libsepol" ,libsepol)
       ("libselinux" ,libselinux)
       ("libsemanage" ,libsemanage)))
    (native-inputs
     `(("gettext" ,gettext-minimal)))
    (synopsis "SELinux core utilities")
    (description "The policycoreutils package contains the core utilities that
are required for the basic operation of an SELinux-enabled GNU system and its
policies.  These utilities include @code{load_policy} to load policies,
@code{setfiles} to label file systems, @code{newrole} to switch roles, and
@code{run_init} to run service scripts in their proper context.")
    (license license:gpl2+)))

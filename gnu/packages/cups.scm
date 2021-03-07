;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015, 2019, 2021 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015, 2016, 2017, 2019 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2015, 2016, 2017, 2018 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Danny Milosavljevic <dannym@scratchpost.org>
;;; Copyright © 2017 Leo Famulari <leo@famulari.name>
;;; Copyright © 2017 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2017–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2020 Marius Bakke <mbakke@fastmail.com>
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

(define-module (gnu packages cups)
  #:use-module (gnu packages)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fonts)     ; font-dejavu
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages scanner)
  #:use-module (gnu packages tls)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match))

(define-public brlaser
  (let ((commit "9d7ddda8383bfc4d205b5e1b49de2b8bcd9137f1")
        (revision "1"))
    (package
      (name "brlaser")
      (version (git-version "6" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/pdewacht/brlaser")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1drh0nk7amn9a8wykki4l9maqa4vy7vwminypfy1712alwj31nd4"))))
      (build-system cmake-build-system)
      (arguments
       `(#:configure-flags
         (list (string-append "-DCUPS_DATA_DIR="
                              (assoc-ref %outputs "out")
                              "/share/cups")
               (string-append "-DCUPS_SERVER_BIN="
                              (assoc-ref %outputs "out")
                              "/lib/cups"))))
      (inputs
       `(("ghostscript" ,ghostscript)
         ("cups" ,cups)
         ("zlib" ,zlib)))
      (home-page "https://github.com/pdewacht/brlaser")
      (synopsis "Brother laser printer driver")
      (description "Brlaser is a CUPS driver for Brother laser printers.  This
driver is known to work with these printers:

@enumerate
@item Brother DCP-1510 series
@item Brother DCP-1600 series
@item Brother DCP-7030
@item Brother DCP-7040
@item Brother DCP-7055
@item Brother DCP-7055W
@item Brother DCP-7060D
@item Brother DCP-7065DN
@item Brother DCP-7080
@item Brother DCP-L2500D series
@item Brother DCP-L2520D series
@item Brother DCP-L2540DW series
@item Brother HL-1110 series
@item Brother HL-1200 series
@item Brother HL-2030 series
@item Brother HL-2140 series
@item Brother HL-2220 series
@item Brother HL-2270DW series
@item Brother HL-5030 series
@item Brother HL-L2300D series
@item Brother HL-L2320D series
@item Brother HL-L2340D series
@item Brother HL-L2360D series
@item Brother MFC-1910W
@item Brother MFC-7240
@item Brother MFC-7360N
@item Brother MFC-7365DN
@item Brother MFC-7840W
@item Brother MFC-L2710DW series
@item Lenovo M7605D
@end enumerate")
      (license license:gpl2+))))

(define-public cups-filters
  (package
    (name "cups-filters")
    (version "1.27.4")
    (source(origin
              (method url-fetch)
              (uri
               (string-append "https://openprinting.org/download/cups-filters/"
                              "cups-filters-" version ".tar.xz"))
              (sha256
               (base32
                "110b1xhb5vfpcx0zq9kkas7pj281skx5dpnnr22idx509jfdzj8b"))
              (modules '((guix build utils)))
              (snippet
               ;; install backends, banners and filters to cups-filters output
               ;; directory, not the cups server directory
               '(begin
                  (substitute* "Makefile.in"
                    (("CUPS_DATADIR = @CUPS_DATADIR@")
                     "CUPS_DATADIR = $(PREFIX)/share/cups")
                    (("pkgcupsserverrootdir = \\$\\(CUPS_SERVERROOT\\)")
                     "pkgcupsserverrootdir = $(PREFIX)")
                    ;; Choose standard directories notably so that binaries are
                    ;; stripped.
                    (("pkgbackenddir = \\$\\(CUPS_SERVERBIN\\)/backend")
                     "pkgbackenddir = $(PREFIX)/lib/cups/backend")
                    (("pkgfilterdir = \\$\\(CUPS_SERVERBIN\\)/filter")
                     "pkgfilterdir = $(PREFIX)/lib/cups/filter"))
                  ;; Find bannertopdf data such as the print test page in our
                  ;; output directory, not CUPS's prefix.
                  (substitute* "configure"
                    (("\\{CUPS_DATADIR\\}/data")
                     "{prefix}/share/cups/data"))
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags (list (string-append "PREFIX=" %output))
       #:configure-flags
       `("--disable-driverless" ; TODO: enable this
         "--disable-mutool"     ; depends on yet another PDF library (mupdf)

         ;; Look for the "domain socket of CUPS" in /var/run/cups.
         "--localstatedir=/var"

         ;; Free software for the win.
         "--with-acroread-path=evince"

         ,(string-append "--with-test-font-path="
                         (assoc-ref %build-inputs "font-dejavu")
                         "/share/fonts/truetype/DejaVuSans.ttf")
         ,(string-append "--with-gs-path="
                         (assoc-ref %build-inputs "ghostscript")
                         "/bin/gsc")
         ,(string-append "--with-shell="
                         (assoc-ref %build-inputs "bash")
                         "/bin/bash")
         ,(string-append "--with-rcdir="
                         (assoc-ref %outputs "out") "/etc/rc.d"))

       #:phases (modify-phases %standard-phases
                  (add-after 'unpack 'patch-foomatic-hardcoded-file-names
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      ;; Foomatic has hardcoded file names we need to fix.
                      (let ((out (assoc-ref outputs "out"))
                            (gs  (assoc-ref inputs "ghostscript")))
                        (substitute* "filter/foomatic-rip/foomaticrip.c"
                          (("/usr/local/lib/cups/filter")
                           (string-append out "/lib/cups/filter")))
                        #t)))
                  (add-after 'install 'wrap-filters
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      ;; Some filters expect to find 'gs' in $PATH.  We cannot
                      ;; just hard-code its absolute file name in the source
                      ;; because foomatic-rip, for example, has tests like
                      ;; 'startswith(cmd, "gs")'.
                      (let ((out         (assoc-ref outputs "out"))
                            (ghostscript (assoc-ref inputs "ghostscript")))
                        (for-each (lambda (file)
                                    (wrap-program file
                                      `("PATH" ":" prefix
                                        (,(string-append ghostscript
                                                         "/bin")))))
                                  (find-files (string-append
                                               out "/lib/cups/filter")))
                        #t))))))
    (native-inputs
     `(("glib" ,glib "bin") ; for gdbus-codegen
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("avahi"        ,avahi)
       ("fontconfig"   ,fontconfig)
       ("freetype"     ,freetype)
       ("font-dejavu"  ,font-dejavu) ; also needed by test suite
       ("ghostscript"  ,ghostscript/cups)
       ("ijs"          ,ijs)
       ("dbus"         ,dbus)
       ("lcms"         ,lcms)
       ("libjpeg"      ,libjpeg-turbo)
       ("libpng"       ,libpng)
       ("libtiff"      ,libtiff)
       ("glib"         ,glib)
       ("qpdf"         ,qpdf)
       ("poppler"      ,poppler)
       ("cups-minimal" ,cups-minimal)))
    (home-page "https://wiki.linuxfoundation.org/openprinting/cups-filters")
    (synopsis "OpenPrinting CUPS filters and backends")
    (description
     "Contains backends, filters, and other software that was once part of the
core CUPS distribution but is no longer maintained by Apple Inc.  In addition
it contains additional filters developed independently of Apple, especially
filters for the PDF-centric printing workflow introduced by OpenPrinting.")
    ;; Different filters and backends have different licenses; see COPYING for
    ;; details
    (license (list license:gpl2
                   license:gpl2+
                   license:gpl3
                   license:gpl3+
                   license:lgpl2.0+
                   license:expat))))

;; CUPS on non-MacOS systems requires cups-filters.  Since cups-filters also
;; depends on CUPS libraries and binaries, cups-minimal has been added to
;; satisfy this dependency.
(define-public cups-minimal
  (package
    (name "cups-minimal")
    (version "2.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/apple/cups/releases/download/v"
                           version "/cups-" version "-source.tar.gz"))
       (sha256
        (base32
         "1vpk0b2vq830f8fvf9z8qjsm5k141i7pi8djbinpnr78pi4dj7r6"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       '("--disable-launchd"
         "--disable-systemd"
         "--disable-avahi"
         "--disable-dnssd")
       ;; Seven tests fail, mostly because of files that are provided by the
       ;; cups-filters package.
       #:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-makedefs
           (lambda _
             (substitute* "Makedefs.in"
               (("INITDIR.*=.*@INITDIR@") "INITDIR = @prefix@/@INITDIR@")
               (("/bin/sh") (which "sh")))
             #t))
         ;; Make the compressed manpages writable so that the
         ;; reset-gzip-timestamps phase does not error out.
         (add-before 'reset-gzip-timestamps 'make-manpages-writable
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (man (string-append out "/share/man")))
               (for-each (lambda (file) (chmod file #o644))
                         (find-files man "\\.gz"))
               #t)))
         (add-before 'build 'patch-tests
           (lambda _
             (substitute* "tools/ippeveprinter.c"
               (("#  else /\\* HAVE_AVAHI \\*/")
                "#elif defined(HAVE_AVAHI)"))
             #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("zlib"  ,zlib)
       ("gnutls" ,gnutls)))
    (home-page "https://www.cups.org")
    (synopsis "The Common Unix Printing System")
    (description
     "CUPS is a printing system that uses the Internet Printing Protocol
(@dfn{IPP}).  It provides System V and BSD command-line interfaces, as well
as a Web interface and a C programming interface to manage printers and print
jobs.  It supports printing to both local (parallel, serial, USB) and
networked printers, and printers can be shared from one computer to another.
Internally, CUPS uses PostScript Printer Description (@dfn{PPD}) files to
describe printer capabilities and features, and a wide variety of generic and
device-specific programs to convert and print many types of files.")
    ;; CUPS is Apache 2.0 with exceptions, see the NOTICE file.
    (license license:asl2.0)))

(define-public cups
  (package/inherit cups-minimal
    (name "cups")
    (arguments
     `(;; Three tests fail:
       ;; * two tests in ipp-1.1.test related to "RFC 2911 section 3.2.6:
       ;;   Get-Jobs Operation"
       ;; * test of number of error/warning messages, probably related to a
       ;;   missing font.
       #:tests? #f
       #:configure-flags
       '("--disable-launchd"
         "--disable-systemd")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-makedefs
           (lambda _
             (substitute* "Makedefs.in"
               (("INITDIR.*=.*@INITDIR@") "INITDIR = @prefix@/@INITDIR@")
               (("/bin/sh") (which "sh")))
             #t))
         (add-before 'check 'patch-tests
           (lambda _
             (let ((filters (assoc-ref %build-inputs "cups-filters"))
                   (catpath (string-append
                             (assoc-ref %build-inputs "coreutils") "/bin/"))
                   (testdir (string-append (getcwd) "/tmp/")))
               (mkdir testdir)
               (substitute* "test/run-stp-tests.sh"
                 ((" *BASE=/tmp/") (string-append "BASE=" testdir))

                 ;; allow installation of filters from output dir and from
                 ;; cups-filters
                 (("for dir in /usr/libexec/cups/filter /usr/lib/cups/filter")
                  (string-append
                   "for dir in "
                   (assoc-ref %outputs "out") "/lib/cups/filter "
                   filters "/lib/cups/filter"))

                 ;; check for charsets in cups-filters output
                 (("/usr/share/cups/charsets")
                  (string-append filters "/share/cups/charsets"))

                 ;; install additional required filters
                 (("instfilter texttopdf texttopdf pdf")
                  (string-append
                   "instfilter texttopdf texttopdf pdf;"
                   "instfilter imagetoraster imagetoraster raster;"
                   "instfilter gstoraster gstoraster raster;"
                   "instfilter urftopdf urftopdf pdf;"
                   "instfilter rastertopdf rastertopdf pdf;"
                   "instfilter pstopdf pstopdf pdf"))

                 ;; specify location of lpstat binary
                 (("description=\"`lpstat -l")
                  "description=\"`../systemv/lpstat -l")

                 ;; patch shebangs of embedded scripts
                 (("#!/bin/sh") (string-append "#!" (which "sh")))

                 ;; also link mime definitions from cups-filters
                 ;; to enable the additional filters for the test suite
                 (("ln -s \\$root/conf/mime\\.types")
                  (string-append
                   "ln -s " filters
                   "/share/cups/mime/cupsfilters.types $BASE/share/mime; "
                   "ln -s $root/conf/mime.types"))
                 (("ln -s \\$root/conf/mime\\.convs")
                  (string-append
                   "ln -s " filters
                   "/share/cups/mime/cupsfilters.convs $BASE/share/mime; "
                   "ln -s $root/conf/mime.convs")))

               ;; fix search path for "cat"
               (substitute* "cups/testfile.c"
                 (("cupsFileFind\\(\"cat\", \"/bin\"")
                  (string-append "cupsFileFind(\"cat\", \"" catpath "\""))
                 (("cupsFileFind\\(\"cat\", \"/bin:/usr/bin\"")
                  (string-append "cupsFileFind(\"cat\", \"" catpath "\"")))
               #t)))
         ;; Make the compressed manpages writable so that the
         ;; reset-gzip-timestamps phase does not error out.
         (add-before 'reset-gzip-timestamps 'make-manpages-writable
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (man (string-append out "/share/man")))
               (for-each (lambda (file) (chmod file #o644))
                         (find-files man "\\.gz"))
               #t)))
         (add-after 'install 'install-cups-filters-symlinks
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (cups-filters (assoc-ref inputs "cups-filters")))
               ;; charsets
               (symlink
                (string-append cups-filters "/share/cups/charsets")
                (string-append out "/share/charsets"))

               ;; mime types, driver file, ppds
               (for-each
                (lambda (f)
                  (symlink (string-append cups-filters f)
                           (string-append out f)))
                '("/share/cups/mime/cupsfilters.types"
                  "/share/cups/mime/cupsfilters.convs"
                  "/share/cups/drv/cupsfilters.drv"
                  "/share/ppd"))

               ;; filters
               (for-each
                (lambda (f)
                  (symlink f
                           (string-append out "/lib/cups/filter" (basename f))))
                (find-files (string-append cups-filters "/lib/cups/filter")))

               ;; backends
               (for-each
                (lambda (f)
                  (symlink (string-append cups-filters f)
                           (string-append out "/lib/cups/backend/"
                                          (basename f))))
                '("/lib/cups/backend/parallel"
                  "/lib/cups/backend/serial"))

               ;; banners
               (let ((banners "/share/cups/banners"))
                 (delete-file-recursively (string-append out banners))
                 (symlink (string-append cups-filters banners)
                          (string-append out banners)))

               ;; assorted data
               (let ((data "/share/cups/data"))
                 (delete-file-recursively (string-append out data))
                 (symlink (string-append cups-filters data)
                          (string-append out data)))

               #t))))))
    (inputs
     `(("avahi" ,avahi)
       ("gnutls" ,gnutls)
       ("cups-filters" ,cups-filters)
       ("zlib"  ,zlib)))))

(define-public cups-pk-helper
  (package
    (name "cups-pk-helper")
    (version "0.2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://freedesktop.org/software/"
                                  name "/releases/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "0a52jw6rm7lr5nbyksiia0rn7sasyb5cjqcb95z1wxm2yprgi6lm"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("glib" ,glib)
       ("polkit" ,polkit)
       ("cups" ,cups)))
    (home-page "https://www.freedesktop.org/wiki/Software/cups-pk-helper/")
    (synopsis "PolicyKit helper to configure CUPS with fine-grained privileges")
    (description
     "This package provides the org.opensuse.CupsPkHelper.Mechanism DBus
system service which uses @file{cups-pk-helper-mechanism}.  This package
should only be used as part of the Guix cups-pk-helper service.")
    (license license:gpl2+)))

(define-public hplip
  (package
    (name "hplip")
    (version "3.21.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/hplip/hplip/" version
                                  "/hplip-" version ".tar.gz"))
              (sha256
               (base32
                "0hbwx9d4c8177vi0gavz9pxi7rc97jciacndp90ms8327shj2121"))
              (modules '((guix build utils)))
              (patches (search-patches "hplip-remove-imageprocessor.patch"))
              (snippet
               '(begin
                  ;; Delete non-free blobs: .so files, pre-compiled
                  ;; 'locatedriver' executable, etc.
                  (for-each delete-file
                            (find-files "."
                                        (lambda (file stat)
                                          (elf-file? file))))
                  (delete-file "prnt/hpcups/ImageProcessor.h")

                  ;; Install binaries under libexec/hplip instead of
                  ;; share/hplip; that'll at least ensure they get stripped.
                  ;; It's not even clear that they're of any use though...
                  (substitute* "Makefile.in"
                    (("^dat2drvdir =.*")
                     "dat2drvdir = $(pkglibexecdir)\n")
                    (("^locatedriverdir =.*")
                     "locatedriverdir = $(pkglibexecdir)\n"))
                  #t))))
    (build-system gnu-build-system)
    (outputs (list "out" "ppd"))
    (home-page "https://developers.hp.com/hp-linux-imaging-and-printing")
    (synopsis "HP printer drivers")
    (description
     "Hewlett-Packard printer drivers and PostScript Printer Descriptions
(@dfn{PPD}s).")

    ;; The 'COPYING' file lists directories where each of these 3 licenses
    ;; applies.
    (license (list license:gpl2+ license:bsd-3 license:expat))

    ;; TODO install apparmor profile files eventually.
    (arguments
     `(#:configure-flags
       `("--disable-network-build"
         ,(string-append "--prefix=" (assoc-ref %outputs "out"))
         ,(string-append "--sysconfdir=" (assoc-ref %outputs "out") "/etc")
         ,(string-append "LDFLAGS=-Wl,-rpath="
                         (assoc-ref %outputs "out") "/lib")
         ;; Disable until mime.types merging works (FIXME).
         "--disable-fax-build"
         "--enable-new-hpcups"
         ;; TODO add foomatic drv install eventually.
         ;; TODO --enable-policykit eventually.
         ,(string-append "--with-cupsfilterdir="
                         (assoc-ref %outputs "out") "/lib/cups/filter")
         ,(string-append "--with-cupsbackenddir="
                         (assoc-ref %outputs "out") "/lib/cups/backend")
         ,(string-append "--with-hpppddir="
                         (assoc-ref %outputs "ppd") "/share/ppd/HP")
         ,(string-append "--with-icondir="
                         (assoc-ref %outputs "out") "/share/applications")
         ,(string-append "--with-systraydir="
                         (assoc-ref %outputs "out") "/etc/xdg")
         "--enable-qt5" "--disable-qt4")

       #:imported-modules ((guix build python-build-system)
                           ,@%gnu-build-system-modules)
       #:modules ((guix build gnu-build-system)
                  (guix build utils)
                  ((guix build python-build-system) #:prefix python:))

       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-hard-coded-file-names
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   ;; FIXME: use merged ppds (I think actually only
                   ;; drvs need to be merged).
                   (cupsdir (assoc-ref inputs "cups-minimal")))
               (substitute* "base/g.py"
                 (("'/usr/share;[^']*'")
                  (string-append "'" cupsdir "/share'"))
                 (("'/etc/hp/hplip.conf'")
                  (string-append "'" out
                                 "/etc/hp/hplip.conf" "'")))

               (substitute* "Makefile.in"
                 (("[[:blank:]]check-plugin\\.py[[:blank:]]") " ")
                 ;; FIXME Use beginning-of-word in regexp.
                 (("[[:blank:]]plugin\\.py[[:blank:]]") " ")
                 (("/usr/include/libusb-1.0")
                  (string-append (assoc-ref inputs "libusb")
                                 "/include/libusb-1.0"))
                 (("hplip_statedir =.*$")
                  ;; Don't bail out while trying to create
                  ;; /var/lib/hplip.  We can safely change its value
                  ;; here because it's hard-coded in the code anyway.
                  "hplip_statedir = $(prefix)\n")
                 (("hplip_confdir = /etc/hp")
                  ;; This is only used for installing the default config.
                  (string-append "hplip_confdir = " out
                                 "/etc/hp"))
                 (("halpredir = /usr/share/hal/fdi/preprobe/10osvendor")
                  ;; We don't use hal.
                  (string-append "halpredir = " out
                                 "/share/hal/fdi/preprobe/10osvendor"))
                 (("rulesdir = /etc/udev/rules.d")
                  ;; udev rules will be merged by base service.
                  (string-append "rulesdir = " out
                                 "/lib/udev/rules.d"))
                 (("rulessystemdir = /usr/lib/systemd/system")
                  ;; We don't use systemd.
                  (string-append "rulessystemdir = " out
                                 "/lib/systemd/system"))
                 (("/etc/sane.d")
                  (string-append out "/etc/sane.d")))
               #t)))
         (add-before 'configure 'fix-build-with-python-3.8
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((python (assoc-ref inputs "python")))
               ;; XXX: The configure script looks for Python headers in the
               ;; wrong places as of version 3.20.3.  Help it by adding the
               ;; include directory on C_INCLUDE_PATH.
               (when python
                 (setenv "C_INCLUDE_PATH"
                         (string-append python "/include/python"
                                        (python:python-version python)
                                        ":" (getenv "C_INCLUDE_PATH"))))
               #t)))
         (add-after 'install 'install-models-dat
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (models-dir (string-append out
                                               "/share/hplip/data/models")))
               (install-file "data/models/models.dat" models-dir))
             #t))
         (add-after 'install 'wrap-binaries
           ;; Scripts in /bin are all symlinks to .py files in /share/hplip.
           ;; Symlinks are immune to the Python build system's 'WRAP phase,
           ;; and the .py files can't be wrapped because they are reused as
           ;; modules.  Replacing the symlinks in /bin with copies and
           ;; wrapping them also doesn't work (“ModuleNotFoundError:
           ;; No module named 'base'”).  Behold: a custom WRAP-PROGRAM.
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (python (assoc-ref inputs "python")))
               (with-directory-excursion bin
                 (for-each (lambda (file)
                             (let ((target (readlink file)))
                               (delete-file file)
                               (with-output-to-file file
                                 (lambda _
                                   (format #t
                                           "#!~a~@
                                           export PYTHONPATH=\"~a:~a\"~@
                                           exec -a \"$0\" \"~a/~a\" \"$@\"~%"
                                           (which "bash")
                                           (string-append
                                            out "/lib/python"
                                            (python:python-version python)
                                            "/site-packages")
                                           (getenv "PYTHONPATH")
                                           bin target)))
                               (chmod file #o755)))
                  (find-files "." (lambda (file stat)
                                    (eq? 'symlink (stat:type stat)))))
                 #t)))))))

    ;; Note that the error messages printed by the tools in the case of
    ;; missing dependencies are often downright misleading.
    ;; TODO: hp-toolbox still fails to start with:
    ;;   from dbus.mainloop.pyqt5 import DBusQtMainLoop
    ;;   ModuleNotFoundError: No module named 'dbus.mainloop.pyqt5'
    (inputs
     `(("cups-minimal" ,cups-minimal)
       ("dbus" ,dbus)
       ("libjpeg" ,libjpeg-turbo)
       ("libusb" ,libusb)
       ("python" ,python)
       ("python-dbus" ,python-dbus)
       ("python-pygobject" ,python-pygobject)
       ("python-pyqt" ,python-pyqt)
       ("python-wrapper" ,python-wrapper)
       ("sane-backends" ,sane-backends-minimal)
       ("zlib" ,zlib)))
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))))

(define-public hplip-minimal
  (package
    (inherit hplip)
    (name "hplip-minimal")
    (arguments
      (substitute-keyword-arguments (package-arguments hplip)
        ((#:configure-flags cf)
         ;; Produce a "light build", meaning that only the printer (CUPS) and
         ;; scanner (SANE) support gets built, without all the 'hp-*'
         ;; command-line tools.
         `(cons "--enable-lite-build"
                (delete "--enable-qt5" ,cf)))
        ((#:phases phases)
         ;; The 'wrap-binaries' is not needed here since the 'hp-*' programs
         ;; are not installed.
         `(alist-delete 'wrap-binaries ,phases))))
    (inputs (remove (match-lambda
                      ((label . _)
                       (string-prefix? "python" label)))
                    (package-inputs hplip)))
    (synopsis "GUI-less version of hplip")))

(define-public foomatic-filters
  (package
    (name "foomatic-filters")
    (version "4.0.17")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.openprinting.org/download/foomatic/"
                    "foomatic-filters-" version ".tar.gz"))
              (sha256
               (base32
                "1qrkgbm5jay2r7sh9qbyf0aiyrsl1mdc844hxf7fhw95a0zfbqm2"))
              (patches
               (search-patches "foomatic-filters-CVE-2015-8327.patch"
                               "foomatic-filters-CVE-2015-8560.patch"))))
    (build-system gnu-build-system)
    (home-page
     "https://wiki.linuxfoundation.org/openprinting/database/foomatic")
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("dbus" ,dbus)
       ("a2ps" ,a2ps)))
    (arguments
     '( ;; Specify the installation directories.
       #:configure-flags (list (string-append "ac_cv_path_CUPS_BACKENDS="
                                              (assoc-ref %outputs "out")
                                              "/lib/cups/backend")
                               (string-append "ac_cv_path_CUPS_FILTERS="
                                              (assoc-ref %outputs "out")
                                              "/lib/cups/filter")
                               (string-append "ac_cv_path_PPR_INTERFACES="
                                              (assoc-ref %outputs "out")
                                              "/lib/ppr/interfaces")
                               (string-append "ac_cv_path_PPR_LIB="
                                              (assoc-ref %outputs "out")
                                              "/lib/ppr/lib")

                               ;; For some reason these are misdiagnosed.
                               "ac_cv_func_malloc_0_nonnull=yes"
                               "ac_cv_func_realloc_0_nonnull=yes")
       #:test-target "tests"))
    (synopsis "Convert PostScript to the printer's native format")
    (description
     "This package contains filter scripts used by the printer spoolers to
convert the incoming PostScript data into the printer's native format using a
printer/driver specific, but spooler-independent PPD file.")
    (license license:gpl2+)))

(define-public foo2zjs
  (package
    (name "foo2zjs")
    (version "20200610")
    (source (origin
              (method url-fetch)
              ;; XXX: This is an unversioned URL!
              (uri "http://foo2zjs.rkkda.com/foo2zjs.tar.gz")
              (sha256
               (base32
                "11ddx6wf8b5ksl4fqw6fnyz9m3y470lryyrskkya2bsch2bvj9lg"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (replace 'configure
                    (lambda* (#:key outputs #:allow-other-keys)
                      (substitute* (find-files "." "^Makefile$")
                        ;; Set the installation directory.
                        (("^PREFIX[[:blank:]]*=.*$")
                         (string-append "PREFIX = "
                                        (assoc-ref outputs "out")
                                        "\n"))
                        (("^UDEVBIN[[:blank:]]*=.*$")
                         "UDEVBIN = $(PREFIX)/bin\n")
                        ;; Don't try to chown/chgrp the installed files.
                        (("-oroot")
                         "")
                        (("-glp")
                         "")
                        ;; Placate the dependency checks.
                        (("/usr/include/stdio.h")
                         "/etc/passwd")
                        (("/usr/")
                         "$(PREFIX)/")
                        ;; Ensure fixed timestamps in man pages.
                        (("^MODTIME[[:blank:]]*=.*$")
                         "MODTIME = echo Thu Jan 01 01:00:00 1970\n"))
                      #t))
                  (add-before 'install 'make-install-dirs
                    (lambda* (#:key outputs #:allow-other-keys)
                      ;; Make missing install dirs
                      (let ((out (assoc-ref outputs "out"))
                            (dirs '("/share/cups/model"
                                    "/share/foomatic/db/source/opt"
                                    "/share/foomatic/db/source/printer"
                                    "/share/foomatic/db/source/driver"
                                    "/lib/cups/filter")))
                        (for-each (lambda (dir)
                                    (mkdir-p (string-append out dir)))
                                  dirs))))
                  (add-after 'install 'wrap-wrappers
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out"))
                            (ghostscript (assoc-ref inputs "ghostscript"))
                            (coreutils (assoc-ref inputs "coreutils"))
                            (sed (assoc-ref inputs "sed")))
                        (for-each (lambda (file)
                                    (wrap-program file
                                      `("PATH" ":" prefix
                                        (,(string-append ghostscript "/bin:"
                                                         coreutils "/bin:"
                                                         sed "/bin")))))
                                  (find-files (string-append
                                               out "/bin") "wrapper$")))))
                  (add-after 'install 'install-cups-filters-symlinks
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out")))
                        (for-each
                         (lambda (file)
                           (symlink file
                                    (string-append out "/lib/cups/filter/"
                                                   (basename file))))
                         (find-files (string-append out "/bin"))))))
                  (add-after 'install 'remove-pdf
                    (lambda* (#:key outputs #:allow-other-keys)
                      ;; Remove 'manual.pdf' which is (1) useless (it's a
                      ;; concatenation of man pages), and (2) not
                      ;; bit-reproducible due to <https://bugs.gnu.org/27593>.
                      (let ((out (assoc-ref outputs "out")))
                        (for-each delete-file
                                  (find-files out "^manual\\.pdf$"))
                        #t))))
       #:parallel-build? #f                       ;broken makefile
       #:tests? #f                                ;no tests
       #:make-flags '("CC=gcc")))
    (inputs
     `(("coreutils" ,coreutils)
       ("sed" ,sed)
       ("ghostscript" ,ghostscript)
       ("foomatic-filters" ,foomatic-filters)))   ;for 'foomatic-rip'
    (native-inputs
     `(("bc" ,bc)
       ("groff" ,groff)))
    (home-page "http://foo2zjs.rkkda.com/")
    (synopsis "Printer driver for ZjStream-based printers")
    (description
     "foo2zjs is a printer driver for printers that use the Zenographics
ZjStream wire protocol for their print data, often erroneously referred to as
winprinters or GDI printers.

It supports Minolta/QMS@tie{}Magicolor, Minolta@tie{}Color@tie{}PageWorks/Pro,
HP@tie{}LaserJet, and possibly other printers.  See @file{README} for details.")
    (license (list license:expat        ; icc2ps/*.[ch]
                   license:gpl2+))))    ; everything else

(define-public epson-inkjet-printer-escpr
  (package
    (name "epson-inkjet-printer-escpr")
    (version "1.7.9")
    ;; XXX: This currently works.  But it will break as soon as a newer
    ;; version is available since the URLs for older versions are not
    ;; preserved.  An alternative source will be added as soon as
    ;; available.
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://download3.ebz.epson.net/dsc/f/03/00/12/50/95/"
                           "322b8d6b915ab85add33d41f04ba5130866aadbe/"
                           "epson-inkjet-printer-escpr-1.7.9-1lsb3.2.tar.gz"))
       (sha256
        (base32 "136hhvhimxfnrdn3ksbiswjxgsifrwlp3zz8h0v63w4k1vkzpgc0"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules
       ((srfi srfi-26)
        ,@%gnu-build-system-modules)
       #:configure-flags
       `("--disable-static"
         ,(string-append "--prefix="
                         (assoc-ref %outputs "out"))
         ,(string-append "--with-cupsfilterdir="
                         (assoc-ref %outputs "out") "/lib/cups/filter")
         ,(string-append "--with-cupsppddir="
                         (assoc-ref %outputs "out") "/share/cups/model"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-autotools-version-requirement
           (lambda _
             (substitute* "aclocal.m4"
               (("1\\.15")
                ,(package-version automake)))
             (substitute* "configure"
               (("^(ACLOCAL=).*" _ match)
                (string-append match "aclocal"))
               (("^(AUTOMAKE=).*" _ match)
                (string-append match "automake")))
             #t))
         (add-after 'install 'compress-PPDs
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (with-directory-excursion out
                 (for-each (cut invoke "gzip" "-9" <>)
                           (find-files "share/cups" "\\.ppd$")))))))))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)))
    (inputs
     `(("cups" ,cups-minimal)))
    (synopsis "ESC/P-R printer driver")
    (description
     "This package provides a filter for @acronym{CUPS, the Common UNIX Printing
System} that offers high-quality printing with Seiko@tie{}Epson color ink jet
printers.  It can be used only with printers that support the Epson@tie{}ESC/P-R
language.")
    (home-page "http://download.ebz.epson.net/dsc/search/01/search/?OSC=LX")
    (license license:gpl2+)))

(define-public escpr
  (deprecated-package "escpr" epson-inkjet-printer-escpr))

(define-public splix
  ;; Last released in 2009 <https://sourceforge.net/projects/splix/files/>.
  ;; Last SVN commit was 2013 <https://svn.code.sf.net/p/splix/code/splix/>.
  ;; Use a more maintained fork with several bug fixes and support for newer
  ;; printer models.
  (let ((commit "76268c4dd7dbc8218ea7426401104c3b40cc707a")
        (revision "315"))
    (package
      (name "splix")
      (version (git-version "2.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/ScumCoder/splix")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1mxsvllwwr1v8sgrax0b7gkajjhnm0l06s67spmaxz47lyll1qab"))))
      (build-system gnu-build-system)
      ;; PPDs have been obsolete since CUPS 1.2 and make up 90% of total size.
      (outputs (list "out" "ppd"))
      (arguments
       `(#:modules
         ((srfi srfi-26)
          ,@%gnu-build-system-modules)
         #:make-flags
         (list (string-append "CUPSDRV="
                              (assoc-ref %outputs "out") "/share/cups/drv")
               (string-append "CUPSFILTER="
                              (assoc-ref %outputs "out") "/lib/cups/filter")
               (string-append "CUPSPPD="
                              (assoc-ref %outputs "ppd") "/share/cups/model")
               "CACHESIZE=100"          ; pages in RAM, ±300 KiB each
               "THREADS=4")             ; compress and print faster
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'enter-subdirectory
             ;; The git repository replicates the top-level SVN layout.
             (lambda _
               (chdir "splix")
               #t))
           (delete 'configure)          ; no configure script
           (add-before 'build 'build-.drv-files
             (lambda* (#:key make-flags #:allow-other-keys)
               (apply invoke "make" "drv" make-flags)))
           (add-after 'install 'install-.drv-files
             (lambda* (#:key make-flags #:allow-other-keys)
               (apply invoke "make" "install" "DRV_ONLY=1" make-flags)))
           (add-after 'install 'compress-PPDs
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((ppd (assoc-ref outputs "ppd")))
                 (for-each (cut invoke "gzip" "-9" <>)
                           (find-files ppd "\\.ppd$"))))))
         #:tests? #f))                  ; no test suite
      (inputs
       `(("cups" ,cups-minimal)
         ("jbigkit" ,jbigkit)
         ("zlib" ,zlib)))
      (synopsis "QPDL (SPL2) printer driver")
      (description
       "SpliX is a set of CUPS drivers for printers that speak @acronym{QPDL,
Quick Page Description Language}, also called @acronym{SPL2, Samsung Printer
Language version 2}.  These include many laser printers sold by Samsung,
Xerox, Lexmark, Toshiba, and Dell.

Colour printers need colour profile files to get better results.  These
@file{cms} files are provided by the printer's manufacturer and must be
obtained and installed separately.")
      (home-page "http://splix.ap2c.org/")
      (license license:gpl2))))

(define-public python-pycups
  (package
    (name "python-pycups")
    (version "1.9.74")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pycups" version ".tar.bz2"))
       (sha256
        (base32
         "1ffp7sswhdsfpy88zg0cc8kl04wygkjs01rlm9f0spbwk8jhy2c6"))))
    (build-system python-build-system)
    (arguments
     '(;; Tests require CUPS to be running
       #:tests? #f))
    (inputs
     `(("cups" ,cups)))
    (home-page "https://github.com/zdohnal/pycups")
    (synopsis "Python bindings for libcups")
    (description
     "This package provides Python bindings for libcups, wrapping the CUPS
API.")
    (license license:gpl2+)))

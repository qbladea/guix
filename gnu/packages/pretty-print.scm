;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016, 2019, 2020 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2017 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2017, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2017–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2019 Meiyo Peng <meiyo@riseup.net>
;;; Copyright © 2020 Paul Garlick <pgarlick@tourbillion-technology.com>
;;; Copyright © 2020 Vincent Legoll <vincent.legoll@gmail.com>
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

(define-module (gnu packages pretty-print)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages gv)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages swig))

(define-public a2ps
  (package
    (name "a2ps")
    (version "4.14")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/a2ps/a2ps-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "195k78m1h03m961qn7jr120z815iyb93gwi159p1p9348lyqvbpk"))
              (modules '((guix build utils)))
              (snippet
               ;; Remove timestamp from the installed 'README' file.
               '(begin
                  (substitute* "etc/README.in"
                    (("@date@")
                     "1st of some month, sometime after 1970"))
                  #t))
              (patches (search-patches
                        "a2ps-CVE-2001-1593.patch"
                        "a2ps-CVE-2014-0466.patch"
                        "a2ps-CVE-2015-8107.patch"))))
    (build-system gnu-build-system)
    (inputs
     `(("psutils" ,psutils)
       ("gv" ,gv)))
    (native-inputs
     `(("gperf" ,gperf)
       ("groff" ,groff)
       ("perl" ,perl)))
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-before 'build 'patch-scripts
           (lambda _
             (substitute*
                 '("afm/make_fonts_map.sh"
                   "tests/defs"
                   "tests/backup.tst"
                   "tests/styles.tst")
               (("/bin/rm") (which "rm")))))
         (add-before 'check 'patch-test-files
           ;; Alternatively, we could unpatch the shebangs in tstfiles
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((perl (assoc-ref inputs "perl")))
               (substitute* '("tests/ps-ref/includeres.ps"
                              "tests/gps-ref/includeres.ps")
                 (("/usr/local/bin/perl")
                  (string-append perl "/bin/perl"))))
             ;; Some of the reference postscript contain a 'version 3'
             ;; string that in inconsistent with the source text in the
             ;; tstfiles directory.  Erroneous search-and-replace?
             (substitute* '("tests/ps-ref/InsertBlock.ps"
                            "tests/gps-ref/InsertBlock.ps"
                            "tests/ps-ref/bookie.ps"
                            "tests/gps-ref/bookie.ps")
               (("version 3") "version 2"))
             (substitute* '("tests/ps-ref/psmandup.ps"
                            "tests/gps-ref/psmandup.ps")
               (("#! */bin/sh") (string-append
                                 "#!" (which "sh")))))))))
    (home-page "https://www.gnu.org/software/a2ps/")
    (synopsis "Any file to PostScript, including pretty-printing")
    (description
     "GNU a2ps converts almost anything to a PostScript file, ready for
printing.  It accomplishes this by being able to delegate files to external
handlers, such as Groff and Gzip.  It handles as many steps as is necessary to
produce a pretty-printed file.  It also includes some extra abilities for
special cases, such as pretty-printing \"--help\" output.")
    (license gpl3+)))

(define-public trueprint
  (package
    (name "trueprint")
    (version "5.4")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/trueprint/trueprint-"
                          version ".tar.gz"))
      (sha256
       (base32
        "13rkc0fga10xyf56yy9dnq95zndnfadkhxflnp24skszj21y8jqh"))))
    (build-system gnu-build-system)
    (arguments
     ;; Must define DIFF_CMD for tests to pass
     '(#:configure-flags '("CPPFLAGS=-DDIFF_CMD=\\\"diff\\\"")))
    (home-page "https://www.gnu.org/software/trueprint/")
    (synopsis "Pretty-print C sources and other plain text to PostScript")
    (description
     "GNU Trueprint translates C source code files as PostScript files.
In addition to the basic source code output, it can also perform diff-marking,
indentation counting, function and file indices and more.")
    (license gpl2)))

(define-public enscript
  (package
    (name "enscript")
    (version "1.6.6")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/enscript/enscript-"
                          version ".tar.gz"))
      (sha256
       (base32
        "1fy0ymvzrrvs889zanxcaxjfcxarm2d3k43c9frmbl1ld7dblmkd"))))
    (build-system gnu-build-system)
    (home-page "https://www.gnu.org/software/enscript/")
    (synopsis "Generating PostScript, including pretty-printing")
    (description
     "GNU Enscript is a program to convert ASCII text files to PostScript,
HTML or RTF formats, to be stored in files or sent immediately to a printer.
It also includes the capability to perform syntax highlighting for several
different programming languages.")
    (license gpl3+)))

(define-public fmt
  (package
    (name "fmt")
    (version "7.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/fmtlib/fmt/releases/download/"
                           version "/fmt-" version ".zip"))
       (sha256
        (base32 "0kgajl3qsrdyj0csqsz8b8h84kasdy0pnh16byl0y1vlsaddzkyy"))))
    (build-system cmake-build-system)
    (arguments
     '(#:configure-flags '("-DBUILD_SHARED_LIBS=ON")))
    (native-inputs
     `(("unzip" ,unzip)))
    (home-page "https://fmt.dev")
    (synopsis "Small and fast C++ formatting library")
    (description
     "@code{fmt} (formerly @code{cppformat}) is a formatting library for C++.
It can be used as a safe alternative to @code{printf} or as a fast alternative
to @code{IOStreams}.")
    ;; The library is bsd-2, but documentation and tests include other licenses.
    (license (list bsd-2 bsd-3 psfl))))

(define-public fmt-6
  (package
    (inherit fmt)
    (name "fmt")
    (version "6.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/fmtlib/fmt/releases/download/"
                           version "/fmt-" version ".zip"))
       (sha256
        (base32 "06l8g59frbsbwj15kg6x2bbn6p8yidh6wzsigdhbdjncvm1agzll"))))))

(define-public source-highlight
  (package
    (name "source-highlight")
    (version "3.1.9")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/src-highlite/source-highlight-"
                          version ".tar.gz"))
      (sha256
       (base32
        "148w47k3zswbxvhg83z38ifi85f9dqcpg7icvvw1cm6bg21x4zrs"))))
    (build-system gnu-build-system)
    ;; The ctags that comes with emacs does not support the --excmd options,
    ;; so can't be used
    (inputs
     `(("boost" ,boost)))
    (native-inputs
     `(("bison" ,bison)
       ("flex" ,flex)))
    (arguments
     `(#:configure-flags
       (list (string-append "--with-boost="
                            (assoc-ref %build-inputs "boost")))
       #:parallel-tests? #f             ;There appear to be race conditions
       #:phases
       (modify-phases %standard-phases
         ,@(if (%current-target-system)
               ;; 'doc/Makefile.am' tries to run stuff even when
               ;; cross-compiling.  Explicitly skip it.
               ;; XXX: Inline this on next rebuild cycle.
               `((add-before 'build 'skip-doc-directory
                   (lambda _
                     (substitute* "Makefile"
                       (("^SUBDIRS = (.*) doc(.*)$" _ before after)
                        (string-append "SUBDIRS = " before
                                       " " after "\n")))
                     #t)))
               '())
         (add-before 'check 'patch-test-files
           (lambda _
             ;; Unpatch shebangs in test input so that source-highlight
             ;; is still able to infer input language
             (substitute* '("tests/test.sh"
                            "tests/test2.sh"
                            "tests/test.tcl")
               (((string-append "#! *" (which "sh"))) "#!/bin/sh"))
             ;; Initial patching unrecoverably removes whitespace, so
             ;; remove it also in the comparison output.
             (substitute* '("tests/test.sh.html"
                            "tests/test2.sh.html"
                            "tests/test.tcl.html")
               (("#! */bin/sh") "#!/bin/sh"))
             #t)))))
    (home-page "https://www.gnu.org/software/src-highlite/")
    (synopsis "Produce a document with syntax highlighting from a source file")
    (description
     "GNU source-highlight reads in a source code file and produces an output
file in which the keywords are highlighted in different colors to designate
their syntactic role.  It supports over 150 different languages and it can
output to 8 different formats, including HTML, LaTeX and ODF.  It can also
output to ANSI color escape sequences, so that highlighted source code can be
seen in a terminal.")
    (license gpl3+)
    (properties '((ftp-directory . "/gnu/src-highlite")))))

(define-public highlight
  (package
    (name "highlight")
    (version "3.62")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.andre-simon.de/zip/highlight-"
                           version ".tar.bz2"))
       (sha256
        (base32 "088di7qxd6b2r22qljllhnly0r9a0lfnwnfqswjn23s09awjbl6p"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                      ; no tests
       #:make-flags
       (let ((confdir (string-append %output "/share/highlight/config/")))
         (list (string-append "PREFIX=" %output)
               (string-append "HL_CONFIG_DIR=" confdir)
               (string-append "conf_dir=" confdir)))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)            ; no configure script
         (add-after 'unpack 'fix-search-for-lua
           (lambda _
             (substitute* "src/makefile"
               (("(LUA_PKG_NAME=).*" _ assignment)
                (string-append assignment "lua-" ,(version-major+minor
                                                   (package-version lua))
                               "\n")))
             (substitute* "extras/swig/makefile"
               (("lua") (string-append "lua-" ,(version-major+minor
                                                (package-version lua)))))
             #t))
         (add-after 'install 'install-perl-bindings
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((perldir (string-append (assoc-ref outputs "out")
                                            "/lib/perl5/site_perl/"
                                            ,(package-version perl)))
                    (autodir (string-append perldir "/auto/highlight")))
               (with-directory-excursion "extras/swig"
                 (invoke "make" "perl")
                 (invoke "perl" "-I" "." "testmod.pl")
                 (install-file "highlight.pm" perldir)
                 (install-file "highlight.so" autodir))
               #t))))))
    (inputs
     `(("lua" ,lua)
       ("boost" ,boost)
       ("perl" ,perl)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("swig" ,swig)))
    (home-page "http://www.andre-simon.de/doku/highlight/en/highlight.php")
    (synopsis "Convert code to documents with syntax highlighting")
    (description "Highlight converts source code to HTML, XHTML, RTF, LaTeX,
TeX, SVG, BBCode and terminal escape sequences with colored syntax
highlighting.  Language definitions and color themes are customizable.")
    (license gpl3+)))

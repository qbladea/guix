;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2018, 2019, 2020 Arun Isaac <arunisaac@systemreboot.net>
;;; Copyright © 2019, 2020 Christopher Howard <christopher@librehacker.com>
;;; Copyright © 2019, 2020 Evan Straw <evan.straw99@gmail.com>
;;; Copyright © 2020, 2021 Guillaume Le Vaillant <glv@posteo.net>
;;; Copyright © 2020 Danny Milosavljevic <dannym@scratchpost.org>
;;; Copyright © 2020 Charlie Ritter <chewzerita@posteo.net>
;;; Copyright © 2020, 2021 Tobias Geerinckx-Rice <me@tobias.gr>
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

(define-module (gnu packages radio)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages check)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages engineering)
  #:use-module (gnu packages fltk)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages logging)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages swig)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix build-system qt))

(define-public liquid-dsp
  (package
    (name "liquid-dsp")
    (version "1.3.2")
    (source
     (origin (method git-fetch)
             (uri (git-reference
                   (url "https://github.com/jgaeddert/liquid-dsp")
                   (commit (string-append "v" version))))
             (file-name (git-file-name name version))
             (sha256
              (base32 "1n6dbg13q8ga5qhg1yiszwly4jj0rxqr6f1xwm9waaly5z493xsd"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)))
    (inputs
     `(("fftw" ,fftw)
       ("fftwf" ,fftwf)))
    (home-page "https://liquidsdr.org")
    (synopsis "Signal processing library for software-defined radios")
    (description
     "Liquid DSP is a @dfn{digital signal processing} (DSP) library designed
specifically for software-defined radios on embedded platforms.  The aim is to
provide a lightweight DSP library that does not rely on a myriad of external
dependencies or proprietary and otherwise cumbersome frameworks.  All signal
processing elements are designed to be flexible, scalable, and dynamic,
including filters, filter design, oscillators, modems, synchronizers, complex
mathematical operations, and much more.")
    (license license:expat)))

(define-public rtl-sdr
  (package
    (name "rtl-sdr")
    (version "0.6.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.osmocom.org/rtl-sdr/")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0lmvsnb4xw4hmz6zs0z5ilsah5hjz29g1s0050n59fllskqr3b8k"))))
    (build-system cmake-build-system)
    (inputs
     `(("libusb" ,libusb)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (arguments
     `(#:configure-flags '("-DDETACH_KERNEL_DRIVER=ON"
                           "-DINSTALL_UDEV_RULES=ON")
       #:tests? #f ; No tests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "CMakeLists.txt"
               (("DESTINATION \"/etc/udev/")
                (string-append "DESTINATION \""
                               (assoc-ref outputs "out")
                               "/lib/udev/")))
             #t)))))
    (home-page "https://osmocom.org/projects/sdr/wiki/rtl-sdr")
    (synopsis "Software defined radio driver for Realtek RTL2832U")
    (description "DVB-T dongles based on the Realtek RTL2832U can be used as a
cheap software defined radio, since the chip allows transferring the raw I/Q
samples to the host.  @code{rtl-sdr} provides drivers for this purpose.

The default Linux driver managing DVB-T dongles as TV devices doesn't work for
SDR purposes and clashes with this package.  Therefore you must prevent the
kernel from loading it automatically by adding the following line to your
system configuration:

@lisp
(kernel-arguments '(\"modprobe.blacklist=dvb_usb_rtl28xxu\"))
@end lisp

To install the rtl-sdr udev rules, you must extend 'udev-service-type' with
this package.  E.g.: @code{(udev-rules-service 'rtl-sdr rtl-sdr)}")
    (license license:gpl2+)))

(define-public chirp
  (package
    (name "chirp")
    (version "20201121")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://trac.chirp.danplanet.com/chirp_daily/daily-"
                           version "/chirp-daily-" version ".tar.gz"))
       (sha256
        (base32 "092jryb1jn9li6zj243awv6piz1lhghqsm4phrz7j0rgqf76dy4n"))))
    (build-system python-build-system)
    (inputs
     `(("python2-libxml2" ,python2-libxml2)
       ("python2-pygtk" ,python2-pygtk)
       ("python2-pyserial" ,python2-pyserial)))
    (arguments
     `(#:python ,python-2))
    (home-page "https://chirp.danplanet.com")
    (synopsis "Cross-radio programming tool")
    (description "Chirp is a cross-radio programming tool.  It supports a
growing list of radios across several manufacturers and allows transferring of
memory contents between them.")
    (license (list license:gpl3+
                   license:lgpl3+)))) ; chirp/elib_intl.py

(define-public aptdec
  (package
    (name "aptdec")
    (version "1.7")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Xerbo/aptdec")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1hf0zb51qc6fyhdjxyij1n3vgwnw3cwksc3r11szbhkml14qjnzk"))))
    (build-system gnu-build-system)
    (inputs
     `(("libpng" ,libpng)
       ("libsndfile" ,libsndfile)))
    (arguments
     `(#:make-flags
       (list
        (string-append "CC="
                       (if ,(%current-target-system)
                           (string-append (assoc-ref %build-inputs "cross-gcc")
                                          "/bin/" ,(%current-target-system) "-gcc")
                           "gcc"))
        (string-append "PREFIX=" %output)
        (string-append "RPM_BUILD_ROOT=" %output))
       #:tests? #f ; no tests
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (install-file "atpdec" (string-append out "/bin")))
             #t)))))
    (home-page "https://github.com/Xerbo/aptdec")
    (synopsis "NOAA Automatic Picture Transmission (APT) decoder")
    (description "Aptdec decodes Automatic Picture Transmission (APT) images.
These are medium resolution images of the Earth transmitted by, among other
satellites, the POES NOAA weather satellite series.  These transmissions are
on a frequency of 137 MHz.  They can be received using an inexpensive antenna
and a dedicated receiver.")
    (license license:gpl2+)))

(define-public redsea
  (package
    (name "redsea")
    (version "0.18")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/windytan/redsea")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1y96g0ra2krjb2kypm8s5gdfia45yci4f36klsvyzg8d53v5cwhn"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; The configure.ac file does not explicitly link against libiconv
         ;; except on Mac OS, causing the build to fail. This phase comments
         ;; out the original AC_SUBST macro (located inside a conditional) and
         ;; adds an explicit use of it underneath, so that libiconv is always
         ;; linked against.
         (add-after 'unpack 'patch-libiconv
           (lambda _
             (substitute* "configure.ac"
               (("^ +AC_SUBST")
                "# AC_SUBST")
               (("esac")
                "esac\nAC_SUBST([ICONV], [\"-liconv\"])"))
             #t)))))
    (inputs
     `(("libiconv" ,libiconv)
       ("libsndfile" ,libsndfile)
       ("liquid-dsp" ,liquid-dsp)))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)))
    (home-page "https://github.com/windytan/redsea")
    (synopsis "Lightweight RDS to JSON decoder")
    (description "redsea is a lightweight command-line @dfn{FM Radio Data
System} (FM-RDS) decoder.  Redsea can be used with any RTL-SDR USB radio stick
with the rtl_fm tool, or any other @dfn{software-defined radio} (SDR) via
csdr, for example.  It can also decode raw ASCII bitstream, the hex format
used by RDS Spy, and audio files containing @dfn{multiplex} signals (MPX).")
    (license license:expat)))

(define-public gnuradio
  (package
    (name "gnuradio")
    (version "3.8.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://www.gnuradio.org/releases/gnuradio/"
                           "gnuradio-" version ".tar.xz"))
       (sha256
        (base32 "0aw55gf5549b0fz2qdi7vplcmaf92bj34h40s34b2ycnqasv900r"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Delete bundled volk to use the shared one.
           (delete-file-recursively "volk")
           #t))))
    (build-system cmake-build-system)
    (native-inputs
     `(("doxygen" ,doxygen)
       ("ghostscript" ,ghostscript)
       ("orc" ,orc)
       ("pkg-config" ,pkg-config)
       ("python-cheetah" ,python-cheetah)
       ("python-mako" ,python-mako)
       ("python-pyzmq" ,python-pyzmq)
       ("python-scipy" ,python-scipy)
       ("python-sphinx" ,python-sphinx)
       ("swig" ,swig)
       ("texlive" ,(texlive-union (list texlive-amsfonts
                                        texlive-latex-amsmath
                                        ;; TODO: Add newunicodechar.
                                        texlive-latex-graphics)))
       ("xorg-server" ,xorg-server-for-tests)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("boost" ,boost)
       ("cairo" ,cairo)
       ("codec2" ,codec2)
       ("cppzmq" ,cppzmq)
       ("fftwf" ,fftwf)
       ("gmp" ,gmp)
       ("gsl" ,gsl)
       ("gsm" ,gsm)
       ("gtk+" ,gtk+)
       ("jack" ,jack-1)
       ("log4cpp" ,log4cpp)
       ("pango" ,pango)
       ("portaudio" ,portaudio)
       ("python" ,python)
       ("python-click" ,python-click)
       ("python-click-plugins" ,python-click-plugins)
       ("python-lxml" ,python-lxml)
       ("python-numpy" ,python-numpy)
       ("python-pycairo" ,python-pycairo)
       ("python-pygobject" ,python-pygobject)
       ("python-pyqt" ,python-pyqt)
       ("python-pyyaml" ,python-pyyaml)
       ("qtbase" ,qtbase)
       ("qwt" ,qwt)
       ("volk" ,volk)
       ("zeromq" ,zeromq)))
    (arguments
     `(#:modules ((guix build cmake-build-system)
                  ((guix build glib-or-gtk-build-system) #:prefix glib-or-gtk:)
                  ((guix build python-build-system) #:prefix python:)
                  (guix build utils)
                  (ice-9 match))
       #:imported-modules (,@%cmake-build-system-modules
                           (guix build glib-or-gtk-build-system)
                           (guix build python-build-system))
       #:configure-flags
       '("-DENABLE_INTERNAL_VOLK=OFF")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-paths
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((qwt (assoc-ref inputs "qwt")))
               (substitute* "cmake/Modules/FindQwt.cmake"
                 (("/usr/include")
                  (string-append qwt "/include"))
                 (("/usr/lib")
                  (string-append qwt "/lib"))
                 (("qwt6-\\$\\{QWT_QT_VERSION\\}")
                  "qwt")))
             (substitute* "cmake/Modules/GrPython.cmake"
               (("dist-packages")
                "site-packages"))
             (substitute* '("gr-vocoder/swig/vocoder_swig.i"
                            "gr-vocoder/include/gnuradio/vocoder/codec2.h"
                            "gr-vocoder/include/gnuradio/vocoder/freedv_api.h")
               (("<codec2/")
                "<"))
             #t))
         (add-before 'check 'set-test-environment
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "HOME" "/tmp")
             (system (string-append (assoc-ref inputs "xorg-server")
                                    "/bin/Xvfb :1 &"))
             (setenv "DISPLAY" ":1")
             #t))
         (add-after 'install 'wrap-python
           (assoc-ref python:%standard-phases 'wrap))
         (add-after 'wrap-python 'wrap-glib-or-gtk
           (assoc-ref glib-or-gtk:%standard-phases 'glib-or-gtk-wrap))
         (add-after 'wrap-glib-or-gtk 'wrap-with-GI_TYPELIB_PATH
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (paths (map (match-lambda
                                 ((output . directory)
                                  (let ((girepodir (string-append
                                                    directory
                                                    "/lib/girepository-1.0")))
                                    (if (file-exists? girepodir)
                                        girepodir
                                        #f))))
                               inputs)))
               (wrap-program (string-append out "/bin/gnuradio-companion")
                 `("GI_TYPELIB_PATH" ":" prefix ,(filter identity paths))))
             #t)))))
    (native-search-paths
     ;; Variables required to find third-party plugins at runtime.
     (list (search-path-specification
            (variable "GRC_BLOCKS_PATH")
            (files '("share/gnuradio/grc/blocks")))
           (search-path-specification
            (variable "PYTHONPATH")
            (files (list (string-append "lib/python"
                                        (version-major+minor
                                         (package-version python))
                                        "/site-packages"))))))
    (synopsis "Toolkit for software-defined radios")
    (description
     "GNU Radio is a development toolkit that provides signal processing blocks
to implement software radios.  It can be used with external RF hardware to
create software-defined radios, or without hardware in a simulation-like
environment.")
    (home-page "https://www.gnuradio.org")
    (license license:gpl3+)))

(define-public gnuradio-osmosdr
  (package
    (name "gnuradio-osmosdr")
    (version "0.2.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.osmocom.org/gr-osmosdr")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1aqj5cylipmmjh1x1kb2j8262hxq6mi86dgb2zphj94wvsab2ghx"))))
    (build-system cmake-build-system)
    (native-inputs
     `(("doxygen" ,doxygen)
       ("pkg-config" ,pkg-config)
       ("python" ,python)
       ("python-mako" ,python-mako)
       ("python-six" ,python-six)
       ("swig" ,swig)))
    (inputs
     `(("boost" ,boost)
       ("fftwf" ,fftwf)
       ("gmp" ,gmp)
       ("gnuradio" ,gnuradio)
       ("hackrf" ,hackrf)
       ("log4cpp" ,log4cpp)
       ("rtl-sdr" ,rtl-sdr)
       ("volk" ,volk)))
    (synopsis "GNU Radio block for interfacing with various radio hardware")
    (description "This is a block for GNU Radio allowing to use a common API
to access different radio hardware.")
    (home-page "https://osmocom.org/projects/gr-osmosdr/wiki/GrOsmoSDR")
    (license license:gpl3+)))

(define-public libosmo-dsp
  (package
    (name "libosmo-dsp")
    (version "0.4.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.osmocom.org/libosmo-dsp")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "00plihnpym1gkfpflah8il9463qxzm9kx2f07jyvbkszpj8viq5g"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("bash-minimal" ,bash-minimal)
       ("doxygen" ,doxygen)
       ("libtool" ,libtool)
       ("pkg-config" ,pkg-config)
       ("texlive" ,(texlive-union (list texlive-amsfonts
                                        texlive-latex-amsmath
                                        ;; TODO: Add newunicodechar.
                                        texlive-latex-graphics)))))
    (inputs
     `(("fftwf" ,fftwf)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-paths
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "git-version-gen"
               (("/bin/sh")
                (string-append (assoc-ref inputs "bash")
                               "/bin/bash")))
             #t)))))
    (synopsis "DSP primitives for SDR")
    (description
     "This a C-language library for common DSP (Digital Signal Processing)
primitives for SDR (Software Defined Radio).")
    (home-page "https://osmocom.org/projects/libosmo-dsp")
    (license license:gpl2+)))

(define-public gnuradio-iqbalance
  (package
    (name "gnuradio-iqbalance")
    (version "0.38.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.osmocom.org/gr-iqbal")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ksagwz05p3b0702q7ljq7013xmp0ijp30my9z6s3p7ja8dj42s3"))))
    (build-system cmake-build-system)
    (native-inputs
     `(("doxygen" ,doxygen)
       ("pkg-config" ,pkg-config)
       ("python" ,python)
       ("python-numpy" ,python-numpy)
       ("python-six" ,python-six)
       ("swig" ,swig)))
    (inputs
     `(("boost" ,boost)
       ("fftwf" ,fftwf)
       ("gmp" ,gmp)
       ("gnuradio" ,gnuradio)
       ("libosmo-dsp" ,libosmo-dsp)
       ("log4cpp" ,log4cpp)
       ("volk" ,volk)))
    (synopsis "GNU Radio block to correct IQ imbalance")
    (description
     "This is a GNU Radio block to correct IQ imbalance in quadrature
receivers.  It's composed of two main block:
@itemize
@item Fix: Given a phase and amplitude error, it will correct a complex signal.
@item Optimize: Attempts to auto-detect the phase and amplitude error to feed
to the fix block above.
@end itemize")
    (home-page "https://git.osmocom.org/gr-iqbal/")
    (license license:gpl3+)))

(define-public gqrx
  (package
    (name "gqrx")
    (version "2.14.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/csete/gqrx")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0m4ncydihz4n4i80c252vk3c5v672yab1jv85n6ndn7a92xv3ilq"))))
    (build-system qt-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("boost" ,boost)
       ("fftwf" ,fftwf)
       ("gmp" ,gmp)
       ("gnuradio" ,gnuradio)
       ("gnuradio-iqbalance" ,gnuradio-iqbalance)
       ("gnuradio-osmosdr" ,gnuradio-osmosdr)
       ("jack" ,jack-1)
       ("log4cpp" ,log4cpp)
       ("portaudio" ,portaudio)
       ("pulseaudio" ,pulseaudio)
       ("qtbase" ,qtbase)
       ("qtsvg" ,qtsvg)
       ("volk" ,volk)))
    (arguments
     `(#:tests? #f))                    ; no tests
    (synopsis "Software defined radio receiver")
    (description "Gqrx is a software defined radio (SDR) receiver implemented
using GNU Radio and the Qt GUI toolkit.")
    (home-page "https://gqrx.dk/")
    (license license:gpl3+)))

(define-public fldigi
  (package
    (name "fldigi")
    (version "4.1.18")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/fldigi/fldigi")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "177qnl1bxy46rqwdxizfy2i3mxk5bzz733cp445rfzl7b6yf6zrn"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("gettext" ,gettext-minimal)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("fltk" ,fltk)
       ("hamlib" ,hamlib)
       ("libpng" ,libpng)
       ("libsamplerate" ,libsamplerate)
       ("libusb" ,libusb)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxft" ,libxft)
       ("portaudio" ,portaudio)
       ("pulseaudio" ,pulseaudio)))
    (synopsis "Software modem for amateur radio use")
    (description
     "Fldigi is a software modem for amateur radio use.  It is a sound card
based program that is used for both transmitting and receiving data by
connecting the microphone and headphone connections of a computer to some radio
hardware.")
    (home-page "http://www.w1hkj.com/")
    (license license:gpl3+)))

(define-public flrig
  (package
    (name "flrig")
    (version "1.3.52")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/fldigi/flrig")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0vxn1wy5b2zfq20k93rfgq34m1nd3mxd74h8l98f90d85fhcqggy"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("fltk" ,fltk)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxft" ,libxft)))
    (synopsis "Radio transceiver control program")
    (description
     "Flrig is a transceiver control program for amateur radio use.
It provides computer aided control of various radios using a serial
or USB connection.")
    (home-page "http://www.w1hkj.com/")
    (license license:gpl3+)))

(define-public flamp
  (package
    (name "flamp")
    (version "2.2.05")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/fldigi/flamp")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ll2wbhyh1sb4iqsypwrd118mrgw3vbsdbz442qhk4r6l8kjzblq"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("fltk" ,fltk)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxft" ,libxft)))
    (synopsis "Tool for AMP file transfer")
    (description
     "FLAMP is a program for transferring files by radio waves using AMP
(Amateur Multicast Protocol).")
    (home-page "http://www.w1hkj.com/")
    (license license:gpl3+)))

(define-public flwrap
  (package
    (name "flwrap")
    (version "1.3.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/fldigi/flwrap")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0xkhr82smfr7wpb9xl05wf7bz3vi2mr4xkcr2s8v6mblhgsdhqwg"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("fltk" ,fltk)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxft" ,libxft)))
    (synopsis "File encapsulation program")
    (description
     "Flwrap is a software utility for amateur radio use.  Its purpose is to
encapsulate both text and binary files in a way that allows them to be
transmitted over any of several digital modes and verified at the receipt end
for correctness.")
    (home-page "http://www.w1hkj.com/")
    (license license:gpl3+)))

(define-public hackrf
  ;; Using a git commit because there have been many many commits
  ;; since the relase two years ago, but no sign of a promised
  ;; release for many months now.
  (let ((commit "43e6f99fe8543094d18ff3a6550ed2066c398862")
        (revision "0"))
    (package
     (name "hackrf")
     (version (git-version "2018.01.1" revision commit))
     (source
      (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/mossmann/hackrf")
             (commit commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0avnv693xi0zsnrvkbfn0ln1r3s1iyj0bz7sc3gxay909av0pvbc"))))
     (build-system cmake-build-system)
     (arguments
      '(#:configure-flags
        (list "-DUDEV_RULES_GROUP=dialout"
              (string-append "-DUDEV_RULES_PATH="
                             (assoc-ref %outputs "out")
                             "/lib/udev/rules.d"))
        #:phases
        (modify-phases %standard-phases
          (add-before 'configure 'enter-source-directory
            (lambda _
              (chdir "host")
              #t))
          (add-after 'install 'delete-static-library
            (lambda* (#:key outputs #:allow-other-keys)
              (delete-file (string-append (assoc-ref outputs "out")
                                          "/lib/libhackrf.a"))
              #t))
          (add-before 'install-license-files 'leave-source-directory
            (lambda _
              (chdir "..")
              #t)))
        #:tests? #f)) ; no test suite
     (native-inputs
      `(("pkg-config" ,pkg-config)))
     (inputs
      `(("fftw" ,fftw)
        ("fftwf" ,fftwf)
        ("libusb" ,libusb)))
     (home-page "https://greatscottgadgets.com/hackrf/")
     (synopsis "User-space library and utilities for HackRF SDR")
     (description
      "Command line utilities and a C library for controlling the HackRF
Software Defined Radio (SDR) over USB.  Installing this package installs the
userspace hackrf utilities and C library.  To install the hackrf udev rules,
you must extend 'udev-service-type' with this package.  E.g.:
@code{(udev-rules-service 'hackrf hackrf #:groups '(\"dialout\"))}.")
     (license license:gpl2))))

(define-public hamlib
  (package
    (name "hamlib")
    (version "3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/Hamlib/Hamlib/releases/download/"
             version "/hamlib-" version ".tar.gz"))
       (sha256
        (base32 "10788mgrhbc57zpzakcxv5aqnr2819pcshml6fbh8zvnkja562y9"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("doxygen" ,doxygen)
       ("lua" ,lua)
       ("pkg-config" ,pkg-config)
       ("python-wrapper" ,python-wrapper)
       ("swig" ,swig)
       ("tcl" ,tcl)))
    (inputs
     `(("gd" ,gd)
       ("libusb" ,libusb)
       ("libxml2" ,libxml2)
       ("readline" ,readline)))
    (arguments
     `(#:configure-flags '("--disable-static"
                           "--with-lua-binding"
                           "--with-python-binding"
                           "--with-tcl-binding"
                           "--with-xml-support")))
    (synopsis "Tools and API to control radios")
    (description
     "The Ham Radio Control Library (Hamlib) is a project to provide programs
with a consistent Application Programming Interface (API) for controlling the
myriad of radios and rotators available to amateur radio and communications
users.")
    (home-page "https://hamlib.github.io/")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define wsjtx-hamlib
  ;; Fork of hamlib with custom patches used by wsjtx.
  (package
    (inherit hamlib)
    (name "wsjtx-hamlib")
    (version "2.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/u/bsomervi/hamlib.git")
             (commit (string-append "wsjtx-" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ampwqs7p0g8pdnwpdrbvwyqag065n96amgb3v4z332nw0nxvm10"))))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libtool" ,libtool)
       ("texinfo" ,texinfo)
       ,@(package-native-inputs hamlib)))
    (arguments
     `(#:configure-flags '("--disable-static"
                           "--with-lua-binding"
                           "--with-python-binding"
                           "--with-tcl-binding"
                           "--with-xml-support")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-tests
           (lambda _
             (substitute* "tests/testloc.c"
               (("dmmm2dec\\(deg, mmm, nesw\\);")
                "dmmm2dec(deg, mmm, 0, nesw);"))
             #t)))))))

(define-public wsjtx
  (package
    (name "wsjtx")
    (version "2.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/wsjt/wsjtx.git")
             (commit (string-append "wsjtx-" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1qf8r88ssara3pddvd3jpv5phzxwnanvdj00dxgmzq0c2jqcy2a8"))))
    (build-system qt-build-system)
    (native-inputs
     `(("asciidoc" ,asciidoc)
       ("gfortran" ,gfortran)
       ("pkg-config" ,pkg-config)
       ("qttools" ,qttools)
       ("ruby-asciidoctor" ,ruby-asciidoctor)))
    (inputs
     `(("boost" ,boost)
       ("fftw" ,fftw)
       ("fftwf" ,fftwf)
       ("hamlib" ,wsjtx-hamlib)
       ("libusb" ,libusb)
       ("qtbase" ,qtbase)
       ("qtmultimedia" ,qtmultimedia)
       ("qtserialport" ,qtserialport)))
    (arguments
     `(#:tests? #f ; No test suite
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'work-around-runtime-bug
           (lambda _
             ;; Some of the programs in this package fail to find symbols
             ;; in libm at runtime. Adding libm manually at the end of the
             ;; library lists when linking the programs seems to help.
             ;; TODO: find exactly what is wrong in the way the programs
             ;; are built.
             (substitute* "CMakeLists.txt"
               (("target_link_libraries \\((.*)\\)" all libs)
                (string-append "target_link_libraries (" libs " m)")))
             #t)))))
    (synopsis "Weak-signal ham radio communication program")
    (description
     "WSJT-X implements communication protocols or modes called FT4, FT8,
JT4, JT9, JT65, QRA64, ISCAT, MSK144, and WSPR, as well as one called Echo for
detecting and measuring your own radio signals reflected from the Moon.  These
modes were all designed for making reliable, confirmed QSOs under extreme
weak-signal conditions.")
    (home-page "https://www.physics.princeton.edu/pulsar/k1jt/wsjtx.html")
    (license license:gpl3)))

(define-public js8call
  (package
    (inherit wsjtx)
    (name "js8call")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://files.js8call.com/" version
                           "/js8call-" version ".tgz"))
       (sha256
        (base32 "149sjwc4zg6ckgq26af93p4fxappa4k9dh7rdy67g8ajfjad4cd8"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Delete bundled boost to use the shared one.
           (delete-file-recursively "boost")
           #t))))
    (build-system qt-build-system)
    (native-inputs
     `(("asciidoc" ,asciidoc)
       ("gfortran" ,gfortran)
       ("pkg-config" ,pkg-config)
       ("qttools" ,qttools)
       ("ruby-asciidoctor" ,ruby-asciidoctor)))
    (inputs
     `(("boost" ,boost)
       ("fftw" ,fftw)
       ("fftwf" ,fftwf)
       ("hamlib" ,wsjtx-hamlib)
       ("libusb" ,libusb)
       ("qtbase" ,qtbase)
       ("qtmultimedia" ,qtmultimedia)
       ("qtserialport" ,qtserialport)))
    (arguments
     `(#:tests? #f ; No test suite
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "CMakeLists.txt"
               (("DESTINATION /usr/share")
                (string-append "DESTINATION "
                               (assoc-ref outputs "out")
                               "/share")))
             #t))
         (add-after 'fix-paths 'work-around-runtime-bug
           (lambda _
             ;; Some of the programs in this package fail to find symbols
             ;; in libm at runtime. Adding libm manually at the end of the
             ;; library lists when linking the programs seems to help.
             ;; TODO: find exactly what is wrong in the way the programs
             ;; are built.
             (substitute* "CMakeLists.txt"
               (("target_link_libraries \\((.*)\\)" all libs)
                (string-append "target_link_libraries (" libs " m)")))
             #t))
         (add-after 'unpack 'fix-hamlib
           (lambda _
             (substitute* "CMake/Modules/Findhamlib.cmake"
               (("set \\(ENV\\{PKG_CONFIG_PATH\\}.*\\)")
                "set (__pc_path $ENV{PKG_CONFIG_PATH})
  list (APPEND __pc_path \"${__hamlib_pc_path}\")
  set (ENV{PKG_CONFIG_PATH} \"${__pc_path}\")"))
             (substitute* "HamlibTransceiver.hpp"
               (("#ifdef JS8_USE_LEGACY_HAMLIB")
                "#if 1"))
             #t)))))
    (synopsis "Weak-signal ham radio communication program")
    (description
     "JS8Call is a software using the JS8 digital mode (a derivative of the FT8
mode) providing weak signal keyboard to keyboard messaging to amateur radio
operators.")
    (home-page "http://js8call.com/")
    (license license:gpl3)))

(define-public xnec2c
  (package
    (name "xnec2c")
    (version "4.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.5b4az.org/pkg/nec2/xnec2c/xnec2c-"
                           version ".tar.bz2"))
       (sha256
        (base32 "1myvlkfybb2ha8l0h96ca3iz206zzy9z5iizm0sbab2zzp78n1r9"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("gtk+" ,gtk+)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-makefile
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* '("Makefile.am" "Makefile.in")
               ;; The DESTDIR variable does not get replaced the prefix
               ;; in the final Makefile, so let's do here.
               (("\\$\\(DESTDIR\\)/usr")
                (assoc-ref outputs "out")))
             #t))
         (add-after 'fix-makefile 'fix-paths
           (lambda* (#:key outputs #:allow-other-keys)
             ;; Increase the max length of the path to the glade file,
             ;; so that the '/gnu/store/...' path can fit in.
             (substitute* '("src/shared.c" "src/shared.h")
               (("char xnec2c_glade\\[64\\];")
                "char xnec2c_glade[256];"))
             ;; Fix hard coded references to '/usr/...'.
             (substitute* '("src/geom_edit.c" "src/main.c")
               (("\"/usr")
                (string-append "\"" (assoc-ref outputs "out"))))
             #t)))))
    (synopsis "Antenna modeling software")
    (description
     "Xnec2c is a GTK3-based graphical version of nec2c, a translation to the
C language of NEC2, the FORTRAN Numerical Electromagnetics Code commonly used
for antenna simulation and analysis.  It can be used to define the geometry of
an antenna, and then plot the radiation pattern or frequency-related data like
gain and standing wave ratio.")
    (home-page "http://www.5b4az.org/")
    (license license:gpl3+)))

(define-public dump1090
  (package
    (name "dump1090")
    (version "4.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/flightaware/dump1090")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1zacsqaqsiapljhzw31dwc4nld2rp98jm3ivkyznrhzk9n156p42"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("libusb" ,libusb)
       ("ncurses" ,ncurses)
       ("rtl-sdr" ,rtl-sdr)))
    (arguments
     `(#:test-target "test"
       #:make-flags
       (list (string-append "CC=" ,(cc-for-target))
             "BLADERF=no")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
               (install-file "dump1090" bin)
               (install-file "view1090" bin)
               #t))))))
    (synopsis "Mode S decoder for rtl-sdr devices")
    (description
     "Dump1090 is a Mode S decoder specifically designed for rtl-sdr devices.
It can be used to decode the ADS-B signals that planes emit to indicate
their position, altitude, speed, etc.")
    (home-page "https://github.com/flightaware/dump1090")
    (license license:gpl2+)))

(define-public rtl-433
  (package
    (name "rtl-433")
    (version "20.11")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/merbanan/rtl_433")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "093bxjxkg7yf78wqj5gpijbfa2p05ny09qqsj84kzi1svnzsa369"))))
    (build-system cmake-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("libusb" ,libusb)
       ("rtl-sdr" ,rtl-sdr)))
    (synopsis "Decoder for radio transmissions in ISM bands")
    (description
     "This is a generic data receiver, mainly for decoding radio transmissions
from devices on the 433 MHz, 868 MHz, 315 MHz, 345 MHz and 915 MHz ISM bands.")
    (home-page "https://github.com/merbanan/rtl_433")
    (license license:gpl2+)))

(define-public multimon-ng
  (package
    (name "multimon-ng")
    (version "1.1.9")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/EliasOenal/multimon-ng")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "01716cfhxfzsab9zjply9giaa4nn4b7rm3p3vizrwi7n253yiwm2"))))
    (build-system cmake-build-system)
    (inputs
     `(("libx11" ,libx11)
       ("pulseaudio" ,pulseaudio)))
    (arguments
     '(#:tests? #f))                    ; no test suite
    (home-page "https://github.com/EliasOenal/multimon-ng")
    (synopsis "Decoder for digital radio transmission modes")
    (description "Multimon-ng can decode several digital radio transmission
modes:
@itemize
@item POCSAG512, POCSAG1200, POCSAG2400
@item FLEX
@item EAS
@item UFSK1200, CLIPFSK, AFSK1200, AFSK2400, AFSK2400_2, AFSK2400_3
@item HAPN4800
@item FSK9600
@item DTMF
@item ZVEI1, ZVEI2, ZVEI3, DZVEI, PZVEI
@item EEA, EIA, CCIR
@item MORSE CW
@item X10
@end itemize")
    (license license:gpl2+)))

(define-public nanovna-saver
  (package
    (name "nanovna-saver")
    (version "0.3.8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/NanoVNA-Saver/nanovna-saver")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0z83rwpnbbs1n74mx8dgh1d1crp90mannj9vfy161dmy4wzc5kpv"))))
    (build-system python-build-system)
    (native-inputs
     `(("python-cython" ,python-cython)))
    (inputs
     `(("python-numpy" ,python-numpy)
       ("python-pyqt" ,python-pyqt)
       ("python-pyserial" ,python-pyserial)
       ("python-scipy" ,python-scipy)))
    (arguments
     '(#:tests? #f))
    (home-page "https://github.com/NanoVNA-Saver/nanovna-saver")
    (synopsis "GUI for NanoVNA devices")
    (description
     "NanoVNA-Saver is a tool for reading, displaying and saving data from the
NanoVNA vector network analyzers.")
    (license license:gpl3+)))

(define-public qsstv
  (package
    (name "qsstv")
    (version "9.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://users.telenet.be/on4qz/qsstv/downloads/"
                           "qsstv_" version ".tar.gz"))
       (sha256
        (base32 "0f9hx6sy418cb23fadll298pqbc5l2lxsdivi4vgqbkvx7sw58zi"))))
    (build-system qt-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("fftw" ,fftw)
       ("fftwf" ,fftwf)
       ("hamlib" ,hamlib)
       ("openjpeg" ,openjpeg)
       ("pulseaudio" ,pulseaudio)
       ("qtbase" ,qtbase)
       ("v4l-utils" ,v4l-utils)))
    (arguments
     `(#:tests? #f  ; No test suite.
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (invoke "qmake"
                     (string-append "PREFIX=" (assoc-ref outputs "out")))
             #t)))))
    (home-page "http://users.telenet.be/on4qz/qsstv/")
    (synopsis "Program for receiving and transmitting SSTV and HAMDRM")
    (description
     "QSSTV is a program for receiving and transmitting SSTV and HAMDRM
(sometimes called DSSTV).  It is compatible with most of MMSSTV and EasyPal.")
    (license (list license:gpl2+
                   license:qwt1.0))))

(define-public direwolf
  (package
    (name "direwolf")
    (version "1.6")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/wb2osz/direwolf")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0xmz64m02knbrpasfij4rrq53ksxna5idxwgabcw4n2b1ig7pyx5"))))
    (build-system cmake-build-system)
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("hamlib" ,hamlib)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "conf/CMakeLists.txt"
               (("DESTINATION /etc")
                (string-append "DESTINATION "
                               (assoc-ref outputs "out")
                               "/etc"))))))))
    (home-page "https://github.com/wb2osz/direwolf")
    (synopsis "TNC for Amateur Packet Radio")
    (description
     "Dire Wolf is a Terminal Node Controller (TNC) for Amateur Packet Radio.
It can perform as:
@itemize
@item APRS GPS tracker,
@item Digipeater,
@item Internet gateway (IGate)
@item APRStt gateway
@end itemize\n")
    (license license:gpl2+)))

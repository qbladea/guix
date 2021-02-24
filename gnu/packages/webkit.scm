;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2015 David Hashe <david.hashe@dhashe.com>
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015, 2016, 2017, 2018, 2019, 2020 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2018, 2019, 2020 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2019 Marius Bakke <mbakke@fastmail.com>
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

(define-module (gnu packages webkit)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libreoffice)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages virtualization)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define-public libwpe
  (package
    (name "libwpe")
    (version "1.6.0")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://wpewebkit.org/releases/libwpe-"
                       version ".tar.xz"))
       (sha256
        (base32 "141w35b488jjhanl3nrm0awrbcy6hb579fk8n9vbpx07m2wcd1rm"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f))                    ;no tests
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("python" ,python-wrapper)))
    (inputs
     `(("mesa" ,mesa)))
    (propagated-inputs
     `(("libxkbcommon" ,libxkbcommon)))
    (synopsis "General-purpose library for WPE")
    (description "LibWPE is general-purpose library specifically developed for
the WPE-flavored port of WebKit.")
    (home-page "https://wpewebkit.org/")
    (license license:bsd-2)))

(define-public wpebackend-fdo
  (package
    (name "wpebackend-fdo")
    (version "1.6.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://wpewebkit.org/releases/"
                                  "wpebackend-fdo-" version ".tar.xz"))
              (sha256
               (base32
                "1jdi43gciqjgvhnqxs160f3hmp1hkqhrllb0hhmldyxc4wryw3kl"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f))                    ;no tests
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)
       ("libwpe" ,libwpe)
       ("mesa" ,mesa)
       ("wayland" ,wayland)))
    (home-page "https://wpewebkit.org/")
    (synopsis "Wayland WPE backend")
    (description
     "This package provides a backend implementation for the WPE WebKit
engine that uses Wayland for graphics output.")
    (license license:bsd-2)))

(define-public wpewebkit
  (package
    (name "wpewebkit")
    (version "2.28.3")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://wpewebkit.org/releases/"
                       name "-" version ".tar.xz"))
       (sha256
        (base32 "12z9457ja1xm93kl3gpd6nvd5xn11mvm8pr0w2zhmh3k9lx2cf95"))))
    (build-system cmake-build-system)
    (outputs '("out" "doc"))
    (arguments
     `(#:tests? #f                      ; XXX: To be enabled
       #:configure-flags
       (list
        "-DPORT=WPE"
        ;; XXX: To be enabled.
        ;; "-DENABLE_ACCELERATED_2D_CANVAS=ON"
        "-DENABLE_ENCRYPTED_MEDIA=ON"
        "-DENABLE_GTKDOC=ON")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'setenv
           (lambda _
             (setenv "HOME" "/tmp")
             #t))
         (add-after 'unpack 'patch-docbook-xml
           (lambda* (#:key inputs #:allow-other-keys)
             (for-each
              (lambda (file)
                (substitute* file
                  (("http://www.oasis-open.org/docbook/xml/4.1.2/docbookx.dtd")
                   (string-append (assoc-ref inputs "docbook-xml")
                                  "/xml/dtd/docbook/docbookx.dtd"))))
              (find-files "Source" "\\.sgml$"))
             #t))
         (add-after 'install 'move-doc-files
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (doc (assoc-ref outputs "doc")))
               (mkdir-p (string-append doc "/share"))
               (rename-file
                (string-append out "/share/gtk-doc")
                (string-append doc "/share/gtk-doc"))
               #t))))))
    (native-inputs
     `(("docbook-xml" ,docbook-xml-4.1.2)
       ("docbook-xsl" ,docbook-xsl)
       ("glib:bin" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)
       ("gtk-doc" ,gtk-doc)
       ("perl" ,perl)
       ("pkg-config" ,pkg-config)
       ("python" ,python-wrapper)
       ("python2" ,python-2.7)
       ("ruby" ,ruby)))
    (inputs
     `(("atk" ,atk)
       ("atk-bridge" ,at-spi2-atk)
       ("bubblewrap" ,bubblewrap)
       ("cairo" ,cairo)
       ("fontconfig" ,fontconfig)
       ("freetype" ,freetype)
       ("gperf" ,gperf)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)
       ("harfbuzz" ,harfbuzz)
       ("icu" ,icu4c)
       ("libepoxy" ,libepoxy)
       ("libgcrypt" ,libgcrypt)
       ("libjpeg" ,libjpeg-turbo)
       ("libpng" ,libpng)
       ("libseccomp" ,libseccomp)
       ("libtasn1" ,libtasn1)
       ("libxml2" ,libxml2)
       ("libxslt" ,libxslt)
       ("mesa" ,mesa)
       ("openjpeg" ,openjpeg)
       ("sqlite" ,sqlite)
       ("webp" ,libwebp)
       ("woff2" ,woff2)
       ("xdg-dbus-proxy" ,xdg-dbus-proxy)
       ("zlib" ,zlib)))
    (propagated-inputs
     `(("glib" ,glib)
       ("libsoup" ,libsoup)
       ("wpe" ,libwpe)))
    (synopsis "WebKit port optimized for embedded devices")
    (description "WPE WebKit allows embedders to create simple and performant
systems based on Web platform technologies.  It is designed with hardware
acceleration in mind, leveraging common 3D graphics APIs for best performance.")
    (home-page "https://wpewebkit.org/")
    (license
     (list
      ;; Rendering and JavaScript Engines.
      license:lgpl2.1+
      ;; Others
      license:bsd-2))))

(define-public webkitgtk
  (package
    (name "webkitgtk")
    (version "2.30.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.webkitgtk.org/releases/"
                                  "webkitgtk-" version ".tar.xz"))
              (sha256
               (base32
                "07vzbbnvz69rn9pciji4axfpclp98bpj4a0br2z0gbn5wc4an3bx"))
              (patches (search-patches "webkitgtk-share-store.patch"
                                       "webkitgtk-bind-all-fonts.patch"))))
    (build-system cmake-build-system)
    (outputs '("out" "doc"))
    (arguments
     '(#:tests? #f ; no tests
       #:build-type "Release" ; turn off debugging symbols to save space
       #:configure-flags (list
                          "-DPORT=GTK"
                          "-DENABLE_GTKDOC=ON" ; No doc by default
                          "-DUSE_SYSTEMD=OFF"
                          (string-append ; uses lib64 by default
                           "-DLIB_INSTALL_DIR="
                           (assoc-ref %outputs "out") "/lib")

                          ;; XXX Adding GStreamer GL support would apparently
                          ;; require adding gst-plugins-bad to the inputs,
                          ;; which might entail a security risk as a result of
                          ;; the plugins of dubious code quality that are
                          ;; included.  More investigation is needed.  For
                          ;; now, we explicitly disable it to prevent an error
                          ;; at configuration time.
                          "-DUSE_GSTREAMER_GL=OFF"

                          ;; XXX Disable WOFF2 ‘web fonts’.  These were never
                          ;; supported in our previous builds.  Enabling them
                          ;; requires building libwoff2 and possibly woff2dec.
                          "-DUSE_WOFF2=OFF")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'configure-bubblewrap-store-directory
           (lambda _
             ;; This phase is a corollary to 'webkitgtk-share-store.patch' to
             ;; avoid hard coding /gnu/store, for users with other prefixes.
             (let ((store-directory (%store-directory)))
               (substitute*
                   "Source/WebKit/UIProcess/Launcher/glib/BubblewrapLauncher.cpp"
                 (("@storedir@") store-directory))
               #t)))
         (add-after 'unpack 'patch-gtk-doc-scan
           (lambda* (#:key inputs #:allow-other-keys)
             (for-each (lambda (file)
                         (substitute* file
                           (("http://www.oasis-open.org/docbook/xml/4.1.2/docbookx.dtd")
                            (string-append (assoc-ref inputs "docbook-xml")
                                           "/xml/dtd/docbook/docbookx.dtd"))))
                       (find-files "Source" "\\.sgml$"))
             #t))
         (add-after 'unpack 'embed-absolute-wpebackend-reference
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((wpebackend-fdo (assoc-ref inputs "wpebackend-fdo")))
               (substitute* "Source/WebKit/UIProcess/glib/WebProcessPoolGLib.cpp"
                 (("libWPEBackend-fdo-([\\.0-9]+)\\.so" all version)
                  (string-append wpebackend-fdo "/lib/" all)))
               #t)))
         (add-after 'install 'move-doc-files
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (doc (assoc-ref outputs "doc")))
               (mkdir-p (string-append doc "/share"))
               (rename-file (string-append out "/share/gtk-doc")
                            (string-append doc "/share/gtk-doc"))
               #t))))))
    (native-inputs
     `(("bison" ,bison)
       ("gettext" ,gettext-minimal)
       ("glib:bin" ,glib "bin") ; for glib-mkenums, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("gperf" ,gperf)
       ("perl" ,perl)
       ("pkg-config" ,pkg-config)
       ("python" ,python-wrapper)
       ("gtk-doc" ,gtk-doc) ; For documentation generation
       ("docbook-xml" ,docbook-xml) ; For documentation generation
       ("ruby" ,ruby)))
    (propagated-inputs
     `(("gtk+" ,gtk+)
       ("libsoup" ,libsoup)))
    (inputs
     `(("at-spi2-core" ,at-spi2-core)
       ("bubblewrap" ,bubblewrap)
       ("enchant" ,enchant)
       ("geoclue" ,geoclue)
       ("gst-plugins-base" ,gst-plugins-base)
       ("gtk+-2" ,gtk+-2)
       ("harfbuzz" ,harfbuzz)
       ("hyphen" ,hyphen)
       ("icu4c" ,icu4c)
       ("libgcrypt" ,libgcrypt)
       ("libjpeg" ,libjpeg-turbo)
       ("libnotify" ,libnotify)
       ("libpng" ,libpng)
       ("libseccomp" ,libseccomp)
       ("libsecret" ,libsecret)
       ("libtasn1" ,libtasn1)
       ("libwebp" ,libwebp)
       ("libwpe" ,libwpe)
       ("libxcomposite" ,libxcomposite)
       ("libxml2" ,libxml2)
       ("libxslt" ,libxslt)
       ("libxt" ,libxt)
       ("mesa" ,mesa)
       ("openjpeg" ,openjpeg)
       ("sqlite" ,sqlite)
       ("wpebackend-fdo" ,wpebackend-fdo)
       ("xdg-dbus-proxy" ,xdg-dbus-proxy)))
    (home-page "https://www.webkitgtk.org/")
    (synopsis "Web content engine for GTK+")
    (description
     "WebKitGTK+ is a full-featured port of the WebKit rendering engine,
suitable for projects requiring any kind of web integration, from hybrid
HTML/CSS applications to full-fledged web browsers.")
    ;; WebKit's JavaScriptCore and WebCore components are available under
    ;; the GNU LGPL, while the rest is available under a BSD-style license.
    (license (list license:lgpl2.0
                   license:lgpl2.1+
                   license:bsd-2
                   license:bsd-3))))

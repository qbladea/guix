;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Tomáš Čech <sleep_walker@suse.cz>
;;; Copyright © 2020 Vinicius Monego <monego@posteo.net>
;;; Copyright © 2021 Eric Bavier <bavier@posteo.net>
;;; Copyright © 2021 Stefan Reichör <stefan@xsteve.at>
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

(define-module (gnu packages task-management)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system go)
  #:use-module (guix build-system meson))

(define-public taskwarrior
  (package
    (name "taskwarrior")
    (version "2.5.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://taskwarrior.org/download/task-" version ".tar.gz"))
       (sha256 (base32
                "0fwnxshhlha21hlgg5z1ad01w13zm1hlmncs274y5n8i15gdfhvj"))))
    (build-system cmake-build-system)
    (inputs
     `(("gnutls" ,gnutls)
       ("util-linux" ,util-linux "lib")))
    (arguments
     `(#:tests? #f ; No tests implemented.
       #:phases
       (modify-phases %standard-phases
         (delete 'install-license-files)))) ; Already installed by package
     (home-page "https://taskwarrior.org")
    (synopsis "Command line task manager")
    (description
     "Taskwarrior is a command-line task manager following the Getting Things
Done time management method.  It supports network synchronization, filtering
and querying data, exposing task data in multiple formats to other tools.")
    (license license:expat)))

(define-public dstask
  (package
    (name "dstask")
    (version "0.24.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/naggie/dstask")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "03rl2wh58xd6a80ji43c7ak3h0ysi3ddg570pn8ry24s7s45zsz2"))))
    (build-system go-build-system)
    (arguments
     `(#:import-path "github.com/naggie/dstask"
       #:install-source? #f
       #:phases
       (modify-phases %standard-phases
         (replace 'build
           (lambda* (#:key import-path #:allow-other-keys)
             (with-directory-excursion (string-append "src/" import-path)
               (invoke "go" "build" "-o" "dstask" "cmd/dstask/main.go")
               (invoke "go" "build" "-o" "dstask-import"
                       "cmd/dstask-import/main.go"))))
         (replace 'install
           (lambda* (#:key import-path outputs #:allow-other-keys)
             (with-directory-excursion (string-append "src/" import-path)
               (let* ((out (assoc-ref outputs "out"))
                      (bindir (string-append out "/bin"))
                      (zsh-completion (string-append
                                       out "/share/zsh/site-functions/_dstask"))
                      (bash-completion
                       (string-append
                        out "/share/bash-completion/completions/_dstask")))
                 (install-file "dstask" bindir)
                 (install-file "dstask-import" bindir)
                 (install-file ".dstask-bash-completions.sh" bash-completion)
                 (install-file ".dstask-zsh-completions.sh" zsh-completion)))
             #t)))))
    (synopsis "CLI-based TODO manager with git-based sync + markdown notes per task")
    (description "dstask is a personal task tracker that uses git for
synchronization.  It offers a note command to attach a Markdown based note to
a task.")
    (home-page "https://github.com/naggie/dstask")
    (license license:expat)))

(define-public blanket
  (package
    (name "blanket")
    (version "0.3.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/rafaelmardojai/blanket/")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "13xip9b2p2ai2jchkck71c849s2rlxzfvlbsgpraw9hswi0rk0jg"))))
    (build-system meson-build-system)
    (arguments
     `(#:glib-or-gtk? #t
       #:tests? #f ;the "Validate appstream file" test fails
       #:phases
       (modify-phases %standard-phases
         (add-after 'wrap 'wrap-libs
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out               (assoc-ref outputs "out"))
                    (gi-typelib-path   (getenv "GI_TYPELIB_PATH"))
                    (gst-plugin-path   (getenv "GST_PLUGIN_SYSTEM_PATH"))
                    (python-path       (getenv "PYTHONPATH")))
               (wrap-program (string-append out "/bin/blanket")
                 `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))
                 `("GST_PLUGIN_SYSTEM_PATH" ":" prefix (,gst-plugin-path))
                 `("PYTHONPATH" ":" prefix (,python-path))))
             #t)))))
    (native-inputs
     `(("desktop-file-utils" ,desktop-file-utils)
       ("gettext" ,gettext-minimal)
       ("glib:bin" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)
       ("gtk+:bin" ,gtk+ "bin")
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("appstream-glib" ,appstream-glib)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("gst-plugins-bad" ,gst-plugins-bad)
       ("gst-plugins-good" ,gst-plugins-good) ;for ScaleTempo plugin
       ("gtk+" ,gtk+)
       ("libhandy" ,libhandy)
       ("python-gst" ,python-gst)
       ("python-pygobject" ,python-pygobject)))
    (home-page "https://github.com/rafaelmardojai/blanket")
    (synopsis "Ambient sound and noise player")
    (description
     "Blanket provides different ambient sounds and types of noise to listen
to with the goal of improving your focus and enhancing your productivity.
You can also use it to fall asleep in a noisy environment.")
    (license license:gpl3+)))

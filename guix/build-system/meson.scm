;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Peter Mikkelsen <petermikkelsen10@gmail.com>
;;; Copyright © 2018, 2019 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2021 Ludovic Courtès <ludo@gnu.org>
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

(define-module (guix build-system meson)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix store)
  #:use-module (guix monads)
  #:use-module (guix search-paths)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix packages)
  #:use-module (ice-9 match)
  #:export (%meson-build-system-modules
            meson-build-system))

;; Commentary:
;;
;; Standard build procedure for packages using Meson. This is implemented as an
;; extension of `gnu-build-system', with the option to turn on the glib/gtk
;; phases from `glib-or-gtk-build-system'.
;;
;; Code:

(define %meson-build-system-modules
  ;; Build-side modules imported by default.
  `((guix build meson-build-system)
    ;; The modules from glib-or-gtk contains the modules from gnu-build-system,
    ;; so there is no need to import that too.
    ,@%glib-or-gtk-build-system-modules))

(define (default-ninja)
  "Return the default ninja package."
  ;; Lazily resolve the binding to avoid a circular dependency.
  (let ((module (resolve-interface '(gnu packages ninja))))
    (module-ref module 'ninja)))

(define (default-meson)
  "Return the default meson package."
  ;; Lazily resolve the binding to avoid a circular dependency.
  (let ((module (resolve-interface '(gnu packages build-tools))))
    (module-ref module 'meson)))

(define* (lower name
                #:key source inputs native-inputs outputs system target
                (meson (default-meson))
                (ninja (default-ninja))
                (glib-or-gtk? #f)
                #:allow-other-keys
                #:rest arguments)
  "Return a bag for NAME."
  (define private-keywords
    `(#:source #:meson #:ninja #:inputs #:native-inputs #:outputs #:target))

  (and (not target) ;; TODO: add support for cross-compilation.
       (bag
         (name name)
         (system system)
         (build-inputs `(("meson" ,meson)
                         ("ninja" ,ninja)
                         ,@native-inputs
                         ,@inputs
                         ;; Keep the standard inputs of 'gnu-build-system'.
                         ,@(standard-packages)))
         (host-inputs (if source
                          `(("source" ,source))
                          '()))
         (outputs outputs)
         (build meson-build)
         (arguments (strip-keyword-arguments private-keywords arguments)))))

(define* (meson-build name inputs
                      #:key
                      guile source
                      (outputs '("out"))
                      (configure-flags ''())
                      (search-paths '())
                      (build-type "debugoptimized")
                      (tests? #t)
                      (test-target "test")
                      (glib-or-gtk? #f)
                      (parallel-build? #t)
                      (parallel-tests? #f)
                      (validate-runpath? #t)
                      (patch-shebangs? #t)
                      (strip-binaries? #t)
                      (strip-flags ''("--strip-debug"))
                      (strip-directories ''("lib" "lib64" "libexec"
                                            "bin" "sbin"))
                      (elf-directories ''("lib" "lib64" "libexec"
                                          "bin" "sbin"))
                      (phases '(@ (guix build meson-build-system)
                                  %standard-phases))
                      (system (%current-system))
                      (imported-modules %meson-build-system-modules)
                      (modules '((guix build meson-build-system)
                                 (guix build utils)))
                      allowed-references
                      disallowed-references)
  "Build SOURCE using MESON, and with INPUTS, assuming that SOURCE
has a 'meson.build' file."
  (define builder
    (with-imported-modules imported-modules
      #~(let ((build-phases #$(if glib-or-gtk?
                                  phases
                                  #~(modify-phases #$phases
                                      (delete 'glib-or-gtk-compile-schemas)
                                      (delete 'glib-or-gtk-wrap)))))

          (use-modules ,@modules)

          #$(with-build-variables inputs outputs
              #~(meson-build #:source #+source
                             #:system #$system
                             #:outputs %outputs
                             #:inputs %build-inputs
                             #:search-paths '#$(map search-path-specification->sexp
                                                    search-paths)
                             #:phases build-phases
                             #:configure-flags #$configure-flags
                             #:build-type #$build-type
                             #:tests? #$tests?
                             #:test-target #$test-target
                             #:parallel-build? #$parallel-build?
                             #:parallel-tests? #$parallel-tests?
                             #:validate-runpath? #$validate-runpath?
                             #:patch-shebangs? #$patch-shebangs?
                             #:strip-binaries? #$strip-binaries?
                             #:strip-flags #$strip-flags
                             #:strip-directories #$strip-directories
                             #:elf-directories #$elf-directories)))))

  (mlet %store-monad ((guile (package->derivation (or guile (default-guile))
                                                  system #:graft? #f)))
    (gexp->derivation name builder
                      #:system system
                      #:target #f
                      #:substitutable? substitutable?
                      #:allowed-references allowed-references
                      #:disallowed-references disallowed-references
                      #:guile-for-build guile)))

(define meson-build-system
  (build-system
    (name 'meson)
    (description "The standard Meson build system")
    (lower lower)))

;;; meson.scm ends here

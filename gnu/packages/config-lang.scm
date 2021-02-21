;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2021 qblade <qblade@protonmail.com>
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

(define-module (gnu packages config-lang)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download))

(define-public libucl
  (package
    (name "libucl")
    (version "0.8.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/vstakhov/libucl/")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1h52ldxankyhbbm1qbqz1f2q0j03c1b4mig7343bs3mc6fpm18gf"))))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("pkg-config" ,pkg-config)
       ("libtool" ,libtool)))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f)) ;; no tests
    (home-page "https://github.com/vstakhov/libucl")
    (synopsis "Universal configuration language")
    (description "Universal configuration language.
fully compatible with JSON format and is able to parse json files")
    (license license:bsd-2)))

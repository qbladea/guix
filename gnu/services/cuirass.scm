;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 Mathieu Lirzin <mthl@gnu.org>
;;; Copyright © 2016, 2017, 2018, 2019, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2017, 2020 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2018 Clément Lassieur <clement@lassieur.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu services cuirass)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix utils)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages ci)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages version-control)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services databases)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services admin)
  #:use-module (gnu system shadow)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match)
  #:export (<cuirass-remote-server-configuration>
            cuirass-remote-server-configuration
            cuirass-remote-server-configuration?

            <cuirass-configuration>
            cuirass-configuration
            cuirass-configuration?
            cuirass-service-type

            <cuirass-remote-worker-configuration>
            cuirass-remote-worker-configuration
            cuirass-remote-worker-configuration?
            cuirass-remote-worker-service-type

            <build-manifest>
            build-manifest
            build-manifest?

            <simple-cuirass-configuration>
            simple-cuirass-configuration
            simple-cuirass-configuration?

            simple-cuirass-configuration->specs))

;;;; Commentary:
;;;
;;; This module implements a service that to run instances of Cuirass, a
;;; continuous integration tool.
;;;
;;;; Code:

(define %cuirass-default-database
  "dbname=cuirass host=/var/run/postgresql")

(define-record-type* <cuirass-remote-server-configuration>
  cuirass-remote-server-configuration make-cuirass-remote-server-configuration
  cuirass-remote-server-configuration?
  (backend-port     cuirass-remote-server-configuration-backend-port ;int
                    (default #f))
  (publish-port     cuirass-remote-server-configuration-publish-port ;int
                    (default #f))
  (log-file         cuirass-remote-server-log-file ;string
                    (default "/var/log/cuirass-remote-server.log"))
  (cache            cuirass-remote-server-configuration-cache ;string
                    (default "/var/cache/cuirass/remote/"))
  (trigger-url      cuirass-remote-server-trigger-url ;string
                    (default #f))
  (public-key       cuirass-remote-server-configuration-public-key ;string
                    (default #f))
  (private-key      cuirass-remote-server-configuration-private-key ;string
                    (default #f)))

(define-record-type* <cuirass-configuration>
  cuirass-configuration make-cuirass-configuration
  cuirass-configuration?
  (cuirass          cuirass-configuration-cuirass ;package
                    (default cuirass))
  (log-file         cuirass-configuration-log-file ;string
                    (default "/var/log/cuirass.log"))
  (web-log-file     cuirass-configuration-web-log-file ;string
                    (default "/var/log/cuirass-web.log"))
  (cache-directory  cuirass-configuration-cache-directory ;string (dir-name)
                    (default "/var/cache/cuirass"))
  (user             cuirass-configuration-user ;string
                    (default "cuirass"))
  (group            cuirass-configuration-group ;string
                    (default "cuirass"))
  (interval         cuirass-configuration-interval ;integer (seconds)
                    (default 60))
  (parameters       cuirass-configuration-parameters ;string
                    (default #f))
  (remote-server    cuirass-configuration-remote-server
                    (default #f))
  (database         cuirass-configuration-database ;string
                    (default %cuirass-default-database))
  (port             cuirass-configuration-port ;integer (port)
                    (default 8081))
  (host             cuirass-configuration-host ;string
                    (default "localhost"))
  (specifications   cuirass-configuration-specifications)
                                  ;gexp that evaluates to specification-alist
  (use-substitutes? cuirass-configuration-use-substitutes? ;boolean
                    (default #f))
  (one-shot?        cuirass-configuration-one-shot? ;boolean
                    (default #f))
  (fallback?        cuirass-configuration-fallback? ;boolean
                    (default #f))
  (extra-options    cuirass-configuration-extra-options
                    (default '())))

(define (cuirass-shepherd-service config)
  "Return a <shepherd-service> for the Cuirass service with CONFIG."
  (let ((cuirass          (cuirass-configuration-cuirass config))
        (cache-directory  (cuirass-configuration-cache-directory config))
        (web-log-file     (cuirass-configuration-web-log-file config))
        (log-file         (cuirass-configuration-log-file config))
        (user             (cuirass-configuration-user config))
        (group            (cuirass-configuration-group config))
        (interval         (cuirass-configuration-interval config))
        (parameters       (cuirass-configuration-parameters config))
        (remote-server    (cuirass-configuration-remote-server config))
        (database         (cuirass-configuration-database config))
        (port             (cuirass-configuration-port config))
        (host             (cuirass-configuration-host config))
        (specs            (cuirass-configuration-specifications config))
        (use-substitutes? (cuirass-configuration-use-substitutes? config))
        (one-shot?        (cuirass-configuration-one-shot? config))
        (fallback?        (cuirass-configuration-fallback? config))
        (extra-options    (cuirass-configuration-extra-options config)))
    `(,(shepherd-service
        (documentation "Run Cuirass.")
        (provision '(cuirass))
        (requirement '(guix-daemon postgres postgres-roles networking))
        (start #~(make-forkexec-constructor
                  (list (string-append #$cuirass "/bin/cuirass")
                        "--cache-directory" #$cache-directory
                        "--specifications"
                        #$(scheme-file "cuirass-specs.scm" specs)
                        "--database" #$database
                        "--interval" #$(number->string interval)
                        #$@(if parameters
                               (list (string-append
                                      "--parameters="
                                      parameters))
                               '())
                        #$@(if remote-server '("--build-remote") '())
                        #$@(if use-substitutes? '("--use-substitutes") '())
                        #$@(if one-shot? '("--one-shot") '())
                        #$@(if fallback? '("--fallback") '())
                        #$@extra-options)

                  #:environment-variables
                  (list "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt"
                        (string-append "GIT_EXEC_PATH=" #$git
                                       "/libexec/git-core"))

                  #:user #$user
                  #:group #$group
                  #:log-file #$log-file))
        (stop #~(make-kill-destructor)))
      ,(shepherd-service
        (documentation "Run Cuirass web interface.")
        (provision '(cuirass-web))
        (requirement '(cuirass))
        (start #~(make-forkexec-constructor
                  (list (string-append #$cuirass "/bin/cuirass")
                        "--cache-directory" #$cache-directory
                        "--database" #$database
                        "--web"
                        "--port" #$(number->string port)
                        "--listen" #$host
                        "--interval" #$(number->string interval)
                        #$@(if parameters
                               (list (string-append
                                      "--parameters="
                                      parameters))
                               '())
                        #$@(if use-substitutes? '("--use-substitutes") '())
                        #$@(if fallback? '("--fallback") '())
                        #$@extra-options)

                  #:user #$user
                  #:group #$group
                  #:log-file #$web-log-file))
        (stop #~(make-kill-destructor)))
      ,@(if remote-server
            (match-record remote-server <cuirass-remote-server-configuration>
              (backend-port publish-port log-file cache trigger-url
                            public-key private-key)
              (list
               (shepherd-service
                (documentation "Run Cuirass remote build server.")
                (provision '(cuirass-remote-server))
                (requirement '(avahi-daemon cuirass))
                (start #~(make-forkexec-constructor
                          (list (string-append #$cuirass "/bin/remote-server")
                                (string-append "--database=" #$database)
                                (string-append "--cache=" #$cache)
                                (string-append "--user=" #$user)
                                #$@(if backend-port
                                       (list (string-append
                                              "--backend-port="
                                              (number->string backend-port)))
                                       '())
                                #$@(if publish-port
                                       (list (string-append
                                              "--publish-port="
                                              (number->string publish-port)))
                                       '())
                                #$@(if parameters
                                       (list (string-append
                                              "--parameters="
                                              parameters))
                                       '())
                                #$@(if trigger-url
                                       (list
                                        (string-append
                                         "--trigger-substitute-url="
                                         trigger-url))
                                       '())
                                #$@(if public-key
                                       (list
                                        (string-append "--public-key="
                                                       public-key))
                                       '())
                                #$@(if private-key
                                       (list
                                        (string-append "--private-key="
                                                       private-key))
                                       '()))
                          #:log-file #$log-file))
                (stop #~(make-kill-destructor)))))
            '()))))

(define (cuirass-account config)
  "Return the user accounts and user groups for CONFIG."
  (let ((cuirass-user  (cuirass-configuration-user config))
        (cuirass-group (cuirass-configuration-group config)))
    (list (user-group
           (name cuirass-group)
           (system? #t))
          (user-account
           (name cuirass-user)
           (group cuirass-group)
           (system? #t)
           (comment "Cuirass privilege separation user")
           (home-directory (string-append "/var/lib/" cuirass-user))
           (shell (file-append shadow "/sbin/nologin"))))))

(define (cuirass-postgresql-role config)
  (let ((user (cuirass-configuration-user config)))
    (list (postgresql-role
           (name user)
           (create-database? #t)))))

(define (cuirass-activation config)
  "Return the activation code for CONFIG."
  (let* ((cache          (cuirass-configuration-cache-directory config))
         (remote-server  (cuirass-configuration-remote-server config))
         (remote-cache   (and remote-server
                              (cuirass-remote-server-configuration-cache
                               remote-server)))
         (db             (dirname
                          (cuirass-configuration-database config)))
         (user           (cuirass-configuration-user config))
         (log            "/var/log/cuirass")
         (group          (cuirass-configuration-group config)))
    (with-imported-modules '((guix build utils))
      #~(begin
          (use-modules (guix build utils))

          (mkdir-p #$cache)
          (mkdir-p #$db)
          (mkdir-p #$log)

          (when #$remote-cache
            (mkdir-p #$remote-cache))

          (let ((uid (passwd:uid (getpw #$user)))
                (gid (group:gid (getgr #$group))))
            (chown #$cache uid gid)
            (chown #$db uid gid)
            (chown #$log uid gid)

            (when #$remote-cache
              (chown #$remote-cache uid gid)))))))

(define (cuirass-log-rotations config)
  "Return the list of log rotations that corresponds to CONFIG."
  (list (log-rotation
         (files (list (cuirass-configuration-log-file config)))
         (frequency 'weekly)
         (options '("rotate 40")))))              ;worth keeping

(define cuirass-service-type
  (service-type
   (name 'cuirass)
   (extensions
    (list
     (service-extension profile-service-type      ;for 'info cuirass'
                        (compose list cuirass-configuration-cuirass))
     (service-extension rottlog-service-type cuirass-log-rotations)
     (service-extension activation-service-type cuirass-activation)
     (service-extension shepherd-root-service-type cuirass-shepherd-service)
     (service-extension account-service-type cuirass-account)
     ;; Make sure postgresql and postgresql-role are instantiated.
     (service-extension postgresql-service-type (const #t))
     (service-extension postgresql-role-service-type
                        cuirass-postgresql-role)))
   (description
    "Run the Cuirass continuous integration service.")))

(define-record-type* <cuirass-remote-worker-configuration>
  cuirass-remote-worker-configuration make-cuirass-remote-worker-configuration
  cuirass-remote-worker-configuration?
  (cuirass          cuirass-remote-worker-configuration-cuirass ;package
                    (default cuirass))
  (workers          cuirass-remote-worker-workers ;int
                    (default 1))
  (server           cuirass-remote-worker-server ;string
                    (default #f))
  (systems          cuirass-remote-worker-systems ;list
                    (default (list (%current-system))))
  (log-file         cuirass-remote-worker-log-file ;string
                    (default "/var/log/cuirass-remote-worker.log"))
  (publish-port     cuirass-remote-worker-configuration-publish-port ;int
                    (default #f))
  (public-key       cuirass-remote-worker-configuration-public-key ;string
                    (default #f))
  (private-key      cuirass-remote-worker-configuration-private-key ;string
                    (default #f)))

(define (cuirass-remote-worker-shepherd-service config)
  "Return a <shepherd-service> for the Cuirass remote worker service with
CONFIG."
  (match-record config <cuirass-remote-worker-configuration>
    (cuirass workers server systems log-file publish-port
             public-key private-key)
    (list (shepherd-service
           (documentation "Run Cuirass remote build worker.")
           (provision '(cuirass-remote-worker))
           (requirement '(avahi-daemon guix-daemon networking))
           (start #~(make-forkexec-constructor
                     (list (string-append #$cuirass "/bin/remote-worker")
                           (string-append "--workers="
                                          #$(number->string workers))
                           #$@(if server
                                  (list (string-append "--server=" server))
                                  '())
                           #$@(if systems
                                  (list (string-append
                                         "--systems="
                                         (string-join systems ",")))
                                  '())
                           #$@(if publish-port
                                  (list (string-append
                                         "--publish-port="
                                         (number->string publish-port)))
                                  '())
                           #$@(if public-key
                                  (list
                                   (string-append "--public-key="
                                                  public-key))
                                  '())
                           #$@(if private-key
                                  (list
                                   (string-append "--private-key="
                                                  private-key))
                                  '()))
                    #:log-file #$log-file))
           (stop #~(make-kill-destructor))))))

(define cuirass-remote-worker-service-type
  (service-type
   (name 'cuirass-remote-worker)
   (extensions
    (list
     (service-extension shepherd-root-service-type
                        cuirass-remote-worker-shepherd-service)))
   (description
    "Run the Cuirass remote build worker service.")))

(define-record-type* <build-manifest>
  build-manifest make-build-manifest
  build-manifest?
  (channel-name          build-manifest-channel-name) ;symbol
  (manifest              build-manifest-manifest)) ;string

(define-record-type* <simple-cuirass-configuration>
  simple-cuirass-configuration make-simple-cuirass-configuration
  simple-cuirass-configuration?
  (build                 simple-cuirass-configuration-build
                         (default 'all))  ;symbol or list of <build-manifest>
  (channels              simple-cuirass-configuration-channels
                         (default %default-channels))  ;list of <channel>
  (non-package-channels  simple-cuirass-configuration-package-channels
                         (default '())) ;list of channels name
  (systems               simple-cuirass-configuration-systems
                         (default (list (%current-system))))) ;list of strings

(define* (simple-cuirass-configuration->specs config)
  (define (format-name name)
    (if (string? name)
        name
        (symbol->string name)))

  (define (format-manifests build-manifests)
    (map (lambda (build-manifest)
           (match-record build-manifest <build-manifest>
             (channel-name manifest)
             (cons (format-name channel-name) manifest)))
         build-manifests))

  (define (channel->input channel)
    (let ((name   (channel-name channel))
          (url    (channel-url channel))
          (branch (channel-branch channel)))
      `((#:name . ,(format-name name))
        (#:url . ,url)
        (#:load-path . ".")
        (#:branch . ,branch)
        (#:no-compile? #t))))

  (define (package-path channels non-package-channels)
    (filter-map (lambda (channel)
                  (let ((name (channel-name channel)))
                    (and (not (member name non-package-channels))
                         (not (eq? name 'guix))
                         (format-name name))))
                channels))

  (define (config->spec config)
    (match-record config <simple-cuirass-configuration>
      (build channels non-package-channels systems)
      `((#:name . "simple-config")
        (#:load-path-inputs . ("guix"))
        (#:package-path-inputs . ,(package-path channels
                                                non-package-channels))
        (#:proc-input . "guix")
        (#:proc-file . "build-aux/cuirass/gnu-system.scm")
        (#:proc . cuirass-jobs)
        (#:proc-args . ((systems . ,systems)
                        ,@(if (eq? build 'all)
                              '()
                              `((subset . "manifests")
                                (manifests . ,(format-manifests build))))))
        (#:inputs  . ,(map channel->input channels))
        (#:build-outputs . ())
        (#:priority . 1))))

  #~(list '#$(config->spec config)))

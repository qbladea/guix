;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2020, 2021 Mathieu Othacehe <othacehe@gnu.org>
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

(define-module (gnu tests cuirass)
  #:use-module (gnu tests)
  #:use-module (gnu system)
  #:use-module (gnu system vm)
  #:use-module (gnu system install)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages version-control)
  #:use-module (gnu services)
  #:use-module (gnu services avahi)
  #:use-module (gnu services base)
  #:use-module (gnu services cuirass)
  #:use-module (gnu services databases)
  #:use-module (gnu services networking)
  #:use-module (gnu system nss)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:use-module (guix store)
  #:export (%cuirass-test
            %cuirass-remote-test
            %cuirass-simple-test))

(define %derivation-file
  (scheme-file
   "derivation.scm"
   '(begin
      (use-modules (guix)
                   (srfi srfi-1)
                   (ice-9 match))

      (define (derivation->alist store drv)
        `((#:derivation . ,(derivation-file-name drv))
          (#:log . ,(log-file store (derivation-file-name drv)))
          (#:outputs . ,(filter-map (lambda (res)
                                      (match res
                                        ((name . path)
                                         `(,name . ,path))))
                                    (derivation->output-paths drv)))
          (#:nix-name . ,(derivation-name drv))
          (#:system . ,(derivation-system drv))
          (#:max-silent-time . 3600)
          (#:timeout . 3600)))

      (define (cuirass-jobs store arguments)
        (let* ((file (plain-file "test" "this is a test derivation"))
               (job-name "test-job")
               (drv  (run-with-store store
                       (gexp->derivation
                        job-name
                        #~(begin
                            (mkdir #$output)
                            (symlink #$file
                                     (string-append #$output "/file")))))))
          (list (lambda ()
                  `((#:job-name . ,job-name)
                    ,@(derivation->alist store drv)))))))))

(define git-service
  ;; Create a Git repository to host Cuirass' specification.
  (simple-service
   'create-git-directory activation-service-type
   #~(begin
       (let* ((git (string-append #$git "/bin/git"))
              (main "/tmp/cuirass-main")
              (file (string-append main "/build-aux/cuirass/gnu-system.scm")))
         (mkdir-p (dirname file))
         (with-directory-excursion main
           (copy-file #$%derivation-file file)
           (invoke git "config" "--global" "user.email"
                   "charlie@example.org")
           (invoke git "config" "--global" "user.name" "A U Thor")
           (invoke git "init")
           (invoke git "add" ".")
           (invoke git "commit" "-m" "That's a commit."))))))

(define cow-service
  ;; The Guix-daemon & Cuirass will complain if the store is
  ;; read-only. Create a store overlay to solve this issue.
  (simple-service
   'mount-cow-store activation-service-type
   #~(begin
       (use-modules (guix build syscalls)
                    (guix build utils))
       (mkdir-p "/rw-store")
       (mount "none" "/rw-store" "tmpfs")

       (mkdir-p "/rw-store/upper")
       (mkdir-p "/rw-store/work")
       (mount "none" "/gnu/store" "overlay" 0
              "lowerdir=/gnu/store,upperdir=/rw-store/upper,workdir=/rw-store/work"))))

(define %cuirass-specs
    #~(list
       '((#:name . "test")
         (#:load-path-inputs . ())
         (#:package-path-inputs . ())
         (#:proc-input . "main")
         (#:proc-file . "build-aux/cuirass/gnu-system.scm")
         (#:proc . cuirass-jobs)
         (#:proc-args . ())
         (#:inputs . (((#:name . "main")
                       (#:url . "file:///tmp/cuirass-main/")
                       (#:load-path . ".")
                       (#:branch . "master")
                       (#:no-compile? . #t))))
         (#:build-outputs . ())
         (#:priority . 1))))

(define* (cuirass-services #:key remote-build?)
  (list
   (service cuirass-service-type
            (cuirass-configuration
             (specifications %cuirass-specs)
             (remote-server (and remote-build?
                                 (cuirass-remote-server-configuration)))
             (host "0.0.0.0")
             (use-substitutes? #t)))))

(define (run-cuirass-test name os)
  (define os*
    (let ((modules '((gnu services herd)
                     (guix combinators)
                     (guix build syscalls)
                     (guix build utils))))
      (marionette-operating-system
       os
       #:imported-modules modules)))

  (define cuirass-web-port 8081)
  (define forward-port 5000)

  (define vm
    (virtual-machine
     (operating-system os*)
     (memory-size 1024)
     (port-forwardings `((,forward-port . ,cuirass-web-port)))))

  (define test
    (with-extensions (list guile-json-4)
      (with-imported-modules '((gnu build marionette))
        #~(begin
            (use-modules (srfi srfi-11) (srfi srfi-64)
                         (gnu build marionette)
                         (ice-9 match)
                         (ice-9 rdelim)
                         (json)
                         (rnrs bytevectors)
                         (web client) (web response))

            (define marionette
              (make-marionette (list #$vm)))

            (define (query path)
              (http-get
               (format #f "http://localhost:~a~a"
                       #$(number->string forward-port)
                       path)))

            (define* (retry f #:key times delay)
              (let loop ((attempt 1))
                (let ((result (f)))
                  (cond
                   (result result)
                   (else
                    (if (>= attempt times)
                        #f
                        (begin
                          (sleep delay)
                          (loop (+ 1 attempt)))))))))

            (mkdir #$output)
            (chdir #$output)

            (test-begin "cuirass")

            ;; XXX: Shepherd reads the config file *before* binding its
            ;; control socket, so /var/run/shepherd/socket might not exist yet
            ;; when the 'marionette' service is started.
            (test-assert "shepherd socket ready"
              (marionette-eval
               `(begin
                  (use-modules (gnu services herd))
                  (let loop ((i 10))
                    (cond ((file-exists? (%shepherd-socket-file))
                           #t)
                          ((> i 0)
                           (sleep 1)
                           (loop (- i 1)))
                          (else
                           'failure))))
               marionette))

            ;; Wait for cuirass to be up and running.
            (test-assert "cuirass running"
              (marionette-eval
               '(begin
                  (use-modules (gnu services herd))
                  (start-service 'cuirass)
                  #t)
               marionette))

            (test-assert "cuirass-web running"
              (begin
                (wait-for-tcp-port #$cuirass-web-port marionette)
                (retry
                 (lambda ()
                   (let-values (((response text)
                                 (query "/")))
                     (eq? (response-code response) 200)))
                 #:times 5
                 #:delay 5)))

            (test-assert "cuirass-web evaluation"
              (begin
                (retry
                 (lambda ()
                   (let-values (((response text)
                                 (query "/api/evaluation?id=1")))
                     (let ((result
                            (false-if-exception
                             (json-string->scm
                              (utf8->string text)))))
                       (eq? (and result
                                 (assoc-ref result "id"))
                            1))))
                 #:times 5
                 #:delay 5)))

            ;; Even though there's a store overlay, the Guix database is not
            ;; initialized, meaning that we won't be able to perform the
            ;; build. Check at least that it is queued.
            (test-assert "cuirass-web build queued"
              (begin
                (retry
                 (lambda ()
                   (let-values (((response text)
                                 (query "/api/queue?nr=1")))
                     (let ((result
                            (json-string->scm
                             (utf8->string text))))
                       (match (vector->list result)
                         ((build)
                          (string=? (assoc-ref build "job") "test-job"))
                         (else #f)))))
                 #:times 5
                 #:delay 10)))

            (test-end)
            (exit (= (test-runner-fail-count (test-runner-current)) 0))))))

  (gexp->derivation name test))

(define %cuirass-test
  (let ((os (operating-system
              (inherit %simple-os)
              (services
               (append (list cow-service
                             (service dhcp-client-service-type)
                             git-service)
                       (cuirass-services)
                       (operating-system-user-services %simple-os))))))
    (system-test
     (name "cuirass")
     (description "Connect to a Cuirass server.")
     (value
      (run-cuirass-test name os)))))

(define %cuirass-remote-test
  (let ((os (operating-system
              (inherit %simple-os)
              (name-service-switch %mdns-host-lookup-nss)
              (services
               (append (list (service avahi-service-type)
                             cow-service
                             (service dhcp-client-service-type)
                             git-service)
                       (cuirass-services #:remote-build? #t)
                       (operating-system-user-services %simple-os))))))
    (system-test
     (name "cuirass-remote")
     (description "Connect to a Cuirass server with remote build.")
     (value (run-cuirass-test name os)))))

(define simple-cuirass-service
  (service cuirass-service-type
           (cuirass-configuration
            (specifications
             (simple-cuirass-configuration->specs
              (simple-cuirass-configuration
               (build 'all)
               (channels
                (list (channel
                       (name 'guix)
                       (url "file:///tmp/cuirass-main/")))))))
            (host "0.0.0.0")
            (use-substitutes? #t))))

(define %cuirass-simple-test
  (let ((os (operating-system
              (inherit %simple-os)
              (services
               (append
                (list cow-service
                      (service dhcp-client-service-type)
                      git-service
                      simple-cuirass-service)
                (operating-system-user-services %simple-os))))))
    (system-test
     (name "cuirass-simple")
     (description "Connect to a simple Cuirass server.")
     (value
      (run-cuirass-test name os)))))

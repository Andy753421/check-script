; Copyright (C) 2007, 2008 Andy Spencer <spenceal@rose-hulman.edu>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU Affero General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU Affero General Public License for more details.
;
; You should have received a copy of the GNU Affero General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(load "chez-init.ss")

(define my-load load)
(define load
  (lambda (s)
    (if (not (equal? s "chez-init.ss")) ;; should be improved to substring
        (my-load s))))

(define trace (lambda v v))
;(define-syntax trace-lambda
;  (syntax-rules ()
;    ((_ name args body ...)
;     ((lambda args body ...)))))

; Allows circular structures to be printed
(print-graph #t)

;(define-syntax foreign-procedure
;     (syntax-rules ()
;             [(_ exp ...) "disabled"]))

(define io-error (lambda x "I/O functions are illegal! Sorry"))

(define-syntax eval-sans-io
  (syntax-rules ()
    ((eval-sans-io expr)
     (fluid-let [(open-input-file io-error)
         (close-input-port io-error)
         (delete-file io-error) ;Added 9/20/02
         (transcript-on io-error) ;Added 9/20/02
         (call-with-input-file io-error)
         (with-input-from-file io-error)
         (read io-error)
         (read-char io-error)
         (peek-char io-error)
         (open-output-file io-error)
         (close-output-port io-error)
         (call-with-output-file io-error)
         (system io-error)
         (process io-error)
         (load-shared-object io-error)
         (display io-error)
         (write io-error)
         (debug (lambda L 'no-debug-allowed))
         (break (lambda L 'giveMeABreak))
         (write-char io-error)
         (printf io-error)
         (fprintf io-error)
         (pretty-print io-error)
;         (write-block io-error)
;         (eval io-error)
;         (provide-foreign-entries io-error)
;         (load-foreign io-error)
;         (trace-lambda io-error)
         ]
       expr))))

;; Used to handle "intentional" errors thrown by students' code
;; Need to ensure that chez-init is not loaded again after this point
(define eopl:error error)

;;; Start of original code ;;;

(define argv (command-line-arguments))
(define stdout (make-output-port 1 ""))
(define stderr (make-output-port 2 ""))

(define debug  #f)
(define (dprint line)
  (if debug (format #t "DEBUG: ~s\n" line)))

(define perror
  (lambda err
    (write (list '*error* (car err) (apply format (cdr err))))))
;    (format stderr
;            "Error in ~s: ~s\n"
;            (car err)
;            (apply format (cdr err)))))

(define (read-line)
  (let helper ((sofar '())
               (next  (read-char)))
    (cond ((eof-object? next)
           (error 'read-line "EOF encountered while reading testcase"))
          ((eq? next #\newline)
           (list->string (reverse sofar)))
          (else
            (helper (cons next sofar)
                    (read-char))))))

(if (< (length argv) 1)
  (begin
    (display "usage: scheme --script checker.ss <test-file> [<lib-file>]\n")
    (exit)))

(error-handler perror)
(load (car argv))

; Added to load the lib file
(if (> (length argv) 1)
  (load (cadr argv)))

; Runs a single test
; \returns Guaranteed to return a status
;   ('success answer) => Correct, display answer
;   ('other   errmsg) => Error occured, log the message to stdout?
;                        Note: Now the error message is displayed
(define (run-test)
  (call/cc
    (lambda (k)
      (error-handler (lambda err (k err)))
      (let* ((line   (read-line))
             (parsed (read (open-input-string line)))
             (answer (eval-sans-io (eval parsed))))
        (cons 'success answer)))))

(let run-tests ((status (run-test)))
  (case (car status)
    ('success     (display (cdr status)))
    ('read-line   (apply perror status) (exit))
    (else         (apply perror status)))
  (newline)
  (run-tests (run-test)))

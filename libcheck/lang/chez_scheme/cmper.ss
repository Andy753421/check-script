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

; (load "scheme_common2.ss")
; START scheme_common2.ss
(define status "")
(define debug  #f)
(define argv (command-line-arguments))

(define (dprint line)
  (if debug (format #t "DEBUG: ~s\n" line)))

(define (read-line)
  (let helper ((sofar '())
               (next  (read-char)))
    (cond ((eof-object? next)
           (set! status (eof-object))
           (exit))
          ((eq? next #\newline)
           (list->string (reverse sofar)))
          (else
            (helper (cons next sofar)
                    (read-char))))))

(define (parse-str str)
  (read (open-input-string str)))

(define (main-loop body end)
  (dynamic-wind
    (lambda ignore
      (dprint 'start))
    (lambda ignore
      (dprint 'body)
      (set! status (body status)))
    (lambda ignore
      (dprint 'end)
      (end status)
      (main-loop body end))))

(error-handler (lambda x
                 (dprint x)
                 (set! status 'error)))
; END scheme_common2.ss

; Notes:
;  Status gets set to #f by:
;   * Default
;   * Results of comparator, this is the 'normal' way
;   * Error on eval (by error-handler)
;  And reset to #t by:
;   * Result of comparator
(map load argv)

(define (test-input)
  (let ((eq-func (read-line))
        (answer1 (read-line))
        (answer2 (read-line)))
    ((eval (parse-str eq-func))
     (parse-str answer1)
     (parse-str answer2))))

(main-loop 
  (lambda (status)
    (test-input))
  (lambda (status)
    (cond
      ((eq? status #t) (display "true\n"))
      ((eq? status #f) (display "false\n"))
      ((eq? status 'error) (display "false\n"))
      ((eof-object? status) (exit)))))

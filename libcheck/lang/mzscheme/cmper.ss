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

(letrec
  ((parse-str (lambda (str)
                (read (open-input-string str))))
   (test-input (lambda ()
                 (with-handlers
                   ((exn:fail? (lambda x #f)))
                   (let ((eq-func (read-line)))
                     (if (eof-object? eq-func) eof
                       (let ((answer1 (read-line)))
                         (if (eof-object? answer1) eof
                           (let ((answer2 (read-line)))
                             (if (eof-object? answer2) eof
                               ((eval (parse-str eq-func))
                                (parse-str answer1)
                                (parse-str answer2)))))))))))
   (run-checker (lambda ()
                  (let ((resp (test-input)))
                    (if (not (eof-object? resp))
                      (begin
                        (display (if resp "true\n" "false\n"))
                        (run-checker)))))))
  ;(display (cmper '(1 2 3 4) '(4 3 2 1)))
  ;(display (cmper '(1 2 3 4) '(1 2 3 4)))
  ;(newline)
  ;(if (< (vector-length argv) 1)
  ;  (error 'argv "usage: mzscheme -r scheme_cmp.ss")
  ;  (run-checker)))
  (run-checker))

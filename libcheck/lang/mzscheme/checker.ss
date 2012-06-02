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
  ((parse-line (lambda ()
		 (read (open-input-string (read-line)))))
   (do-exprs (lambda (input)
	       (if (not (eof-object? input))
		 (begin
		   (display (eval input))
		   (newline)
		   (do-exprs (parse-line)))))))
  (if (< (vector-length argv) 1)
    (error 'argv "usage: mzscheme -r scheme_check.ss <test-file>")
    (let ((test-file (vector-ref argv 0)))
      (load test-file)
      (do-exprs (parse-line)))))

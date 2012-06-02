; Copyright (C) 2007, 2008 Jason Sauppe
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

(define code-filename #f)
(define course-name #f)
(define assign-num #f)
(define total-points #f)

(define read-list
  (lambda (filename)
    (define the-list '())
    (let ((infile (open-input-file filename)))
	  (begin
	    (set! code-filename (read infile))
		(set! course-name (read infile))
		(set! assign-num (read infile))
		(set! total-points (read infile))
		(letrec ((read-tests
				  (lambda (acc)
					(let ((item (read infile)))
					  (if (eof-object? item)
						acc
						(read-tests (append acc (list item))))))))
		  (set! the-list (read-tests '())))
		(close-input-port infile)
	  the-list))))

(letrec
  ((parse-input 
    (lambda (filename)
	  (if (symbol? filename) (set! filename (symbol->string filename)))
	  (let ((the-list (read-list filename)))
		(begin
		  (display "Assignment ") 
		  (display assign-num) 
		  (newline)
		  (map (lambda (problem)
				(let* ((prob-name (car problem))
					   (prob-points (cadr problem))
					   (proc-list (caddr problem))
					   (proc-name (car proc-list))
					   (print-width (cadr proc-list))
					   (comparator (caddr proc-list))
					   (unknown (cadddr proc-list))
					   (testcases (cdr (cdddr proc-list))))
				  (begin
					(display "*new_problem*") (newline)
					(display prob-name) (newline)
					;(display prob-points) (newline)
					;(display proc-name) (newline)
					;(display print-width) (newline)
					(display comparator) (newline)
					;(display unknown) (newline)
					(map (lambda (testcase)
							(begin
							  (display (car testcase)) (newline)     ; Points
							  (display (cadr testcase)) (newline)    ; Correct Answer
							  (display (caddr testcase)) (newline))) ; Test code
					  testcases))))
			the-list))))))
  (parse-input (read)))

;("#1 - Fahrenheit->Celsius"
; 5                             ; points for this problem
;(Fahrenheit->Celsius           ; procedure-name
; 70                            ; print-width
; equal?                        ; comparison function
; ""                            ; ????
; (1 0 (Fahrenheit->Celsius 32))
; (1 -160/9 (Fahrenheit->Celsius 0))
; (2 -40 (Fahrenheit->Celsius -40))
; (1 9 (Fahrenheit->Celsius 241/5))
; ))

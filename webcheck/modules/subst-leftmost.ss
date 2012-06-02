(define my-equal? equal?)

(define test-equal?
  (lambda (x y)
    (if (or (pair? x) (pair? y))
	(error 'equal? "equal? may not be used for lists in this question")
	(my-equal? x y))))

(define make-fail-pred-eq?
  (lambda (real-pred?)
    (let ([reject '(6 7 8 9 10 q r s t u v w x y z)])
      (lambda (x y)
	(if (or (member x reject) (member y reject))
	    (error 'subst-leftmost "Procedure does not short-circuit")
	    (real-pred? x y))))))
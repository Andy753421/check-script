(define 1st car)
(define my-cdr cdr)
(define my-car car)
(define my-equal? equal?)

; This function checks for set equality
(define sequal?-for-grading-program
  (lambda (l1 l2)
    (cond
     ((null? l1) (null? l2))
     ((null? l2) (null? l1))
     ((or (not (set?-for-grading-program l1))
          (not (set?-for-grading-program l2)))
      #f)
     ((member (1st l1) l2) (sequal?-for-grading-program
                            (cdr l1)
                            (rember-for-grading-program
                             (1st l1)
                             l2)))
     (else #f))))

(define set?-for-grading-program
  (lambda (s)
    (cond [(null? s) #t]
          [(not (list? s)) #f]
          [(member (my-car s) (my-cdr s)) #f]
          [else (set?-for-grading-program (my-cdr s))])))

(define rember-for-grading-program
  (lambda (a l)
    (cond
     ((null? l) l)
     ((my-equal? a (1st l)) (cdr l))
     (else (cons (1st l) (rember-for-grading-program a (cdr l)))))))


; This function tests for graph equality (Erik Halvorson)
(define graph-equal?-for-grading-program
  (lambda (a b)
    (letrec ((comp
      (lambda (el g)
        (if (null? g)
          #f
          (if (el-equal? el (car g))
            #t
            (comp el (cdr g))))))
            (el-equal?
        (lambda (el1 el2)
          (if (not (eq? (car el1) (car el2)))
            #f
            (sequal?-for-grading-program (cadr el1) (cadr el2)))))
            (check-all
          (lambda (at)
            (if (null? at)
              #t
              (if (not (comp (car at) b))
                #f
                (check-all (cdr at)))))))
  (if (eq? (length a) (length b))
   (check-all a)
   #f))))


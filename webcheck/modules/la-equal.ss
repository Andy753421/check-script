(define 1st car)
(define 2nd cadr)
(define 3rd caddr)

(define la-equal?
    (lambda (e1 e2)
      (cond
        [(and (pair? e2) (eq? (car e2) 'quote))
         (la-equal? e1 (cadr e2))]
        [(and (pair? e1) (eq? (car e1) 'quote))
         (la-equal? (cadr e1)  e2)]

        [(null? e1)
         '(printf "null case ~s ~s~%" e1 e2)
         (null? e2)]
        [(symbol? e1)
         '(printf "symbol case ~s ~s~%" e1 e2)
         (or (eq? e1 e2)
             (and (string? e2) (string=? (symbol->string e1) e2)))]
        [(string? e1)
         '(printf "string case ~s ~s~%" e1 e2)
         (or (eq? e1 e2)
             (and (symbol? e2) (string=? e1 (symbol->string e2))))]
        [(pair? e1)
         '(printf "pair case ~s ~s~%" e1 e2)
         (and (pair? e2)
              (la-equal? (car e1) (car e2))
              (la-equal? (cdr e1) (cdr e2)))]
        [(vector? e1)
         '(printf "vector case ~s ~s~%" e1 e2)
         (and (vector? e2)
              (la-equal? (vector->list e1)
                (vector->list e2)))]
        [else '(printf "else case ~s ~s~%" e1 e2)
              (equal? e1 e2)])))

(define set-equal?  ; are these list-of-symbols equal when
  (lambda (s1 s2)    ; treated as sets?
    (if (or (not (list? s1)) (not (list? s2)))
        #f
        (not (not (and (is-a-subset? s1 s2) (is-a-subset? s2 s1)))))))

(define is-a-subset?
  (lambda (s1 s2)
    (andmap (lambda (x) (member x s2))
      s1)))


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
          [(member (car s) (cdr s)) #f]
          [else (set?-for-grading-program (cdr s))])))

(define rember-for-grading-program
  (lambda (a l)
    (cond
     ((null? l) l)
     ((equal? a (1st l)) (cdr l))
     (else (cons (1st l) (rember-for-grading-program a (cdr l)))))))


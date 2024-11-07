(load "pmatch.scm")
(load "prelude.scm")

(define take
  (lambda (lst n)
    (if (or (zero? n) (null? lst))
        '()
        (cons (car lst)
              (take (cdr lst) (- n 1))))))

(define corpus
  (with-input-from-file "corpus.scm"
    (lambda ()
      (let loop ((exprs '()))
        (let ((e (read)))
          (if (eof-object? e)
              (reverse exprs)
              (loop (cons e exprs))))))))

(define exprs
  (filter (lambda (x) (and (pair? x) (eq? (car x) 'define))) corpus))

(define (ngrams-for-expr expr n)
  (letrec
    ((ngrams-helper
      (lambda (expr context defn-name args)
        (pmatch expr
          [(eq? ,e1 ,e2)
           (error 'ngrams-helper (format "unconverted eq?"))]
          [(eqv? ,e1 ,e2)
           (error 'ngrams-helper (format "unconverted eqv?"))]
          [(cond . ,c*)
           (error 'ngrams-helper (format "unconverted cond"))]
          [(match ,e . ,c*)
           (let ((current 'match))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e (cons 'match-against new-context) defn-name args)
                (apply append
                       (map (lambda (c)
                              (ngrams-helper (cadr c) (cons 'match-body new-context) defn-name args))
                            c*)))))]
          [(quote ())
           (let ((current 'quoted-datum))
             (collect-ngrams (reverse (cons current context)) n))]
          [(quote ,x) (guard (symbol? x))
           (let ((current 'quoted-datum))
             (collect-ngrams (reverse (cons current context)) n))]
          [(quote ,ls) (guard (list? ls))
           (let ((current 'quoted-datum))
             (collect-ngrams (reverse (cons current context)) n))]
          [(quote ,_)
           (error 'ngrams-helper (format "unknown quoted form ~s" _))]
          [#t
           (let ((current 'bool))
             (collect-ngrams (reverse (cons current context)) n))]
          [#f
           (let ((current 'bool))
             (collect-ngrams (reverse (cons current context)) n))]
          [,num (guard (number? num))
           (let ((current 'num))
             (collect-ngrams (reverse (cons current context)) n))]
          [,x (guard (symbol? x))
           (let ((current 'var))
             (collect-ngrams (reverse (cons current context)) n))]
          [(define ,id ,e) (guard (symbol? id))
           (let ((current 'letrec))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e (cons 'letrec-rhs new-context) id args))))]
          [(lambda ,x ,body)
           (let ((current 'lambda))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper body new-context defn-name
                              (if (symbol? x) (list x) x)))))]
          [(if ,test ,conseq ,alt)
           (let ((current 'if))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper test (cons 'if-test new-context) defn-name args)
                (ngrams-helper conseq (cons 'if-conseq new-context) defn-name args)
                (ngrams-helper alt (cons 'if-alt new-context) defn-name args))))]
          [(symbol? ,e)
           (let ((current 'symbol?))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(not ,e)
           (let ((current 'not))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(and . ,e*)
           (let ((current 'and))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (apply append
                       (map (lambda (e)
                              (ngrams-helper e new-context defn-name args))
                            e*)))))]
          [(or . ,e*)
           (let ((current 'or))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (apply append
                       (map (lambda (e)
                              (ngrams-helper e new-context defn-name args))
                            e*)))))]
          [(list . ,e*)
           (let ((current 'list))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (apply append
                       (map (lambda (e)
                              (ngrams-helper e new-context defn-name args))
                            e*)))))]
          [(null? ,e)
           (let ((current 'null?))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(pair? ,e)
           (let ((current 'pair?))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(car ,e)
           (let ((current 'car))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(cdr ,e)
           (let ((current 'cdr))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e new-context defn-name args))))]
          [(cons ,e1 ,e2)
           (let ((current 'cons))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e1 (cons 'cons-e1 new-context) defn-name args)
                (ngrams-helper e2 (cons 'cons-e2 new-context) defn-name args))))]
          [(equal? ,e1 ,e2)
           (let ((current 'equal?))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e1 (cons 'equal?-e1 new-context) defn-name args)
                (ngrams-helper e2 (cons 'equal?-e2 new-context) defn-name args))))]
          [(let ,binding* ,e)
           (let ((current 'let))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (apply append
                       (map (lambda (binding)
                              (ngrams-helper (cadr binding) (cons 'let-rhs new-context) defn-name args))
                            binding*))
                (ngrams-helper e (cons 'let-body new-context) defn-name args))))]
          [(letrec ((,id (lambda ,x ,body))) ,e)
           (let ((current 'letrec))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper `(lambda ,x ,body) (cons 'letrec-rhs new-context) defn-name args)
                (ngrams-helper e (cons 'letrec-body new-context) id args))))]
          [(,e . ,e*) 
           (let ((current 'app))
             (let ((new-context (cons current context)))
               (append
                (collect-ngrams (reverse new-context) n)
                (ngrams-helper e (cons 'app-rator new-context) defn-name args)
                (apply append
                       (map (lambda (e)
                              (ngrams-helper e (cons 'app-rand* new-context) defn-name args))
                            e*)))))]
          [else (error 'ngrams-helper (format "unknown expression type ~s" expr))]))))
    (ngrams-helper expr '() #f #f)))

(define (collect-ngrams choices n)
  (let ((choices-length (length choices)))
    (if (< choices-length n)
        '()
        (let loop ((i 0) (ngrams '()))
          (if (> (+ i n) choices-length)
              (reverse ngrams)
              (loop (+ i 1) (cons (take (list-tail choices i) n) ngrams)))))))

(define (count-ngrams ngram-lists)
  (letrec ((count-helper
            (lambda (ngrams counts)
              (cond
                [(null? ngrams) counts]
                [else
                 (let ((key (car ngrams)))
                   (let ((counts
                          (cond
                            [(assoc key counts) =>
                             (lambda (pr)
                               (cons (cons key (+ 1 (cdr pr)))
                                     (remove pr counts)))]
                            [else
                             (cons (cons key 1) counts)])))
                     (count-helper (cdr ngrams) counts)))]))))
    (count-helper ngram-lists '())))

(display "Enter the value of n for n-grams: ")
(define n
  (let ((input (read)))
    (if (number? input)
        input
        (begin
          (display "Invalid input. Using default value 2\n")
          2))))

(define all-ngrams
  (apply append (map (lambda (expr) (ngrams-for-expr expr n)) exprs)))

(define ngram-counts (count-ngrams all-ngrams))

(define sorted-ngram-counts
  (sort (lambda (e1 e2) (> (cdr e1) (cdr e2))) ngram-counts))

(write-data-to-file sorted-ngram-counts "statistics.scm")

(exit)
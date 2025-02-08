(load "src/MK/pmatch.scm")
(load "src/MK/prelude.scm")
(load "src/MK/corpus_zinkov.scm") ; TODO - change this back

(define max-n 5)

(define ngrams-for-expr ; expr => '((newtoken (parent_token2 parent_token1 ...)) ...)
  (lambda (expr)
    (letrec ((ngrams-for-expr
              (lambda (expr parent defn-name args)
                (define parent^ (if (> (length parent) (- max-n 1))
                                   (reverse (cdr (reverse parent)))
                                   parent))
                (define (context tok)
                  (cons tok parent^))
                (pmatch expr
                  [(eq? ,e1 ,e2)
                   (error 'bigrams-for-expr (format "unconverted eq?"))]
                  [(eqv? ,e1 ,e2)
                   (error 'bigrams-for-expr (format "unconverted eqv?"))]
                  [(cond . ,c*)
                   (error 'bigrams-for-expr (format "unconverted cond"))]
                  [(match ,e . ,c*)
                   (cons (cons 'match parent)
                         (append (ngrams-for-expr e (context 'match-against) defn-name args)
                                 (apply append (map (lambda (c) (ngrams-for-expr (cadr c)
                                                                                 (context 'match-body)
                                                                                 defn-name args))
                                                    c*))))]
                  [(quote ())
                   (list (context 'quoted-datum))]
                  [(quote ,x) (guard (symbol? x))
                   (list (context 'quoted-datum))]
                  [(quote ,ls) (guard (list? ls))
                   (list (context 'quoted-datum))]
                  [(quote ,_)
                   (error 'bigrams-for-expr (format "unknown quoted form ~s" _))]                  
                  [#t
                   (list (context 'bool))]
                  [#f
                   (list (context 'bool))]
                  [,n (guard (number? n))
                   (list (context 'num))]
                  [,x (guard (symbol? x))
                   (list
                     (cond
                       [(eqv? x defn-name) (context 'var)]
                       [(memv x args)      (context 'var)]
                       [else               (context 'var)]))]
                  ; because our interpreter doesn't support define, code as letrec
                  [(define ,id ,e) (guard (symbol? id))
                   (cons (context 'letrec)
                         (ngrams-for-expr e (context 'letrec-rhs) id args))]
                  [(lambda ,x ,body)
                   (cons (context 'lambda)
                         (ngrams-for-expr body
                                           (context 'lambda)
                                           defn-name
                                           (if (symbol? x) (list x) x)))]
                  [(if ,test ,conseq ,alt)
                   (cons (context 'if)
                         (append (ngrams-for-expr test (context 'if-test) defn-name args)
                                 (ngrams-for-expr conseq (context 'if-conseq) defn-name args)
                                 (ngrams-for-expr alt (context 'if-alt) defn-name args)))]
                  [(symbol? ,e)
                   (cons (context 'symbol?)
                         (ngrams-for-expr e (context 'symbol?) defn-name args))]
                  [(not ,e)
                   (cons (context 'not)
                         (ngrams-for-expr e (context 'not) defn-name args))]
                  [(and . ,e*)
                   (cons (context 'and)
                         (apply append (map (lambda (e) (ngrams-for-expr e (context 'and) defn-name args)) e*)))]
                  [(or . ,e*)
                   (cons (context 'or)
                         (apply append (map (lambda (e) (ngrams-for-expr e (context 'or) defn-name args)) e*)))]
                  [(list . ,e*)
                   (cons (context 'list)
                         (apply append (map (lambda (e) (ngrams-for-expr e (context 'list) defn-name args)) e*)))]
                  [(null? ,e)
                   (cons (context 'null?)
                         (ngrams-for-expr e (context 'null?) defn-name args))]
                  [(pair? ,e)
                   (cons (context 'pair?)
                         (ngrams-for-expr e (context 'pair?) defn-name args))]
                  [(car ,e)
                   (cons (context 'car)
                         (ngrams-for-expr e (context 'car) defn-name args))]
                  [(cdr ,e)
                   (cons (context 'cdr)
                         (ngrams-for-expr e (context 'cdr) defn-name args))]
                  [(cons ,e1 ,e2)
                   (cons (context 'cons)
                         (append (ngrams-for-expr e1 (context 'cons-e1) defn-name args)
                                 (ngrams-for-expr e2 (context 'cons-e2) defn-name args)))]
                  [(equal? ,e1 ,e2)
                   (cons (context 'equal?)
                         (append (ngrams-for-expr e1 (context 'equal?-e1) defn-name args)
                                 (ngrams-for-expr e2 (context 'equal?-e2) defn-name args)))]
                  [(let ,binding* ,e)
                   (cons (context 'let)
                         (append (apply append (map (lambda (binding) (ngrams-for-expr (cadr binding) (context 'let-rhs) defn-name args)) binding*))
                                 (ngrams-for-expr e (context 'let-body) defn-name args)))]
                  [(letrec ((,id (lambda ,x ,body))) ,e)
                   (cons (context 'letrec)
                         (append (ngrams-for-expr `(lambda ,x ,body) (context 'letrec-rhs) defn-name args)
                                 (ngrams-for-expr e (context 'letrec-body) id args)))]
                  [(,e . ,e*) ;; application
                   (cons (context 'app)
                         (append (ngrams-for-expr e (context 'app-rator) defn-name args)
                                 (apply append (map (lambda (e) (ngrams-for-expr e (context 'app-rand*) defn-name args)) e*))))]
                  [else (error 'bigrams-for-expr (format "unknown expression type ~s" expr))]))))
      (ngrams-for-expr expr '(top-level) #f #f))))

(define bigrams-for-expr ; expr => '((token2 token1) ...)
  (lambda (expr)
    (letrec ((bigrams-for-expr
              (lambda (expr parent defn-name args)
                (pmatch expr
                  [(eq? ,e1 ,e2)
                   (error 'bigrams-for-expr (format "unconverted eq?"))]
                  [(eqv? ,e1 ,e2)
                   (error 'bigrams-for-expr (format "unconverted eqv?"))]
                  [(cond . ,c*)
                   (error 'bigrams-for-expr (format "unconverted cond"))]
                  [(match ,e . ,c*)
                   (cons (list 'match parent)
                         (append (bigrams-for-expr e 'match-against defn-name args)
                                 (apply append (map (lambda (c) (bigrams-for-expr (cadr c) 'match-body defn-name args)) c*))))]
                  [(quote ())
                   (list (list 'quoted-datum parent))]
                  [(quote ,x) (guard (symbol? x))
                   (list (list 'quoted-datum parent))]
                  [(quote ,ls) (guard (list? ls))
                   (list (list 'quoted-datum parent))]
                  [(quote ,_)
                   (error 'bigrams-for-expr (format "unknown quoted form ~s" _))]                  
                  [#t
                   (list (list 'bool parent))]
                  [#f
                   (list (list 'bool parent))]
                  [,n (guard (number? n))
                   (list (list 'num parent))]
                  [,x (guard (symbol? x))
                   (list
                     (cond
                       [(eqv? x defn-name) (list 'var parent)]
                       [(memv x args) (list 'var parent)]
                       [else (list 'var parent)]))]
                  ; because our interpreter doesn't support define, code as letrec
                  [(define ,id ,e) (guard (symbol? id))
                   (cons (list 'letrec parent) (bigrams-for-expr e 'letrec-rhs id args))]
                  [(lambda ,x ,body)
                   (cons (list 'lambda parent)
                         (bigrams-for-expr body
                                           'lambda
                                           defn-name
                                           (if (symbol? x) (list x) x)))]
                  [(if ,test ,conseq ,alt)
                   (cons (list 'if parent)
                         (append (bigrams-for-expr test 'if-test defn-name args)
                                 (bigrams-for-expr conseq 'if-conseq defn-name args)
                                 (bigrams-for-expr alt 'if-alt defn-name args)))]
                  [(symbol? ,e)
                   (cons (list 'symbol? parent)
                         (bigrams-for-expr e 'symbol? defn-name args))]
                  [(not ,e)
                   (cons (list 'not parent)
                         (bigrams-for-expr e 'not defn-name args))]
                  [(and . ,e*)
                   (cons (list 'and parent)
                         (apply append (map (lambda (e) (bigrams-for-expr e 'and defn-name args)) e*)))]
                  [(or . ,e*)
                   (cons (list 'or parent)
                         (apply append (map (lambda (e) (bigrams-for-expr e 'or defn-name args)) e*)))]
                  [(list . ,e*)
                   (cons (list 'list parent)
                         (apply append (map (lambda (e) (bigrams-for-expr e 'list defn-name args)) e*)))]
                  [(null? ,e)
                   (cons (list 'null? parent)
                         (bigrams-for-expr e 'null? defn-name args))]
                  [(pair? ,e)
                   (cons (list 'pair? parent)
                         (bigrams-for-expr e 'pair? defn-name args))]
                  [(car ,e)
                   (cons (list 'car parent)
                         (bigrams-for-expr e 'car defn-name args))]
                  [(cdr ,e)
                   (cons (list 'cdr parent)
                         (bigrams-for-expr e 'cdr defn-name args))]
                  [(cons ,e1 ,e2)
                   (cons (list 'cons parent)
                         (append (bigrams-for-expr e1 'cons-e1 defn-name args)
                                 (bigrams-for-expr e2 'cons-e2 defn-name args)))]
                  [(equal? ,e1 ,e2)
                   (cons (list 'equal? parent)
                         (append (bigrams-for-expr e1 'equal?-e1 defn-name args)
                                 (bigrams-for-expr e2 'equal?-e2 defn-name args)))]
                  [(let ,binding* ,e)
                   (cons (list 'let parent)
                         (append (apply append (map (lambda (binding) (bigrams-for-expr (cadr binding) 'let-rhs defn-name args)) binding*))
                                 (bigrams-for-expr e 'let-body defn-name args)))]
                  [(letrec ((,id (lambda ,x ,body))) ,e)
                   (cons (list 'letrec parent)
                         (append (bigrams-for-expr `(lambda ,x ,body) 'letrec-rhs defn-name args)
                                 (bigrams-for-expr e 'letrec-body id args)))]
                  [(,e . ,e*) ;; application
                   (cons (list 'app parent)
                         (append (bigrams-for-expr e 'app-rator defn-name args)
                                 (apply append (map (lambda (e) (bigrams-for-expr e 'app-rand* defn-name args)) e*))))]
                  [else (error 'bigrams-for-expr (format "unknown expression type ~s" expr))]))))
      (bigrams-for-expr expr 'top-level #f #f))))


(define count-bigrams
  (lambda (bg-ls)
    (letrec ((count-bigrams
              (lambda (bg-ls count-al)
                (cond
                  [(null? bg-ls)
                   (sort-counts-al-by-symbols count-al)]
                  [else
                   (let ((bg (car bg-ls)))
                     (let ((count-al
                            (cond
                              [(assoc bg count-al) =>
                               (lambda (pr)
                                 (cons (cons bg (add1 (cdr pr)))
                                       (remove pr count-al)))]
                              [else (cons (cons bg 1) count-al)])))
                       (count-bigrams (cdr bg-ls) count-al)))]))))
      (count-bigrams bg-ls '()))))

(define sort-counts-al-by-symbols
  (lambda (counts-al)
    (sort
     (lambda (e1 e2)
       (or
        (string<? (symbol->string (caar e1))
                  (symbol->string (caar e2)))
        (and
         (string=? (symbol->string (caar e1))
                   (symbol->string (caar e2)))
         (string<? (symbol->string (cadar e1))
                   (symbol->string (cadar e2))))))
     counts-al)))

(define sort-counts-al-by-counts
  (lambda (counts-al)
    (sort
     (lambda (e1 e2) (> (cdr e1) (cdr e2)))
     counts-al)))

(define sort-counts-al-by-type/counts
  (lambda (counts-al)
    (sort
     (lambda (e1 e2)
       (or
        (string<? (symbol->string (caar e1))
                  (symbol->string (caar e2)))
        (and
         (string=? (symbol->string (caar e1))
                   (symbol->string (caar e2)))
         (> (cdr e1) (cdr e2)))))
     counts-al)))

(define safe-ngrams-for-expr
  (lambda (expr)
    (guard (exn [else '()]) ; Return empty list on error
      (ngrams-for-expr expr))))

(define ngrams (map reverse (apply append (map safe-ngrams-for-expr exprs))))
(display ngrams)
(newline)

; (define bigrams (map reverse (apply append (map bigrams-for-expr exprs))))
(define bigram-counts (count-bigrams ngrams))
(define bigrams-sorted-by-counts (sort-counts-al-by-counts bigram-counts))

;; this is the important one
(define bigrams-sorted-by-type/counts (sort-counts-al-by-type/counts bigram-counts))

(define merge-entries
  (lambda (alist key-f)
    (let loop ((alist alist)
               (table '()))
      (pmatch alist
        [() table]
        [((,k . ,n) . ,rest)
         (let ((key (key-f k)))
           (cond
             [(assoc key table) =>
              (lambda (pr)
                (let ((m (cdr pr)))
                  (loop rest (cons (cons key (+ n m)) (remove pr table)))))]
             [else (loop rest (cons (cons key n) table))]))]))))

(define alist-value-descending-comparator
  (lambda (e1 e2) (> (cdr e1) (cdr e2))))

(define global-frequency-ordering
  (list-sort alist-value-descending-comparator
             (merge-entries bigrams-sorted-by-type/counts
                            cadr)))

(write-data-to-file bigrams-sorted-by-type/counts "src/MK/statistics.scm")

;; (exit)

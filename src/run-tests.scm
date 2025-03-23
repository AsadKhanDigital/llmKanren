(load "src/run-with-llm.scm")
(load "src/run-with-zinkov.scm")
(load "src/run-with-expert.scm")

(define (display-separator)
  (display "\n----------------------------------------\n"))

(define (display-section title)
  (display-separator)
  (display title)
  (display-separator))

(define (run-single-test system-name system-func logic-vars definitions test-inputs test-outputs n-values . absento-symbols)
  (if (null? n-values)
      (begin
        (display-section system-name)
        (apply system-func logic-vars definitions test-inputs test-outputs absento-symbols))
      (for-each 
        (lambda (n)
          (display-section (string-append system-name " (n=" (number->string n) ")"))
          (apply system-func logic-vars definitions test-inputs test-outputs n absento-symbols))
        n-values)))

(define (run-test-case test-case)
  (let ((name (car test-case))
        (logic-vars (cadr test-case))
        (definition (caddr test-case))
        (inputs (cadddr test-case))
        (outputs (car (cddddr test-case)))
        (absento-symbols (if (> (length test-case) 5) (cdr (cddddr test-case)) '())))
    
    (display-section (string-append "Test Case: " name))
    
    Run Expert system (no n-value)
    (apply run-single-test "Expert" run-with-expert 
                     logic-vars definition inputs outputs '() absento-symbols)
    
    ;; Run Zinkov system with n=2 and n=3
    (apply run-single-test "Zinkov" run-with-zinkov 
                     logic-vars definition inputs outputs '(2 3) absento-symbols)
    
    ;; Run LLM system with n=2, n=3, and n=4
    (apply run-single-test "LLM" run-with-llm 
                     logic-vars definition inputs outputs '(2 3 4) absento-symbols)
    ))

;; Define a function to run all test cases
(define (run-all-test-cases test-cases)
  (for-each run-test-case test-cases))

(define test-cases
  (list

    (list "basic-append-no-absento"
          '(q r)
          '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
          '((f '() '()) (f '(a) '(b)) (f '(c d) '(e f)))
          '(() (a b) (c d e f)))
    
    (list "append-recursive"
          '(q r)
          '((define append (lambda (l s) (if ,q ,r (cons (car l) (append (cdr l) s))))))
          '((append '(a b c) '(d e)))
          '((a b c d e))
          'a 'b 'c 'd 'e)

    (list "full-foldr-synthesis"
          '(body)
          '((define foldr (lambda (f acc xs) ,body)))
          '((foldr 'g2 'g1 '())
            (foldr (lambda (a d) (cons a d)) 'g3 '(g4))
            (foldr (lambda (a d) (cons a d)) 'g4 '(g5 g6))
            (foldr (lambda (v1 v2) (equal? v1 v2)) 'g7 '(g7)))
          '(g1 
            (g4 . g3) 
            (g5 g6 . g4)
            #t)
          'g1 'g2 'g3 'g4 'g5 'g6 'g7)

    (list "full-append-synthesis"
          '(body)
          '((define append (lambda (l s) ,body)))
          '((append '() '()) (append '(a) '(b)) (append '(c d) '(e f)))
          '(() (a b) (c d e f))
          'a 'b 'c 'd 'e 'f)

    (list "map-hard-0"
         '(body)
         '((define map (lambda (f xs) ,body)))
         '((map 'g1 '())
           (map (lambda (p) (car p)) '((g2 . g3)))
           (map (lambda (p) (cdr p)) '((g4 . g5) (g6 . g7))))
         '(() (g2) (g5 g7))
         'g1 'g2 'g3 'g4 'g5 'g6 'g7)

    (list "reverse-synthesis"
          '(q r s)
          '((define reverse (lambda (xs) 
                             (if (null? xs)
                                 '()
                                 (,q (reverse ,r) ,s)))))
          '((reverse '())
            (reverse '(g1))
            (reverse '(g2 g3))
            (reverse '(g4 g5 g6)))
          '(() 
            (g1)
            (g3 g2)
            (g6 g5 g4))
          'g1 'g2 'g3 'g4 'g5 'g6 'g7)

    ; (list "hard-append" ; Expert Times Out
    ;       '(q r s t)
    ;       '((define f (lambda (l s) (if ,q ,r (,s (car l) (f (cdr l) s))))))
    ;       '((f '() '()) (f '(a) '(b)) (f '(c d) '(e f)))
    ;       '(() (a b) (c d e f))
    ;       'a 'b 'c 'd 'e 'f)

    ; (list "full-map-synthesis" ; Extremely Hard
    ;       '(body)
    ;       '((define map (lambda (f xs) ,body)))
    ;       '((map (lambda (x) (+ x 1)) '())
    ;         (map (lambda (x) (* x 2)) '(1 2 3))
    ;         (map (lambda (x) (cons x '())) '(a b c))
    ;         (map car '((1 2) (3 4) (5 6))))
    ;       '(() 
    ;         (2 4 6)
    ;         ((a) (b) (c))
    ;         (1 3 5)))

    ; (list "full-filter-synthesis" ; Extremely Hard
    ;       '(body)
    ;       '((define filter (lambda (pred xs) ,body)))
    ;       '((filter (lambda (x) (> x 3)) '())
    ;         (filter (lambda (x) (> x 3)) '(1 2 3 4 5 6))
    ;         (filter symbol? '(a 1 b 2 c 3))
    ;         (filter null? '(() (1) () (2 3) ())))
    ;       '(() 
    ;         (4 5 6)
    ;         (a b c)
    ;         (() () ())))
  ))

(run-all-test-cases test-cases)

(exit)
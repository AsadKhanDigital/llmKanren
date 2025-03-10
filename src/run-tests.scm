(load "src/run-with-llm.scm")
(load "src/run-with-zinkov.scm")
(load "src/run-with-expert.scm")

(define (display-separator)
  (display "\n----------------------------------------\n"))

(define (display-section title)
  (display-separator)
  (display title)
  (display-separator))

(define (run-single-test system-name system-func logic-vars definitions test-inputs test-outputs n-values)
  (if (null? n-values)
      (begin
        (display-section system-name)
        (system-func logic-vars definitions test-inputs test-outputs))
      (for-each 
        (lambda (n)
          (display-section (string-append system-name " (n=" (number->string n) ")"))
          (system-func logic-vars definitions test-inputs test-outputs n))
        n-values)))

(define (run-test-case test-case)
  (let ((name (car test-case))
        (logic-vars (cadr test-case))
        (definition (caddr test-case))
        (inputs (cadddr test-case))
        (outputs (car (cddddr test-case))))
    
    (display-section (string-append "Test Case: " name))
    
    ; Run Expert system (no n-value)
    (run-single-test "Expert" run-with-expert 
                     logic-vars definition inputs outputs '())
    
    ;; Run Zinkov system with n=2 and n=3
    (run-single-test "Zinkov" run-with-zinkov 
                     logic-vars definition inputs outputs '(2 3))
    
    ;; Run LLM system with n=2, n=3, and n=4
    (run-single-test "LLM" run-with-llm 
                     logic-vars definition inputs outputs '(2 3 4))
    ))

;; Define a function to run all test cases
(define (run-all-test-cases test-cases)
  (for-each run-test-case test-cases))

(define test-cases
  (list

    (list "basic-append"
          '(q r)
          '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
          '((f '() '()) (f '(a) '(b)) (f '(c d) '(e f)))
          '(() (a b) (c d e f)))
    
    (list "append-recursive"
          '(q r)
          '((define append (lambda (l s) (if ,q ,r (cons (car l) (append (cdr l) s))))))
          '((append '(a b c) '(d e)))
          '((a b c d e)))

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
            #t))

    (list "full-append-synthesis"
          '(body)
          '((define append (lambda (l s) ,body)))
          '((append '() '()) (append '(a) '(b)) (append '(c d) '(e f)))
          '(() (a b) (c d e f)))

    ; (list "full-reverse-synthesis"
    ;       '(body)
    ;       '((define reverse (lambda (xs) ,body)))
    ;       '((reverse '())
    ;         (reverse '(a))
    ;         (reverse '(1 2 3))
    ;         (reverse '(x y z w)))
    ;       '(() 
    ;         (a)
    ;         (3 2 1)
    ;         (w z y x)))

    ; (list "full-length-synthesis"
    ;       '(body)
    ;       '((define length (lambda (xs) ,body)))
    ;       '((length '())
    ;         (length '(a))
    ;         (length '(1 2 3))
    ;         (length '(w x y z)))
    ;       '(0 1 3 4))

    ; (list "hard-append" ; Expert Times Out
    ;       '(q r s t)
    ;       '((define f (lambda (l s) (if ,q ,r (,s (car l) (f (cdr l) s))))))
    ;       '((f '() '()) (f '(a) '(b)) (f '(c d) '(e f)))
    ;       '(() (a b) (c d e f)))

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
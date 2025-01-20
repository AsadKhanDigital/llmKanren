(define allow-incomplete-search? #f)
(define lookup-optimization? #t)

(load "mk-vicare.scm")
(load "mk.scm")
(load "interp-core.scm")
(load "interp-app-optimization.scm")
(load "construct-ordering.scm")


(define (run-with-zinkov lvars defns test_inputs test_outputs)
  
    (system "cp corpus-zinkov.scm corpus.scm")

    (load "n-grams.scm")
    (load "interp-simplified-dynamic.scm")

    (time
    

    (letrec ((query `(run 1 (prog)
                    (fresh ,lvars
                      (== (,'quasiquote ,(map cdr defns))
                          prog)
                      (evalo
                      (list 'letrec prog
                        (,'quasiquote (list . ,test_inputs)))
                      (,'quasiquote ,test_outputs))))))
    
    (display "Orderings: ")
    (newline)
    (pretty-print orderings-alist)
    (newline)
    (newline)
    (display "Query:")
    (newline)
    (pretty-print query)
    (newline)
    (newline)
    (display "Query Evaluated:")
    (newline)
    (display (eval query))
    (newline)
    (newline)
    (display "Inc-count: ")
    (display inc-count)
    (set! inc-count 0)
    (newline)
    (newline)
    (display "Evalo-count: ")
    (display eval-expo-call-count)
    (set! eval-expo-call-count 0)
    (newline)
    (newline))))
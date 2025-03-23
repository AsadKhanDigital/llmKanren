(define allow-incomplete-search? #f)
(define lookup-optimization? #t)

(load "src/MK/mk-vicare.scm")
(load "src/MK/mk.scm")
(load "src/MK/interp-core.scm")
(load "src/MK/interp-app-optimization.scm")
(load "src/MK/construct-ordering.scm")
(load "src/MK/interp-expert.scm")

(define (run-with-expert lvars defns test_inputs test_outputs . absento_symbols)

    (set! *max-n* 0)

    (time

    (letrec ((query `(run 1 (prog)
                    (fresh ,lvars
                      ,@(map (lambda (sym) `(absento ',sym prog)) absento_symbols)
                      (== (,'quasiquote ,(map cdr defns))
                          prog)
                      (evalo
                      (list 'letrec prog
                        (,'quasiquote (list . ,test_inputs)))
                      (,'quasiquote ,test_outputs))))))
        
        ; (display "Orderings: ")
        ; (newline)
        ; (pretty-print expert-ordering-alist)
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
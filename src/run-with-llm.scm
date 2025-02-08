(define allow-incomplete-search? #f)
(define lookup-optimization? #t)

(load "src/MK/mk-vicare.scm")
(load "src/MK/mk.scm")
(load "src/MK/interp-core.scm")
(load "src/MK/interp-app-optimization.scm")
(load "src/MK/construct-ordering.scm")

(define (run-with-llm logic_variables definitions test_inputs test_outputs)

    (system (apply string-append "python3 src/run.py " (map (lambda (x) (format "\"~s\" " x)) (list logic_variables definitions test_inputs test_outputs))))

    (load "src/MK/n-grams.scm")
    (load "src/MK/interp-simplified-dynamic.scm")

    (letrec 
    
    ((query `(run 1 (prog)
                    (fresh ,logic_variables
                      (== (,'quasiquote ,(map cdr definitions))
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
    (newline))
)
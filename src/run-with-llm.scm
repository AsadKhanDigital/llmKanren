(define *output-table-file-name* "tmp/variant-dynamic-ordering-table.scm")
(define allow-incomplete-search? #f)
(define lookup-optimization? #f)

(load "mk-vicare.scm")
(load "mk.scm")
(load "interp-core.scm")
(load "interp-app-optimization.scm")
(load "construct-ordering.scm")
(load "interp-simplified-dynamic.scm")

;; Define a function that executes the run expression
(define (execute-run run-expr)
  (let ((begin-stats (statistics)))
    (let ((result run-expr))
      (display "Result: ")
      (write result)
      (newline))))

(define-syntax preprocess-run-expr
  (syntax-rules ()
    ((_ expr)
     (let ((str (format "~s" 'expr)))
       (system (string-append "python3 run.py \"" str "\""))))))

;; (define (run-with-llm run-expr)
;;   (let ((str (format "~s" run-expr)))
;;     (system (string-append "python3 run.py \"" str "\"")))
;;   (system "chez n-grams.scm")
;;   (execute-run run-expr))

; (define (run-with-llm run-expr variables, test_cases, temperature, n-gram order) 

;   (let ((str (format "~s" run-expr)))

;     (system (string-append "python3 run.py \"" str "\"")))

;   (system "chez n-grams.scm")

;   (execute-run run-expr))

(define (run-with-llm lvars defns test_inputs test_outputs)
  (display (list lvars defns test_inputs test_outputs))
  (newline)
  (display "Executing run.py")
  (newline)
  (system (apply string-append "python run.py " (map (lambda (x) (format "\"~s\" " x)) (list lvars defns test_inputs test_outputs))))
  (display "Writing to statistics.scm")
  (newline)
  (load "n-grams.scm") ; load n-grams.scm at top of file and then make it into a function
  (display "Extracting one definition")
  (newline)
  (display (car (cdr (car defns))))
  (newline)
  (display "Running MK query")
  (newline)
  (display "Test Outputs")
  (newline)
  (display test_outputs)
  (newline)

  ;; represent test cases
  ;; extract function name (e.g. something generic instead of "append")
  ;; probably dont need to do this as discussed in previous call but
  ;; abstract away absentos? maybe need to map them?

  (letrec ((query `(run 1 (prog)
                  (fresh ,lvars
                    (absento 'a prog)
                    (absento 'b prog)
                    (absento 'c prog)
                    (absento 'd prog)
                    (absento 'e prog)
                    (absento 'f prog)
                    (== ',(car (cdr (car defns)))
                        prog)
                    (evalo
                    `(letrec ((append ,prog))
                        (list
                        (append '() '())
                        (append '(a) '(b))
                        (append '(c d) '(e f))))
                    ',test_outputs)
                      ))))
        (display query)
        (newline)
        (display (eval query))
        (newline)
        (display "Test Inputs")
        (newline)
        (display test_inputs)
        ))

(define (run-with-llm lvars defns test_inputs test_outputs)
  (display (list lvars defns test_inputs test_outputs))
  (newline)
  (display "Executing run.py:")
  (newline)
  (system (apply string-append "python run.py " (map (lambda (x) (format "\"~s\" " x)) (list lvars defns test_inputs test_outputs))))
  (display "Writing to statistics.scm")
  (newline)
  (load "n-grams.scm") ; load n-grams.scm at top of file and then make it into a function
  (display "Extracting one definition:")
  (newline)
  (display (car (cdr (car defns))))
  (newline)
  (display "Running MK query:")
  (newline)
  (display "Test Inputs:")
  (newline)
  (display test_inputs)
  (newline)
  (display "Test Outputs:")
  (newline)
  (display test_outputs)
  (newline)

  ;; represent test cases
  ;; extract function name (e.g. something generic instead of "append")
  ;; probably dont need to do this as discussed in previous call but
  ;; abstract away absentos? maybe need to map them?

  (let ((lambda-expr (car (cdr (car defns)))))
    (display "Lambda Expression:")
    (newline)
    (display lambda-expr))
    (newline)

  ;; Modify the letrec section to use the defns parameter directly
  (letrec ((query `(run 1 (prog)
                  (fresh ,lvars
                    (absento 'a prog)
                    (absento 'b prog)
                    (absento 'c prog)
                    (absento 'd prog)
                    (absento 'e prog)
                    (absento 'f prog)
                    ; (== (car (cdr (car ,defns)))
                    ;     prog)
                    (== `(lambda (l s)
                          (if ,q
                              ,r
                              (cons (car l) (append (cdr l) s))))
                        prog)
                    (evalo
                    `(letrec ((append ,prog))
                      (list ,@',test_inputs))
                    ',test_outputs)))))
        (display "Query:")
        (newline)
        (display query)
        (newline)
        (display "Query Evaluated:")
        (newline)
        (display (eval query))
        (newline)
        ))
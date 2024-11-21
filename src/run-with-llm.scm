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


(define (run-with-llm lvars defns test_inputs test_outputs debug?)
  (let* ((output-filename 
          (string-append "run/output-" 
                        (number->string 
                          (time-second (current-time)))  ; Changed this line
                        ".txt"))
         (start-time (current-time)))  ; Move to let* binding
    
    (transcript-on output-filename)
    
    (display "Generating corpus.scm:")
    (newline)
    (system (apply string-append "python run.py " 
                  (map (lambda (x) (format "\"~s\" " x)) 
                       (list lvars defns test_inputs test_outputs debug?))))
    (display "Writing to statistics.scm")
    (newline)
    (load "n-grams.scm") ; load n-grams.scm at top of file and then make it into a function
    (display "--------------------------------------")
    (newline)
    (display "Running MK query")
    (newline)
    (display "--------------------------------------")
    (newline)
    (display "Test Inputs:")
    (newline)
    (display test_inputs)
    (newline)
    (display "Test Outputs:")
    (newline)
    (display test_outputs)
    (newline)
    (display "--------------------------------------")
    (newline)
    (display defns)
    (newline)

    ;; represent test cases
    ;; extract function name (e.g. something generic instead of "append")
    ;; probably dont need to do this as discussed in previous call but
    ;; abstract away absentos? maybe need to map them?

    ;; Modify the letrec section to use the defns parameter directly
    (letrec ((query `(run 1 (prog)
                    (fresh ,lvars
                      (== (,'quasiquote ,(map cdr defns))
                          prog)
                      ; (== `(lambda (l s)
                      ;       (if ,q
                      ;           ,r
                      ;           (cons (car l) (append (cdr l) s))))
                      ;     prog)
                      (evalo
                      (list 'letrec prog
                        (,'quasiquote (list . ,test_inputs)))
                      (,'quasiquote ,test_outputs))))))
      (let* ((end-time (current-time))
             (elapsed-time (time-difference end-time start-time))
             (seconds (time-second elapsed-time))
             (milliseconds (/ (time-nanosecond elapsed-time) 1000000.0)))
        (display "Query:")
        (newline)
        (pretty-print query)
        (newline)
        (newline)
        (display "Query Evaluated:")
        (newline)
        (display (eval query))
        (newline)
        (display "--------------------------------------")
        (newline)
        (display "Elapsed time: ")
        (display (+ seconds milliseconds))
        (display " milliseconds")
        (newline)))
    (transcript-off)))
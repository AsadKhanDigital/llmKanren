(define *output-table-file-name* "tmp/variant-dynamic-ordering-table.scm")
(define allow-incomplete-search? #f)
(define lookup-optimization? #f)

(load "mk-vicare.scm")
(load "mk.scm")
(load "interp-core.scm")
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

(define (run-with-llm run-expr)
  (let ((str (format "~s" run-expr)))
    (system (string-append "python3 run.py \"" str "\"")))
  (system "chez n-grams.scm")
  (execute-run run-expr))
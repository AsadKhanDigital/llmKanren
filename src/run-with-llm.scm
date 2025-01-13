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
  ;; Start total clock right away
  (let* ((total-start (current-time))

         ;; Time the LLM (Python) call
         (llm-start (current-time))
         ;; 1) LLM call: python run.py ...
         (unused-rc (system (apply string-append 
                                   "python run.py "
                                   (map (lambda (x) (format "\"~s\" " x))
                                        (list lvars defns test_inputs test_outputs debug?)))))

         (llm-end (current-time))
         (llm-elapsed (time-difference llm-end llm-start))

         ;; Start transcript and do everything else
         (output-filename (string-append
                           "run/output-"
                           (number->string (time-second llm-end)) ; for uniqueness
                           ".txt")))

    ;; Turn on transcript
    (transcript-on output-filename)

    (display "LLM call done.\n")
    (display "LLM call time (ms): ")
    (display (+ (* 1000 (time-second llm-elapsed))
                (/ (time-nanosecond llm-elapsed) 1000000.0)))
    (newline)
    (newline)

    ;; Next, time the Scheme portion
    (display "Writing to statistics.scm\n")
    (let* ((scheme-start (current-time))
           (unused-rc2 (load "n-grams.scm")) ; analyze bigrams from corpus, etc.
           ;; now run the query
           (query
            `(run 1 (prog)
               (fresh ,lvars
                 (== (,'quasiquote ,(map cdr defns)) prog)
                 (evalo
                  (list 'letrec prog
                        (,'quasiquote (list . ,test_inputs)))
                  (,'quasiquote ,test_outputs)))))
           (scheme-mid (current-time))  ; time after n-grams load, before eval
           (scheme-result (eval query))
           (scheme-end (current-time))
           (scheme-elapsed (time-difference scheme-end scheme-start))
           (total-end scheme-end)
           (total-elapsed (time-difference total-end total-start)))

      ;; Print out standard logs
      (display "Query:\n")
      (pretty-print query)
      (newline)
      (display "Query Evaluated:\n")
      (display scheme-result)
      (newline)
      (display "Number of evalo calls: ")
      (display *eval-expo-call-count*)
      (newline)
      (set! *eval-expo-call-count* 0)
      (display "--------------------------------------\n")
      (display "Number of inc calls: ")
      (display *inc-count*)
      (newline)
      (set! *inc-count* 0)
      (display "--------------------------------------\n")
      (display "Clause Ordering:\n")
      (pretty-print orderings-alist)
      (newline)
      (display "--------------------------------------\n")
      (display "LLM call time (ms): ")
      (display (+ (* 1000 (time-second llm-elapsed))
                  (/ (time-nanosecond llm-elapsed) 1000000.0)))
      (newline)
      (display "Scheme logic time (ms): ")
      (display (+ (* 1000 (time-second scheme-elapsed))
                  (/ (time-nanosecond scheme-elapsed) 1000000.0)))
      (newline)
      (display "Total time (ms): ")
      (display (+ (* 1000 (time-second total-elapsed))
                  (/ (time-nanosecond total-elapsed) 1000000.0)))
      (newline))

    ;; Turn off transcript
    (transcript-off)))

(define (run-with-expert-ordering lvars defns test_inputs test_outputs debug?)
  ;; Start total clock right away
  (let* ((total-start (current-time))
         ;; For the “expert only” approach, we do no LLM Python call:
         (llm-start (current-time))
         ;; we skip the entire python step
         (llm-end (current-time))
         (llm-elapsed (time-difference llm-end llm-start))

         ;; Optionally set the global `lookup-optimization?` or some other
         ;; variable so that `interp-simplified-dynamic.scm` uses only expert-ordering:
         (unused (set! lookup-optimization? #f))  ;; forcibly do not reorder
         (output-filename (string-append
                           "run/output-"
                           (number->string (time-second (current-time)))
                           "-expert.txt")))

    ;; Turn on transcript
    (transcript-on output-filename)

    (display "Expert ordering version (no LLM)!\n")
    (display "LLM call time (ms): 0\n\n")  ; we skip Python call, so ~0

    (display "Skipping n-grams.scm, using default expert ordering...\n\n")

    ;; Next, time the Scheme portion
    (let* ((scheme-start (current-time))

           ;; do *not* load "n-grams.scm" – skipping the dynamic approach
           ;; just run the query with the same code
           (query
            `(run 1 (prog)
               (fresh ,lvars
                 (== (,'quasiquote ,(map cdr defns)) prog)
                 (evalo
                  (list 'letrec prog
                        (,'quasiquote (list . ,test_inputs)))
                  (,'quasiquote ,test_outputs)))))
           (scheme-mid (current-time))
           (scheme-result (eval query))
           (scheme-end (current-time))
           (scheme-elapsed (time-difference scheme-end scheme-start))
           (total-end scheme-end)
           (total-elapsed (time-difference total-end total-start)))

      ;; Print out standard logs
      (display "Query:\n")
      (pretty-print query)
      (newline)
      (display "Query Evaluated:\n")
      (display scheme-result)
      (newline)
      (display "Number of evalo calls: ")
      (display *eval-expo-call-count*)
      (newline)
      (set! *eval-expo-call-count* 0)
      (display "--------------------------------------\n")
      (display "Number of inc calls: ")
      (display *inc-count*)
      (newline)
      (set! *inc-count* 0)
      (display "--------------------------------------\n")
      (display "Clause Ordering:\n")
      (pretty-print orderings-alist)
      (newline)
      (display "--------------------------------------\n")
      (display "LLM call time (ms): 0\n")   ; again ~0, no python call
      (display "Scheme logic time (ms): ")
      (display (+ (* 1000 (time-second scheme-elapsed))
                  (/ (time-nanosecond scheme-elapsed) 1000000.0)))
      (newline)
      (display "Total time (ms): ")
      (display (+ (* 1000 (time-second total-elapsed))
                  (/ (time-nanosecond total-elapsed) 1000000.0)))
      (newline))

    ;; Turn off transcript
    (transcript-off)))

(define (run-compare lvars defns test_inputs test_outputs debug?)
  (display "=== RUNNING with LLM-based dynamic ordering ===\n")
  (run-with-llm lvars defns test_inputs test_outputs debug?)

  (newline)
  (display "=== RUNNING with EXPERT ordering only ===\n")
  (run-with-expert-ordering lvars defns test_inputs test_outputs debug?))


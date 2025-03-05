(load "src/run-with-llm.scm")
(load "src/run-with-zinkov.scm")
(load "src/run-with-expert.scm")

(define (display-separator)
  (display "\n----------------------------------------\n"))

(define (display-section title)
  (display-separator)
  (display title)
  (display-separator))

;; Define a generic test runner function to run a single test case for one system
(define (run-single-test system-name system-func logic-vars definitions test-inputs test-outputs n-values)
  ;; If n-values is empty (for Expert system), run without n
  (if (null? n-values)
      (begin
        (display-section system-name)
        (system-func logic-vars definitions test-inputs test-outputs))
      ;; Otherwise run for each n value
      (for-each 
        (lambda (n)
          (display-section (string-append system-name " (n=" (number->string n) ")"))
          (system-func logic-vars definitions test-inputs test-outputs n))
        n-values)))

;; Define a function to run all systems for a single test case
(define (run-test-case test-case)
  (let ((name (car test-case))
        (logic-vars (cadr test-case))
        (definition (caddr test-case))
        (inputs (cadddr test-case))
        (outputs (car (cddddr test-case))))
    
    (display-section (string-append "Test Case: " name))
    
    ;; Run Expert system (no n-value)
    (run-single-test "Expert" run-with-expert 
                     logic-vars definition inputs outputs '())
    
    ;; Run Zinkov system with n=2 and n=3
    (run-single-test "Zinkov" run-with-zinkov 
                     logic-vars definition inputs outputs '(2 3))
    
    ;; Run LLM system with n=2, n=3, and n=4
    (run-single-test "LLM" run-with-llm 
                     logic-vars definition inputs outputs '(2 3 4))))

;; Define a function to run all test cases
(define (run-all-test-cases test-cases)
  (for-each run-test-case test-cases))

;; ========== Test Case Definitions ==========
;; Each test case is a list with the format:
;; (name logic-vars definition inputs outputs)

(define test-cases
  (list
    ;; Test Case 1: Basic append
    (list "basic-append"
          '(q r)
          '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
          '((f '() '()) (f '(a) '(b)) (f '(c d) '(e f)))
          '(() (a b) (c d e f)))
    
    ;; Add more test cases by adding more lists here
    ;; For example:
    (list "another-function"
          '(a b)
          '((define g (lambda (x) (if ,a ,b (+ x 1)))))
          '((g 0) (g 5))
          '(1 6))
  ))

;; ========== Run all test cases ==========
(run-all-test-cases test-cases)

(exit)
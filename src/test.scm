(load "run-with-llm.scm")

;; Test #1:
(run-compare
  '(q r)
  '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
  '((f '() '())
    (f '(a) '(b))
    (f '(c d) '(e f)))
  '(()
    (a b)
    (c d e f))
  #f) ;; Last parameter is debug? #t or #f

;; Test #2:
(run-compare
  '(q r)
  '((define append (lambda (l s) (if ,q ,r (cons (car l) (append (cdr l) s)))))) 
  '((append '() '())
    (append '(a) '(b))
    (append '(c d) '(e f)))
  '(()
    (a b)
    (c d e f))
  #t)  ;; For example, you might set debug to #t here

;; Add as many more test cases as you want below:
;; (run-with-llm
;;   '(your-var-here)
;;   '((define your-fn (lambda (params ...) ...)))
;;   '((your-fn ...) (your-fn ...) ...)
;;   '(expected-result-1 expected-result-2 ...)
;;   #f)

(exit)
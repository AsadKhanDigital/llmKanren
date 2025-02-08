(load "run-with-expert.scm")

; (run-with-expert 
;     '(q r)
;     '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
;     '((f '() '())
;         (f '(a) '(b))
;         (f '(c d) '(e f)))
;     '(()
;         (a b)
;         (c d e f))
; )

(run-with-expert
  '(append-def)  ;; Logic variable name
  '((define append ,append-def))  ;; Definition template
  '((append '() '())  ;; Test inputs
    (append '(a) '(b))
    (append '(c d) '(e f)))
  '(()  ;; Expected outputs
    (a b)
    (c d e f)))

(exit)
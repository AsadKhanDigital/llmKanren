(load "src/run-with-llm.scm")

(run-with-llm 
    '(q r)
    '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
    '((f '() '())
        (f '(a) '(b))
        (f '(c d) '(e f)))
    '(()
        (a b)
        (c d e f))
)

(exit)
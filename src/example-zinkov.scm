(load "src/run-with-zinkov.scm")

(run-with-zinkov 
    '(q r)
    '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
    '((f '() '())
        (f '(a) '(b))
        (f '(c d) '(e f)))
    '(()
        (a b)
        (c d e f))
    2)

(exit)
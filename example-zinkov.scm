(load "run-with-zinkov.scm")

; (run-with-zinkov 
;     '(q r)
;     '((define f (lambda (l s) (if ,q ,r (cons (car l) (f (cdr l) s))))))
;     '((f '() '())
;         (f '(a) '(b))
;         (f '(c d) '(e f)))
;     '(()
;         (a b)
;         (c d e f))
; )

(run-with-zinkov 
    '(a)
    '(
        (define interleave
        (lambda (l1 l2)
            (if (null? ,a)
                l1
                (cons (car l1)
                    (interleave l2 (cdr l1))))))
    )
    '(
        (interleave '() '())
        (interleave '(g1) '(g2))
        (interleave '(g3 g4) '(g5 g6))
    )
    '(
        ()
        (g1 g2)
        (g3 g5 g4 g6)
    )
)

(exit)
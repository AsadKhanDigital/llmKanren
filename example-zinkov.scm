(load "run-with-zinkov.scm")

(run-with-zinkov
  '(q)
  '((define append (lambda (l s)
                    (if (null? l)
                        s
                        (cons ,q (append (cdr l) s))))))
  '((append '(a b c) '(d e)))
  '((a b c d e)))

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

; (run-with-zinkov 
;     '(a)
;     '(
;         (define interleave
;         (lambda (l1 l2)
;             (if (null? ,a)
;                 l1
;                 (cons (car l1)
;                     (interleave l2 (cdr l1))))))
;     )
;     '(
;         (interleave '() '())
;         (interleave '(g1) '(g2))
;         (interleave '(g3 g4) '(g5 g6))
;     )
;     '(
;         ()
;         (g1 g2)
;         (g3 g5 g4 g6)
;     )
; )

; (run-with-zinkov
;   '(a) ; Logic variable in the lambda body
;   '((define foldr (lambda (f acc xs) ,a))) ; Definition template with hole 'a'
;   '((foldr 'any-f 'init-acc '()) ; Test inputs (foldr calls)
;     (foldr (lambda (a d) (cons a d)) 'acc '(elem))
;     (foldr (lambda (a d) (cons a d)) 'acc2 '(elem1 elem2))
;     (foldr (lambda (v1 v2) (equal? v1 v2)) 'sym '(sym)))
;   '(init-acc ; Expected outputs
;     (elem . acc)
;     (elem1 elem2 . acc2)
;     #t))

; (run-with-zinkov
;   '(append-def)  ;; Logic variable name
;   '((define append ,append-def))  ;; Definition template
;   '((append '() '())  ;; Test inputs
;     (append '(a) '(b))
;     (append '(c d) '(e f)))
;   '(()  ;; Expected outputs
;     (a b)
;     (c d e f)))

(exit)
(load "run-with-llm.scm")


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

(run-with-llm
  '(q)
  '(
    (define remove
      (lambda (x ls)
        (if (null? ls)
            '()
            (if (equal? (car ls) x)
                (remove x (cdr ls))
                (cons (car ls) (remove x (cdr ls)))))))
   )
  '(
    (remove 'foo '())
    (remove 'foo '(foo))
    (remove 'foo '(1))
    (remove 'foo '(2 foo 3))
    (remove 'foo '(bar foo baz (foo) foo ((quux foo) foo)))
    (remove 'foo '((4 foo) foo (5 (foo 6 foo)) foo 7 foo (8)))
   )
  '(
    ()
    ()
    (1)
    (2 3)
    (bar baz (foo) ((quux foo) foo))
    ((4 foo) (5 (foo 6 foo)) 7 (8))
  )
)

(run-with-llm
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
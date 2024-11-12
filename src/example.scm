(load "run-with-llm.scm")

(run-with-llm
  (run 1 (prog)
    (fresh (q r s)
      (absento 'a prog)
      (absento 'b prog)
      (absento 'c prog)
      (absento 'd prog)
      (absento 'e prog)
      (absento 'f prog)
      (== `(lambda (l s)
             (if ,q
                 ,r
                 (cons (car l) (append (cdr l) s))))
          prog)
      (evalo
       `(letrec ((append ,prog))
          (list
           (append '() '())
           (append '(a) '(b))
           (append '(c d) '(e f))))
       '(()
         (a b)
         (c d e f))))))

(exit)
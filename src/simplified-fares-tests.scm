(test-runner 

20 ; timeout

(test-p "append-19"
   (run 1 (prog)
     (fresh (q r)
       (absento 'a prog)
       (absento 'b prog)
       (absento 'c prog)
       (absento 'd prog)
       (absento 'e prog)
       (absento 'f prog)
       (== `(lambda ,q
              ,r)
           prog)
       (evalo
        `(letrec ((append ,prog))
           (list
            (append '() '())
            (append '(a) '(b))
            (append '(c d) '(e f))))
        '(()
          (a b)
          (c d e f)))))
   (one-of?
    '((((lambda (_.0 _.1)
          (if (null? _.0)
              _.1
              (cons (car _.0) (append (cdr _.0) _.1))))
        (=/= ((_.0 _.1)) ((_.0 a)) ((_.0 append)) ((_.0 b)) ((_.0 c)) ((_.0 car)) ((_.0 cdr)) ((_.0 cons)) ((_.0 d)) ((_.0 e)) ((_.0 f)) ((_.0 if)) ((_.0 null?)) ((_.1 a)) ((_.1 append)) ((_.1 b)) ((_.1 c)) ((_.1 car)) ((_.1 cdr)) ((_.1 cons)) ((_.1 d)) ((_.1 e)) ((_.1 f)) ((_.1 if)) ((_.1 null?)))
        (sym _.0 _.1)))
      (((lambda (_.0 _.1) (if (null? _.0) _.1 (cons (car _.0) (append (cdr _.0) _.1)))) (=/= ((_.0 _.1)) ((_.0 a)) ((_.0 and)) ((_.0 append)) ((_.0 b)) ((_.0 c)) ((_.0 car)) ((_.0 cdr)) ((_.0 cons)) ((_.0 d)) ((_.0 e)) ((_.0 equal?)) ((_.0 f)) ((_.0 if)) ((_.0 lambda)) ((_.0 letrec)) ((_.0 list)) ((_.0 match)) ((_.0 not)) ((_.0 null?)) ((_.0 or)) ((_.0 quote)) ((_.0 symbol?)) ((_.1 a)) ((_.1 and)) ((_.1 append)) ((_.1 b)) ((_.1 c)) ((_.1 car)) ((_.1 cdr)) ((_.1 cons)) ((_.1 d)) ((_.1 e)) ((_.1 equal?)) ((_.1 f)) ((_.1 if)) ((_.1 lambda)) ((_.1 letrec)) ((_.1 list)) ((_.1 match)) ((_.1 not)) ((_.1 null?)) ((_.1 or)) ((_.1 quote)) ((_.1 symbol?))) (sym _.0 _.1)))))   
   )

)
(exit)
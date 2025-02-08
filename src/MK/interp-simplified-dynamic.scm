(load "src/MK/prelude.scm")

;; ngrams-statistics structure:
;;
;; (((context form) . count) ...)
(define ngrams-statistics (read-data-from-file "src/MK/statistics.scm"))

(define (entry-ctx entry)   (caar entry))
(define (entry-child entry) (cadar entry))
(define (entry-count entry) (cdr entry))


(define unique
  (lambda (l)
    (if (null? l)
      '()
      (cons (car l) (remove (car l) (unique (cdr l)))))))

(define all-contexts (unique (map entry-ctx ngrams-statistics)))

;; orderings-alist structure:
;;
;; ((context . (eval-relation ...)) ...)
(define orderings-alist
  (let ((ordering-for-context
          (lambda (ctx)
            (let* ((filtered (filter (lambda (entry) (equal? ctx (entry-ctx entry))) ngrams-statistics))
                   (ctx-stats (map (lambda (entry) (cons (entry-child entry) (entry-count entry)))
                                   filtered)))
              ;; expert-ordering-alist :: (list of (child . evalo-branch))

              ;; ctx-stats has the structure:
              ;;
              ;; ((form . count) ...)
              ;;
              ;; For example,
              ;;
              ;; ((app . 33) ...)
              (let ((compare
                      (lambda (a b)
                        (> (alist-ref ctx-stats (car a) 0)
                           (alist-ref ctx-stats (car b) 0)))))
                (map cdr (list-sort compare expert-ordering-alist)))))))
    (map (lambda (ctx)
           (cons ctx (ordering-for-context ctx)))
         all-contexts)))

(pretty-print orderings-alist)

; (exit)

;; context -> list of eval-relations
(define order-eval-relations
  (lambda (context)
    (cond
      ((assoc context orderings-alist) => cdr)
      (else
      (display "Falling back to expert ordering for context ")
      (newline)
      (display "Context: ")
      (display context)
      (newline)
        ;(error 'eval-expo (string-append "bad context " (symbol->string context)))

        ; symbol? doesn't appear in the data, so we'll return the expert ordering
        ; for such cases.
        expert-ordering))))

(define eval-expo-call-count 0)

(define (eval-expo expr env val context)
  ; for debugging build-and-run-code

  ;(conde
    ;((quote-evalo expr env val))
    ;((num-evalo expr env val))
    ;((bool-evalo expr env val))
    ;((var-evalo expr env val))
    ;((lambda-evalo expr env val))
    ;((app-evalo expr env val))
    ;((car-evalo expr env val))
    ;((cdr-evalo expr env val))
    ;((null?-evalo expr env val))
    ;((cons-evalo expr env val))
    ;((if-evalo expr env val))
    ;((equal?-evalo expr env val))
    ;((and-evalo expr env val))
    ;((or-evalo expr env val))
    ;((list-evalo expr env val))
    ;((symbol?-evalo expr env val))
    ;((not-evalo expr env val))
    ;((letrec-evalo expr env val))
    ;((match-evalo expr env val)))

  (build-and-run-conde expr env val
                       (order-eval-relations context)
                       ;expert-ordering
                       ))

(define old-eval-expo eval-expo)

(set! eval-expo
  (lambda (expr env val context)
    (set! eval-expo-call-count (+ eval-expo-call-count 1))
    (old-eval-expo expr env val context)))

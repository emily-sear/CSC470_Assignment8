;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Parser) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(define resolve
  (lambda (varName env)
    (cond
      ((null? env) #f)
      ((eq? varName (caar env)) (cadar env))
      (else (resolve varName (cdr env))))))

(define extend-env
  (lambda (lo-vars lo-vals env)
    (cond
      ((null? lo-vars) env)
      (else (extend-env (cdr lo-vars)
                        (cdr lo-vals)
                        (cons (list (car lo-vars) (car lo-vals)) env))))))

; ~~~~~~~~~~~~~~~~~~~~
; ~~~~~ TOASTERS ~~~~~
; ~~~~~~~~~~~~~~~~~~~~


(define do-arithmetic-boolean-stuff-toaster
  (lambda (op num1 num2)
    (cond
      ((eq? op '<) (if (< num1 num2) 'True 'False))
      ((eq? op '>) (if (> num1 num2) 'True 'False))
      ((eq? op '<=) (if (<= num1 num2) 'True 'False))
      ((eq? op '>=) (if (>= num1 num2) 'True 'False))
      ((eq? op '==) (if (= num1 num2) 'True 'False))
      ((eq? op '!=) (if (not (= num1 num2)) 'True 'False)))))

(define do-mathy-stuff-toaster
  (lambda (op num1 num2)
    (cond
      ((eq? op '+) (+ num1 num2))
      ((eq? op '-) (- num1 num2))
      ((eq? op '/) (/ num1 num2))
      ((eq? op '//) (quotient num1 num2))
      ((eq? op '%) (modulo num1 num2))
      ((eq? op '*) (* num1 num2))
      (else #f))))

; ~~~~~~~~~~~~~~~~~~~~
; ~~~~~ PARSERS ~~~~~~
; ~~~~~~~~~~~~~~~~~~~~

(define no-code-boolean-parser
  (lambda (no-code-boolean)
    (cond
      ((eq? (car no-code-boolean) '<)
       (list 'less-then (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      ((eq? (car no-code-boolean) '<=)
       (list 'less-then-or-equal (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      ((eq? (car no-code-boolean) '>)
       (list 'greater-then (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      ((eq? (car no-code-boolean) '>=)
       (list 'greater-then-or-equal (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      ((eq? (car no-code-boolean) '==)
       (list 'equal (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      ((eq? (car no-code-boolean) '!=)
       (list 'not-equal (no-parser (cadr no-code-boolean)) (no-parser (caddr no-code-boolean))))
      (else "Not a valid boolean expression"))))

(define no-code-function-parser
  (lambda (no-code-function)
    (list 'func-exp
             (append (list 'params) (cadr no-code-function))
             (list 'body
                   (no-parser (caddr no-code-function))))))

(define no-parser
  (lambda (no-code)
    (cond
      ((number? no-code) (list 'num-lit-exp no-code))
      ((symbol? no-code) (list 'var-exp no-code))
      ((eq? (car no-code) 'do-mathy-stuff)
       (list 'math-exp (cadr no-code) (no-parser (caddr no-code)) (no-parser (cadddr no-code))))
      ((eq? (car no-code) 'ask)
       (list 'ask-exp
             (no-code-boolean-parser (cadr no-code))
             (no-parser (caddr no-code))
             (no-parser (car (reverse no-code)))))
      ((eq? (car no-code) 'let)
       (list 'let-exp (cadr no-code) (no-parser (caddr no-code))))
      (else (list 'call-exp
                  (no-code-function-parser (cadr no-code))
                  (map no-parser (cddr no-code))))))) 

; ~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~ INTERPRETERS ~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~

(define run-parsed-boolean-code
  (lambda (parsed-no-code-boolean env)
    (cond
      ((eq? (car parsed-no-code-boolean) 'less-then)
       (< (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env)))
      ((eq? (car parsed-no-code-boolean) 'less-then-or-equal)
       (<= (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env)))
      ((eq? (car parsed-no-code-boolean) 'greater-then)
       (> (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env)))
      ((eq? (car parsed-no-code-boolean) 'greater-then-or-equal)
       (>= (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env)))
      ((eq? (car parsed-no-code-boolean) 'equal)
       (= (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env)))
      ((eq? (car parsed-no-code-boolean) 'not-equal)
       (not (= (run-parsed-code (cadr parsed-no-code-boolean) env)
          (run-parsed-code (caddr parsed-no-code-boolean) env))))
      (else ("Not a legal boolean expression")))))

(define run-parsed-function-code
  (lambda (parsed-no-code-function env)
    (run-parsed-code (cadr (caddr parsed-no-code-function)) env)))

(define run-parsed-code
  (lambda (parsed-no-code env)
    (cond
      ((eq? (car parsed-no-code) 'num-lit-exp)
       (cadr parsed-no-code))
      ((eq? (car parsed-no-code) 'var-exp)
       (resolve (cadr parsed-no-code) env))
      ((eq? (car parsed-no-code) 'math-exp)
       (do-mathy-stuff-toaster
        (cadr parsed-no-code)
        (run-parsed-code (caddr parsed-no-code) env)
        (run-parsed-code (cadddr parsed-no-code) env)))
      ((eq? (car parsed-no-code) 'ask-exp)
       (if (run-parsed-boolean-code (cadr parsed-no-code) env)
           (run-parsed-code (caddr parsed-no-code) env)
           (run-parsed-code (cadddr parsed-no-code) env)))
      ((eq? (car parsed-no-code) 'let-exp)
       (run-parsed-code (caddr parsed-no-code) (append (cadr parsed-no-code) env)))
      (else
         (run-parsed-function-code
        (cadr parsed-no-code)
        (extend-env
         (cdr (cadr (cadr parsed-no-code)))
         (map (lambda (packet) (run-parsed-code (car packet) (cadr packet))) (map (lambda (x) (list x env)) (caddr parsed-no-code)))
         env))))))

(define env '((age 21) (a 7) (b 5) (c 23)))
(define sample-no-code '(ask (< 5 10) (let ((b 2) (c 3)) (do-mathy-stuff + b c)) otherwise c))
(define parsed-no-code (no-parser sample-no-code))
;(display parsed-no-code)
(run-parsed-code parsed-no-code env)
;(display env)


(define let-sample
  (lambda (d)
    (let ((a 1) (b 2) (c 3)) ; as soon as this let is done, these variables disappear --> gives you a more local environment
      (+ d (* b c)))))
;(let-sample 2)

(define letSample2
  (lambda (a)
    (let* ((a 1) (b 2) (c (lambda (x) (* x 2))))
      (c b))))
;(letSample2 2)
#lang at-exp racket/base

(require
 (for-syntax racket/base)
 cpsc411/compiler-lib
 cpsc411/info-lib
 scribble/bettergrammar
 racket/contract
 static-rename
 (for-label cpsc411/info-lib)
 (for-label racket/contract)
 (for-label cpsc411/compiler-lib)
 "redex-gen.rkt"
 "v4.rkt"
 (submod "base.rkt" interp))

(provide
 (all-defined-out))

@define-grammar/pred[values-lang-v5
  #:literals (name? int64?)
  #:datum-literals (define lambda module let call true false not if * + < <= =
   >= > !=)
  [p     (module (define x (lambda (x ...) tail)) ... tail)]
  [pred  (relop triv triv)
         (true)
         (false)
         (not pred)
         (let ([x value] ...) pred)
         (if pred pred pred)]
  [tail  value
         (let ([x value] ...) tail)
         (if pred tail tail)
         (call x triv ...)]
  [value triv
         (binop triv triv)
         (let ([x value] ...) value)
         (if pred value value)]
  [triv  x int64]
  [x     name?]
  [binop * +]
  [relop < <= = >= > !=]
  [int64 int64?]
]

(define (interp-values-lang-v5 x)
  (interp-base x))

@define-grammar/pred[values-unique-lang-v5
  #:literals (name? int64? label? aloc?)
  #:datum-literals (define lambda module let call true false not if * + < <= =
   >= > !=)
  [p     (module (define label (lambda (aloc ...) tail)) ... tail)]
  [pred  (relop opand opand)
         (true)
         (false)
         (not pred)
         (let ([aloc value] ...) pred)
         (if pred pred pred)]
  [tail  value
         (let ([aloc value] ...) tail)
         (if pred tail tail)
         (call triv opand ...)]
  [value triv
         (binop opand opand)
         (let ([aloc value] ...) value)
         (if pred value value)]
  [opand aloc int64]
  [triv  opand label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc aloc?]
  [label label?]
  [int64 int64?]
]

(define (interp-values-unique-lang-v5 x)
  (interp-base x))

@define-grammar/pred[imp-mf-lang-v5
  #:literals (int64? label? aloc? register? fvar? info?)
  #:datum-literals (define lambda module begin jump set! true false not if
   * + < <= = >= > != call)
  [p      (module (define label (lambda (aloc ...) tail)) ...
                  tail)]
  [pred   (relop opand opand)
          (true)
          (false)
          (not pred)
          (begin effect ... pred)
          (if pred pred pred)]
  [tail   value
          (call triv opand ...)
          (begin effect ... tail)
          (if pred tail tail)]
  [value  triv
          (binop opand opand)
          (begin effect ... value)
          (if pred value value)]
  [effect (set! aloc value)
          (begin effect ...)
          (if pred effect effect)]
  [opand aloc int64]
  [triv  opand label]
  [binop  * +]
  [relop  < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [int64  int64?]
]

(define (interp-imp-mf-lang-v5 x)
  (interp-base x))

@define-grammar/pred[proc-imp-cmf-lang-v5
  #:literals (int64? label? aloc? info?)
  #:datum-literals (define lambda module begin set! call true false not if
                    * + < <= = >= > !=)
  [p      (module (define label (lambda (aloc ...) tail)) ...
                  tail)]
  [pred   (relop opand opand)
          (true)
          (false)
          (not pred)
          (begin effect ... pred)
          (if pred pred pred)]
  [tail   value
          (call triv opand ...)
          (begin effect ... tail)
          (if pred tail tail)]
  [value  triv
          (binop opand opand)]
  [effect (set! aloc value)
          (begin effect ...)
          (if pred effect effect)]
  [opand aloc int64]
  [triv  opand label]
  [binop  * +]
  [relop  < <= = >= > !=]
  [aloc  aloc?]
  [label  label?]
  [int64 int64?]
]

(define (interp-proc-imp-cmf-lang-v5 x)
  (interp-base x))

@define-grammar/pred[imp-cmf-lang-v5
  #:literals (int64? label? aloc? register? fvar? info?)
  #:datum-literals (define lambda module begin jump set! true false not if
   * + < <= = >= > !=)
  [p      (module (define label tail) ... tail)]
  [pred   (relop opand opand)
          (true)
          (false)
          (not pred)
          (begin effect ... pred)
          (if pred pred pred)]
  [tail   value
          (jump trg loc ...)
          (begin effect ... tail)
          (if pred tail tail)]
  [value  triv
          (binop opand opand)]
  [effect (set! loc value)
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop  * +]
  [relop  < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-imp-cmf-lang-v5 x)
  (interp-base x))

@define-grammar/pred[asm-pred-lang-v5
  #:literals (int64? label? aloc? register? fvar? info?)
  #:datum-literals (define module begin set! jump true false not if * + < <= =
   >= > != halt)
  [p    (module info (define label info tail) ... tail)]
  [info info?]
  [pred (relop loc opand)
        (true)
        (false)
        (not pred)
        (begin effect ... pred)
        (if pred pred pred)]
  [tail (halt opand)
        (jump trg loc ...)
        (begin effect ... tail)
        (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-asm-pred-lang-v5 x)
  (interp-base x))

@define-grammar/pred[asm-pred-lang-v5/locals
  #:literals (int64? label? aloc? register? fvar? info? info/c)
  #:datum-literals (locals define module begin set! jump true false not if * + <
   <= = >= > != halt)
  [p    (module info (define label info tail) ... tail)]
  [info #:with-contract
        (info/c
         (locals (aloc ...)))
        (info/c
         (locals (aloc? ...)))]
  [pred (relop loc opand)
        (true)
        (false)
        (not pred)
        (begin effect ... pred)
        (if pred pred pred)]
  [tail (halt opand)
        (jump trg loc ...)
        (begin effect ... tail)
        (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-asm-pred-lang-v5/locals x)
  (interp-base x))

@define-grammar/pred[asm-pred-lang-v5/undead
  #:literals (int64? label? aloc? register? fvar? info? undead-set-tree/rloc? info/c)
  #:datum-literals (locals undead-out define module begin set! true false not if
   * + < <= = >= > != jump halt)
  [p    (module info (define label info tail) ... tail)]
  [info #:with-contract
        (info/c
         (locals (aloc ...))
         (undead-out undead-set-tree/rloc?))
        (info/c
         (locals (aloc? ...))
         (undead-out undead-set-tree/rloc?))]
  [pred (relop loc opand)
        (true)
        (false)
        (not pred)
        (begin effect ... pred)
        (if pred pred pred)]
  [tail (halt opand)
        (jump trg loc ...)
        (begin effect ... tail)
        (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-asm-pred-lang-v5/undead x)
  (interp-base x))

@define-grammar/pred[asm-pred-lang-v5/conflicts
  #:literals (int64? label? aloc? register? fvar? info? info/c)
  #:datum-literals (locals conflicts define module begin set! true false not if
   * + < <= = >= > != jump halt)
  [p    (module info (define label info tail) ... tail)]
  [info #:with-contract
        (info/c
         (locals (aloc ...))
         (conflicts ((loc (loc ...)) ...)))
        (let ([loc? (or/c aloc? register? fvar?)])
          (info/c
           (locals (aloc? ...))
           (conflicts ((loc? (loc? ...)) ...))))]
  [pred (relop loc opand)
        (true)
        (false)
        (not pred)
        (begin effect ... pred)
        (if pred pred pred)]
  [tail (halt opand)
        (jump trg loc ...)
        (begin effect ... tail)
        (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-asm-pred-lang-v5/conflicts x)
  (interp-base x))

@define-grammar/pred[asm-pred-lang-v5/assignments
  #:literals (int64? label? aloc? register? fvar? info?)
  #:datum-literals (locals assignment define module begin set! true false not if
   * + < <= = >= > != jump halt)
  [p    (module info (define label info tail) ... tail)]
  [info #:with-contract
        (info/c
         (locals (aloc ...))
         (assignment ((aloc rloc) ...)))
        (let ([rloc? (or/c register? fvar?)])
          (info/c
           (locals (aloc? ...))
           (assignment ((aloc? rloc?) ...))))]
  [pred (relop loc opand)
        (true)
        (false)
        (not pred)
        (begin effect ... pred)
        (if pred pred pred)]
  [tail (halt opand)
        (jump trg loc ...)
        (begin effect ... tail)
        (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [opand loc int64]
  [triv  opand label]
  [loc    rloc aloc]
  [trg    loc label]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc   aloc?]
  [label  label?]
  [rloc   register? fvar?]
  [int64  int64?]
]

(define (interp-asm-pred-lang-v5/assignments x)
  (interp-base x))

@define-grammar/pred[nested-asm-lang-v5
  #:literals (int64? register? label? aloc? info? fvar?)
  #:datum-literals (define module begin set! true false not if * + < <= = >= >
   != jump rsp rbp rax rbx rcx rdx rsi rdi r8 r9 r12 r13 r14 r15 halt)
  [p     (module (define label tail) ... tail)]
  [pred  (relop loc opand)
         (true)
         (false)
         (not pred)
         (begin effect ... pred)
         (if pred pred pred)]
  [tail  (halt opand)
         (jump trg)
         (begin effect ... tail)
         (if pred tail tail)]
  [effect (set! loc triv)
          (set! loc_1 (binop loc_1 opand))
          (begin effect ...)
          (if pred effect effect)]
  [triv  opand label]
  [opand loc int64]
  [loc   reg fvar]
  [trg   loc label]
  [reg   rsp rbp rax rbx rcx rdx rsi rdi r8 r9 r12 r13 r14 r15]
  [binop * +]
  [relop < <= = >= > !=]
  [fvar fvar?]
  [label label?]
  [int64 int64?]
]

(define (interp-nested-asm-lang-v5 x)
  (interp-base x))

@define-grammar/pred[block-pred-lang-v5
  #:literals (int64? register? label? aloc? info? fvar?)
  #:datum-literals (define module begin set! true false not if * + < <= = >= >
   != jump rsp rbp rax rbx rcx rdx rsi rdi r8 r9 r12 r13 r14 r15)
  [p     (module b ... b)]
  [b     (define label tail)]
  [pred  (relop loc opand)
         (true)
         (false)
         (not pred)]
  [tail  (halt opand)
         (jump trg)
         (begin effect ... tail)
         (if pred (jump trg) (jump trg))]
  [effect     (set! loc triv)
         (set! loc_1 (binop loc_1 opand))]
  [triv  opand label]
  [opand loc int64]
  [trg   loc label]
  [loc   reg fvar]
  [reg   rsp rbp rax rbx rcx rdx rsi rdi r8 r9 r12 r13 r14 r15]
  [binop * +]
  [relop < <= = >= > !=]
  [aloc aloc?]
  [fvar fvar?]
  [label label?]
  [int64 int64?]
]

(define (interp-block-pred-lang-v5 x)
  (interp-base x))

(define-syntax block-asm-lang-v5 (syntax-local-value #'block-asm-lang-v4))

(define-syntax para-asm-lang-v5 (syntax-local-value #'para-asm-lang-v4))

(define-syntax paren-x64-fvars-v5 (syntax-local-value #'paren-x64-fvars-v4))

(define-syntax paren-x64-v5 (syntax-local-value #'paren-x64-v4))

(define-values (interp-block-asm-lang-v5 block-asm-lang-v5?
                interp-para-asm-lang-v5 para-asm-lang-v5?
                interp-paren-x64-fvars-v5 paren-x64-fvars-v5?
                interp-paren-x64-v5 paren-x64-v5?)
  (values
   (static-rename interp-block-asm-lang-v5 interp-block-asm-lang-v4)
   (static-rename block-asm-lang-v5? block-asm-lang-v4?)

   (static-rename interp-para-asm-lang-v5 interp-para-asm-lang-v4)
   (static-rename para-asm-lang-v5? para-asm-lang-v4?)

   (static-rename interp-paren-x64-fvars-v5 interp-paren-x64-fvars-v4)
   (static-rename paren-x64-fvars-v5? paren-x64-fvars-v4?)

   (static-rename interp-paren-x64-v5 interp-paren-x64-v4)
   (static-rename paren-x64-v5? paren-x64-v4?)))

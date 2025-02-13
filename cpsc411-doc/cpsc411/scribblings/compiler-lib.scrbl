#lang scribble/manual

@(require
  scribble/example
  cpsc411/compiler-lib
  (for-label
    racket/list
    cpsc411/compiler-lib
    racket/contract
    racket/set
    (except-in racket/base compile)))

@(define eg (make-base-eval '(require cpsc411/compiler-lib)))

@title{Compiler Support}

@author[@author+email["William J. Bowman" "wjb@williamjbowman.com"]]
@defmodule[cpsc411/compiler-lib]

This library provides support functions and parameters for implementing the
CPSC411 project compiler.

@section{Data Types}

These data types are used in the implementation of the CPSC411 compiler for
representing intermediate language constructs.

@defproc[(dispoffset? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is a valid displacement
mode offset for x86-64.

@examples[#:eval eg
(dispoffset? 0)
(dispoffset? 1)
(dispoffset? 2)
(dispoffset? 3)
(dispoffset? 4)
(dispoffset? 8)
(dispoffset? 8)
(dispoffset? 15)
(dispoffset? 16)
(dispoffset? 17)
(dispoffset? 'x)
]
}

@defproc[(register? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is a valid register on the
target machine, and @racket[#f] otherwise.

@examples[#:eval eg
(register? 'rax)
(register? 'r10)
(register? 'r18)
]
}

@subsection{Labels}

@defproc[(label? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is a valid label in
in the CPSC411 languages.

@examples[#:eval eg
(label? 'L.start.1)
(label? 'Lstart.1)
(label? 'L.start1)
(label? 'start.1)
(label? "L.start.1")
]
}

@defproc[(fresh-label [x (or/c string? symbol?) 'tmp]) label?]{
Returns a fresh label, distinct from any label that has previously been
generated.
Assumes all other labels in the program have been generated using this
procedure, to ensure freshness.
Optionally, takes a base label to generate from.

@examples[#:eval eg
(fresh-label)
(fresh-label)
(fresh-label)
(fresh-label 'meow)
(fresh-label "hello")
]
}

@defproc[(sanitize-label [l label?]) string?]{
Transform @racket[l] into a string that is valid as a @tt{nasm} label, escaping
any special characters.

@examples[
#:eval eg
(sanitize-label 'L.main.1)
(sanitize-label 'L.$!!@#*main.2)
]
}

@subsection{Identifiers}

@defproc[(name? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is a valid lexical
identifier in the CPSC411 languages.

@examples[#:eval eg
(name? 'L.start.1)
(name? 'Lstart.1)
(name? 'L.start1)
(name? 'start.1)
(name? 'start)
(name? 'x)
(name? "L.start.1")
(name? "x")
(name? 5)
]
}

@defproc[(aloc? [v any/c]) boolean?]{
A predicate that return @racket[#t] when @racket[v] is a valid abstract location
in the CPSC411 languages.

@examples[#:eval eg
(aloc? 0)
(aloc? 'x)
(aloc? 'x.1)
(aloc? 'L.start.1)
(aloc? 'Lstart.1)
(aloc? 'L.start1)
(aloc? 'start.1)
(aloc? 'start)
(aloc? 'x)
(aloc? "L.start.1")
(aloc? "x")
(aloc? 5)
]
}

@defproc*[([(fresh) aloc?]
           [(fresh [v symbol?]) aloc?])]{
Returns a fresh @racket[aloc?], unique from every other @racket[aloc?] that has
been generated by @racket[fresh].
It is not guaranteed to be unique when used in an arbitrary program, unless all
@racket[aloc?]s in the program were generated using @racket[fresh].

Optionally takes a symbol @racket[v] to represent the name part of the @racket[aloc?].

@examples[#:eval eg
(fresh)
(fresh)
(fresh)
(fresh 'L.start.1)
(fresh 'L.start.1)
]
}

@subsection{Frame Variables}
@defproc[(fvar? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is a valid frame variable.

@examples[#:eval eg
(fvar? 0)
(fvar? 'x)
(fvar? 'x.1)
(fvar? 'fv)
(fvar? 'fv.1)
(fvar? 'fv1)
(fvar? 'fv2)
]
}

@defproc[(make-fvar [i exact-nonnegative-integer?]) fvar?]{
Returns an @racket[fvar?] with index @racket[i].

@examples[#:eval eg
(make-fvar 1)
(make-fvar 2)
(make-fvar 0)
]
}

@defproc[(fvar->index [v fvar?]) exact-nonnegative-integer?]{
Returns the index component of an @racket[fvar?].

@examples[#:eval eg
(fvar->index (make-fvar 1))
(fvar->index 'fv1)
]
}

@subsection{Undead Sets}

@defproc[(undead-set? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is an undead set,
and @racket[#f] otherwise.

@examples[#:eval eg
(undead-set? '(a.1 b.2 c.3))
(undead-set? '(a.1 b.2 a.1))
(undead-set? '(5 3))
]
}

@defproc[(undead-set-tree? [ust any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[ust] is an undead set tree,
and @racket[#f] otherwise.

@examples[#:eval eg
(undead-set-tree? '(a.1 b.2 c.3))
(undead-set-tree? '((a.1 b.2 c.3)))
(undead-set-tree? '((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3)))
(undead-set-tree? '((a.1 b.2 c.3) ((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3))))
(undead-set-tree? '((5 b.2 c.3) ((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3))))
]
}

@defproc[(undead-set-tree/rloc? [ust any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[ust] is an undead set tree
that might contain physical locations or abstract locations,and @racket[#f] otherwise.

@examples[#:eval eg
(undead-set-tree/rloc? '(a.1 b.2 c.3))
(undead-set-tree/rloc? '((a.1 b.2 c.3)))
(undead-set-tree/rloc? '((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3)))
(undead-set-tree/rloc? '((a.1 b.2 c.3) ((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3))))
(undead-set-tree/rloc? '((5 b.2 c.3) ((a.1 b.2 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3))))
(undead-set-tree/rloc? '((rax rbx r8 c.3) ((a.1 r9 c.3) (a.1 b.2 c.3) (a.1 b.2 c.3))))
]
}

@section{Compilation Harness}
This section describes abstractions for executing the compiler and compiled code in Racket.

@defproc[(bin-format [type (or/c 'unix 'windows 'macosx) (system-type)]) (or/c
"elf64" "macho64" "win64")]{
Returns the binary format used by @tt{nasm} to generate executable on the operating system
specified by @racket[type].
Defaults to the current system.
Assumes an x86-64 target machine.

@examples[#:eval eg
(bin-format)
(bin-format 'macosx)
(bin-format 'unix)
]
}

@defproc[(ld-flags [type (or/c 'unix 'windows 'macos)]) string?]{
Returns additional linker flags for @tt{ld} to generate a linked execute on the
operating system specified by @racket[type].
Defaults to the current system.

@examples[#:eval eg
(ld-flags)
(ld-flags 'macosx)
(ld-flags 'unix)
]
}

@defthing[start-label string? #:value (unsyntax start-label)]{
Defines the initial label used by the run-time system linker.
}


@defproc[(sys-write [type (or/c 'unix 'macosx 'windows)]) int64?]{
Returns the write system call number for the specified operating system.
Defaults to the current system.
Doesn't work for Windows since Windows doesn't support system calls.
}


@defproc[(sys-exit [type (or/c 'unix 'macosx 'windows)]) int64?]{
Returns the exit system call number for the specified operating system.
Defaults to the current system.
Doesn't work for Windows since Windows doesn't support system calls.
}

@defproc[(sys-mmap [type (or/c 'unix 'macosx 'windows)]) int64?]{
Returns the mapped memory system call number for the specified operating system.
Defaults to the current system.
Doesn't work for Windows since Windows doesn't support system calls.
}

@defparam[current-pass-list passes (list-of (-> any/c any/c))
          #:value exn:fail]{
A @racket[parameter?] that defines the list of compiler passes to use when
running @racket[compile] or @racket[execute].
The list of procedures is composed in order, so the output of the @tt{n-th}
procedure should match the input expected by the @tt{n+1 th}.

Raises an error when accessed before being initialized with a valid pass list.

@examples[#:eval eg
(current-pass-list)
(parameterize ([current-pass-list
                (list (lambda (x) (displayln x)))])
  (compile 'x))
(current-pass-list (list (lambda (x) (displayln x))))
(compile 'x)
]
}

@defproc[(compile (e any/c)) any/c]{
Compiles @racket[e] using the @racket[current-pass-list], and returns the
resulting program.
Expects @racket[e] to be a valid input program to the first pass in the @racket[current-pass-list].
}

@defparam[current-run/read run/read (-> string? any/c)
          #:value nasm-run/read]{
Defines a default @tech{run-reader} to be used with @racket[execute] when none
is specified directly.

A @deftech{run-reader}, @racket[run/read], takes a string representing a
complete x64 program in
Intel syntax, capable of compiling via @tt{nasm}, linking via @tt{ld}, and
running as a binary, and should return the result of the program as a Racket
value.
The default, @racket[nasm-run/read], compiles and executes the program and
returns the result of the standard output as read by @racket[read].

See also @racket[nasm-run/exit-code], @racket[nasm-run/print-string],
@racket[nasm-run/print-number], @racket[nasm-run/error-string],
@racket[nasm-run/error-string+code], and @racket[nasm-run/observe].
}

@defthing[cpsc411-execute-logger logger?]{
A logger to which error and debug information is written if a low-level error happens during @racket[execute], such as a failure to assemble and link.
You might view this debug information by adding @tt{PLTSTDERR="debug@cpsc411-execute"} to your environment when executing the test suite, as in @tt{env PLTSTDERR="debug@cpsc411-execute" raco test compiler.rkt}.
}

@defproc[(execute (v any/c) [run/read (-> string? any/c) (current-run/read)]) any/c]{
Compiles @racket[v] using the @racket[current-pass-list] and then runs the
program using the @racket[run/read] argument, and returns the result.

The intention is that the program is compiled to assembly, then assembled with
@tt{nasm}, then linked, then the binary is executed and the result returned as a
Racket value, enabling testing the end-to-end compiler.

Expects @racket[e] to be a valid input program to the first pass in the
@racket[current-pass-list], and the compiler to produce a valid input to the
@racket[run/read] procedure.

@; NOTE: The following only works with the reference, so typeset it manually.
@examples[
(eval:alts (require cpsc411/reference/a2-solution cpsc411/2c-run-time) (void))
(eval:alts (parameterize ([current-pass-list
                (list generate-x64
                      wrap-x64-run-time
                      wrap-x64-boilerplate)])
  (execute '(begin (set! rax 120)))) 120)
(eval:alts (parameterize ([current-pass-list
                (list implement-fvars
                      generate-x64
                      wrap-x64-run-time
                      wrap-x64-boilerplate)])
  (execute '(begin (set! fv1 120) (set! rax fv1)))) 120)
(eval:alts (require cpsc411/reference/a1-solution) (void))
(eval:alts (parameterize ([current-pass-list
                (list generate-x64
                      wrap-x64-run-time
                      wrap-x64-boilerplate)])
  (execute '(begin (set! rax 120)) nasm-run/exit-code)) 120)
]
}

@defproc[(nasm-run/observe (runner path? any/c)) (-> string? any/c)]{
Returns a @tech{run-reader} that compiles and links its input to an
executable using @tt{nasm}, and passes the executable path to @racket[runner] to
be executed.

The @racket[runner] is expected to run the executable, and return an observation.

This procedure performs additional error checking and cleans up temporary files
before returning the observation.
}

@defproc[(nasm-run/exit-code [s string?]) (in-range/c 0 256)]{
A @tech{run-reader} that returns the process's exit code.
}

@defproc[(nasm-run/print-string [s string?]) string?]{
A @tech{run-reader} that returns the contents of the standard output port of the
process, as a string.
}

@defproc[(nasm-run/print-number [s string?]) number?]{
A @tech{run-reader} that parses the standard output of the process as a Racket number.
}

@defproc[(nasm-run/read [s string?]) any/c]{
A @tech{run-reader} that parses the standard output of the process using
@racket[read], returning some valid Racket value.
}

@defproc[(nasm-run/error-string [s string?]) string?]{
A @tech{run-reader} that returns the contents of the standard error port of the
process, as a string.
}

@defproc[(nasm-run/error-string+code [s string?]) (cons/c (in-range/c 0 256) string?)]{
A @tech{run-reader} that returns a pair of the exit code and the contents of the standard error port of the
process as a string.
}

@defproc[(trace-compiler!) void?]{
Instruments the @racket[current-pass-list] to trace the entire compiler using @racket[racket/trace].
}

@defproc[(untrace-compiler!) void?]{
Un-instruments the @racket[current-pass-list]. Must only be called after calling @racket[trace-compiler!].
}

@defform[(with-trace e)]{
Executes the expression @racket[e] in a context where the
@racket[current-pass-list] is locally traced, leaving @racket[current-pass-list]
in its original state after execution.
}

@section{Compiler Parameters}
This section describes parameters defining various values used in the CPSC411
compiler, such as those defining design choices or target machine details.

@defparam[current-word-size-bytes size exact-nonnegative-integer?
          #:value (unsyntax (current-word-size-bytes))]{
The number of bytes in a single machine word on the machine targeted by the
compiler.
}

@defparam[current-register-set set (set/c symbol?)
          #:value (unsyntax @racket['(unsyntax (current-register-set))])]{
The set of registers provided by the machine targeted by the compiler.
}

@defparam[current-stack-size size exact-nonnegative-integer?
          #:value (* 8 1024 1024)]{
Deprecated; has no effect. The stack size is now defined by the operating system
using the SYS V ABI.
}

@defparam[current-heap-size size exact-nonnegative-integer?
          #:value (* 128 1024 1024)]{
Defines the maximum size of the heap, in bytes, created by the run-time system.
Defaults to 128MB.
}

@defparam[current-frame-base-pointer-register reg register?
          #:value '(unsyntax (current-frame-base-pointer-register))]{
Defines the register in which the run-time system stores the base of the frame;
everything above this address is free space.
}

@defproc[(frame-base-pointer-register? [v any/c]) boolean?]{
A predicate that returns @racket[#t] when @racket[v] is equal to the
@racket[current-frame-base-pointer-register], and @racket[#f] otherwise.
}

@defparam[current-auxiliary-registers reg register?
          #:value (unsyntax @racket['(unsyntax (current-auxiliary-registers))])]{
Defines the set of registers used as auxiliary registers when compiling
instructions to match x86-64 restrictions on which instructons use which kinds
of physical locations.
}

@defparam[current-patch-instructions-registers reg register?
          #:value (unsyntax @racket['(unsyntax (current-auxiliary-registers))])]{
An alias for @racket[current-auxiliary-registers].
}

@defparam[current-return-value-register reg register?
          #:value '(unsyntax (current-return-value-register))]{
Defines the register that the run-time system and calling convention expects to
contain the return value.
}

@defparam[current-assignable-registers reg register?
         #:value (unsyntax @racket['(unsyntax (current-assignable-registers))])]{
Defines the set of registers that can be assigned by register allocations.
This set is derived from the @racket[current-register-set] and the other
parameters that reserve registers.
}

@defparam[current-parameter-registers reg (set/c register?)
          #:value (unsyntax @racket['(unsyntax (current-parameter-registers))])]{
Define the set of registers using for passing the first @racket[n] arguments in
a procedure call, where @racket[n] is the size of the set defined by this
parameter.
The remaining arguments are passed on the stack.
}

@defparam[current-return-address-register reg register?
          #:value '(unsyntax (current-return-address-register))]{
Define the register that the run-time system and calling convention expect to
contain the return address.
}

@defparam[current-heap-base-pointer-register reg register?
          #:value '(unsyntax (current-heap-base-pointer-register))]{
Define the register that the run-time system initializes to the base address of
the heap; everything above this address is free space.
}

@section{Two's Complement Integers}
This section defines utilities for working with fixed-width two's complement
integers.

@defproc[(max-int [v exact-nonnegative-integer?]) number?]{
Returns the maximum two's complement signed integer representable in @racket[v] bits.

@examples[#:eval eg
(max-int 2)
(max-int 32)
(max-int 64)
]
}

@defproc[(min-int [v exact-nonnegative-integer?]) number?]{
Returns the minimum two's complement signed integer representable in @racket[v] bits.

@examples[#:eval eg
(min-int 2)
(min-int 32)
(min-int 64)
]
}

@defproc[(int-size? [word-size exact-nonnegative-integer?] [i number?]) boolean?]{
A predicate that decides whether @racket[i] is in the range for a two's complement signed
@racket[word-size]-bit integer.

@examples[#:eval eg
(int-size? 2 1)
(int-size? 2 5)
(int-size? 2 (max-int 2))
(int-size? 2 (min-int 2))
(int-size? 2 (- (min-int 2) 1))
(int-size? 2 (+ (min-int 2) 1))

(int-size? 32 (max-int 32))
(int-size? 32 (min-int 32))
(int-size? 32 (- (min-int 32) 1))
(int-size? 32 (+ (min-int 32) 1))
]
}

@defproc[(uint8? [i any/c]) boolean?]{
Returns @racket[#t] when @racket[i] is in the range for an two's complement
unsigned @racket[8]-bit integer.

@examples[#:eval eg
(uint8? 0)
(uint8? 5)
(uint8? 255)
(uint8? 'x)
]
}

@defproc[(int32? [i any/c]) boolean?]{
A predicate that decides whether @racket[i] is in the range for a two's complement signed
@racket[32]-bit integer; shorthand for @racket[(int-size 32 i)].

@examples[#:eval eg
(int32? 0)
(int32? 5)
(int32? (max-int 32))
(int32? (min-int 32))
(int32? (- (min-int 32) 1))
(int32? (+ (min-int 32) 1))
(int32? 'x)
(int32? 'x.1)
]
}

@defproc[(int64? [i any/c]) boolean?]{
A predicate that decides whether @racket[i] is in the range for a two's complement signed
@racket[64]-bit integer; shorthand for @racket[(int-size 64 i)].

@examples[#:eval eg
(int64? 0)
(int64? 5)
(int64? (max-int 64))
(int64? (min-int 64))
(int64? (- (min-int 64) 1))
(int64? (+ (min-int 64) 1))
(int64? 'x)
(int64? 'x.1)
]
}

@defproc[(int61? [i any/c]) boolean?]{
A predicate that decides whether @racket[i] is in the range for a two's complement signed
@racket[61]-bit integer; shorthand for @racket[(int-size 61 i)].

@examples[#:eval eg
(int61? 0)
(int61? 5)
(int61? (max-int 61))
(int61? (min-int 61))
(int61? (- (min-int 61) 1))
(int61? (+ (min-int 61) 1))
(int61? 'x)
(int61? 'x.1)
]
}

@defproc[(handle-overflow [word-size exact-nonnegative-integer?] [x number?]) number?]{
Transform the number @racket[x] into its representation as a
@racket[word-size]-bit two's complement signed integer.
When @racket[x] is greater than the range, this overflows @racket[x] until it is
range.
By contrast, if @racket[x] is less than the range, this underflows @racket[x]
until it is range.
Has no affect if @racket[x] is in range.

@examples[#:eval eg
(handle-overflow 32 (sub1 (min-int 32)))
(handle-overflow 32 (min-int 32))
(handle-overflow 32 (max-int 32))
(handle-overflow 32 (add1 (max-int 32)))
]
}

@defproc[(twos-complement-add [word-size exact-nonnegative-integer?]
                              [n1 number?]
                              [n2 number?])
         (in-range/c (min-int word-size) (max-int word-size))]{
Returns the result of adding @racket[n1] and @racket[n2] as
@racket[word-size]-bit two's complement integers.

@examples[#:eval eg
(twos-complement-add 32 5 10)
(twos-complement-add 32 (sub1 (max-int 32)) 1)
(twos-complement-add 32 (max-int 32) 1)
(twos-complement-add 32 (add1 (min-int 32)) -1)
(twos-complement-add 32 (min-int 32) -1)
]
}

@defproc[(twos-complement-sub [word-size exact-nonnegative-integer?]
                              [n1 number?]
                              [n2 number?])
         (in-range/c (min-int word-size) (max-int word-size))]{
Returns the result of subtracting @racket[n1] by @racket[n2] as
@racket[word-size]-bit two's complement integers.

@examples[#:eval eg
(twos-complement-sub 32 5 2)
(twos-complement-sub 32 (max-int 32) 1)
(twos-complement-sub 32 (min-int 32) 1)
]
}

@defproc[(twos-complement-mul [word-size exact-nonnegative-integer?]
                              [n1 number?]
                              [n2 number?])
         (in-range/c (min-int word-size) (max-int word-size))]{
Returns the result of multiplying @racket[n1] and @racket[n2] as
@racket[word-size]-bit two's complement integers.

@examples[#:eval eg
(twos-complement-mul 32 2 5)
(twos-complement-mul 32 (/ (max-int 32) 2) 2)
(twos-complement-mul 32 (max-int 32) 2)
]
}

@defproc[(x64-add [n1 number?] [n2 number?]) int64?]{
Returns the 64-bit two's complement addition of @racket[n1] and @racket[n2].

@examples[#:eval eg
(x64-add 2 5)
(x64-add (max-int 64) 1)
]
}

@defproc[(x64-sub [n1 number?] [n2 number?]) int64?]{
Returns the 64-bit two's complement subtraction of @racket[n1] by @racket[n2].

@examples[#:eval eg
(x64-sub 5 2)
(x64-sub (min-int 64) 1)
]
}

@defproc[(x64-mul [n1 number?] [n2 number?]) int64?]{
Returns the 64-bit two's complement multiplication of @racket[n1] and @racket[n2].

@examples[#:eval eg
(x64-mul 5 2)
(x64-mul (min-int 64) 2)
]
}

@section{Ptrs}
This section describes the parameters and procedures for working with ptrs.

@defparam[current-fixnum-shift bits exact-nonnegative-integer?
          #:value 3]{
The bitwise shift length for the ptr encoding of fixnums.
}

@defparam[current-fixnum-mask bits int64?
          #:value (unsyntax @code{#b111})]{
The tag mask for the ptr encoding for fixnums.
}

@defparam[current-fixnum-tag bits int64?
          #:value (unsyntax @code{#b000})]{
The tag bits for the ptr encoding for fixnums.
}

@defparam[current-boolean-shift bits exact-nonnegative-integer?
          #:value (current-boolean-shift)]{
The bitwise shfit length for the ptr encoding of booleans.
}

@defparam[current-boolean-mask bits int64?
          #:value (unsyntax @code{#b11110111})]{
The tag mask for the ptr encoding of booleans.
}

@defparam[current-boolean-tag bits int64?
          #:value (unsyntax @code{#b110})]{
The tag bits for the ptr encoding of booleans.
}

@defparam[current-true-ptr bits int64?
          #:value (unsyntax @code{#b1110})]{
The ptr encoding of the true value.
}

@defparam[current-false-ptr bits int64?
         #:value (unsyntax @code{#b0110})]{
The ptr encoding of the false value.
Note that this should always be identical to the @racket[current-boolean-tag].
}

@defparam[current-empty-mask bits int64?
          #:value (unsyntax @code{#b11111111})]{
The tag mask for the ptr encoding of the empty list.
}

@defparam[current-empty-tag bits int64?
         #:value (unsyntax @code[(format "#b~b" (current-empty-tag))])]{
The tag for the ptr encoding of the empty list.
}

@defparam[current-empty-ptr bits int64?
          #:value (unsyntax @code[(format "#b~b" (current-empty-ptr))])]{
The ptr encoding of the empty list.
Note that this should always be identical to the @racket[current-empty-tag].
}

@defparam[current-void-mask bits int64?
          #:value (unsyntax @code{#b11111111})]{
The tag mask for the ptr encoding of the void value.
}

@defparam[current-void-tag bits int64?
          #:value (unsyntax @code{#b00011110})]{
The tag for the ptr encoding of the void value.
}

@defparam[current-void-ptr bits int64?
          #:value (unsyntax @code{#b00011110})]{
The ptr encoding of the void value.
Note that this should always be identical to the @racket[current-void-tag].
}

@defparam[current-ascii-char-shift bits exact-nonnegative-integer?
          #:value 8]{
The bitwise shift length for the ptr encoding of ASCII character.
}

@defparam[current-ascii-char-mask bits int64?
          #:value (unsyntax @code{#b11111111})]{
The tag mask for the ptr encoding of ASCII characters.
}

@defparam[current-ascii-char-tag bits int64?
          #:value (unsyntax @code{#b00101110})]{
The tag for the ptr encoding of ASCII characters.
}

@defparam[current-error-shift bits exact-nonnegative-integer?
          #:value 8]{
The bitwise shift length for error values.
}

@defparam[current-error-mask bits int64?
          #:value (unsyntax @code{#b11111111})]{
The tag mask for the ptr encoding of error values.
}

@defparam[current-error-tag bits int64?
          #:value (unsyntax @code{#b00111110})]{
The tag for the ptr encoding of error values.
}

@defparam[current-pair-shift bits exact-nonnegative-integer?
          #:value 3]{
The bitwise shift length for the ptr encoding of pairs.
}

@defparam[current-pair-mask bits int64?
          #:value (unsyntax @code{#b111})]{
The tag mask for the ptr encoding of pairs.
}

@defparam[current-pair-tag bits int64?
          #:value (unsyntax @code{#b001})]{
The tag for the ptr encoding of pairs.
}

@defparam[current-car-displacement i int64?
          #:value 0]{
The number of bytes to add to a ptr representing a pair, after masking the tag,
to treat the ptr as a pointer to the first element of the pair.
Probably corresponds to 0 or 1 words.
}

@defparam[current-cdr-displacement i int64?
          #:value (unsyntax (current-cdr-displacement))]{
The number of bytes to add to a ptr representing a pair, after masking the tag,
to treat the ptr as a pointer to the second element of the pair.
Probably corresponds to 0 or 1 word.
}

@defproc[(car-offset) int64?]{
Returns the offset amount, in bytes, to add to a ptr representing a pair to
compute the address of the first element of the pair.
Includes the amount necessary to mask the tag.
}

@defproc[(cdr-offset) int64?]{
Returns the offset amount, in bytes, to add to a ptr representing a pair to
compute the address of the second element of the pair.
Includes the amount necessary to mask the tag.
}

@defparam[current-pair-size i int64?
          #:value (unsyntax (current-pair-size))]{
Returns the size of a pair, in bytes, for the current machine target.
}

@defparam[current-vector-shift bits exact-nonnegative-integer?
          #:value 3]{
The bitwise shift length for the ptr encoding of vectors.
}

@defparam[current-vector-mask bits int64?
          #:value (unsyntax @code{#b111})]{
The tag mask for the ptr encoding of vectors.
}

@defparam[current-vector-tag bits int64?
          #:value (unsyntax @code{#b011})]{
The tag for the ptr encoding of vectors.
}

@defparam[current-vector-length-displacement bytes int64?
          #:value (unsyntax (current-vector-length-displacement))]{
The number of bytes to add to the address of a vector to get the address of the
vector's length.
Probably corresponds to either 0 or 1 words.
}

@defparam[current-vector-base-displacement bytes int64?
          #:value (unsyntax (current-vector-base-displacement))]{
The number of bytes to add to the address of a vector to get the address of the
vector's base, which should be followed by the rest of the vector.
Probably corresponds to either 0 or 1 words.
}

@defparam[current-procedure-shift bits exact-nonnegative-integer?
          #:value (unsyntax (current-procedure-shift))]{
The bitwise shift length for the ptr encoding of procedures.
}

@defparam[current-procedure-mask bits int64?
          #:value (unsyntax @code{#b111})]{
The tag mask for the ptr encoding of procedures.
}

@defparam[current-procedure-tag bits int64?
          #:value (unsyntax @code{#b010})]{
The tag for the ptr encoding of procedures.
}

@defparam[current-procedure-label-displacement bytes int64?
          #:value (unsyntax (current-procedure-label-displacement))]{
The number of bytes to add to the address of a procedure to get the address of
the label of the procedure.
Probably corresponds to 0, 1 or 2 words.
}


@defparam[current-procedure-arity-displacement bytes int64?
          #:value (unsyntax (current-procedure-arity-displacement))]{
The number of bytes to add to the address of a procedure to get the address of
the arity of the procedure.
Probably corresponds to 0, 1 or 2 words.
}

@defparam[current-procedure-environment-displacement bytes int64?
          #:value (unsyntax (current-procedure-environment-displacement))]{
The number of bytes to add to the address of a procedure to get the address of
the environment of the procedure.
Probably corresponds to 0, 1 or 2 words.
}

@defproc[(ascii-char-literal? [c any/c]) boolean?]{
Returns @racket[#t] for ASCII character literals and @racket[#f] otherwise.

@examples[#:eval eg
(ascii-char-literal? #\a)
(ascii-char-literal? #\b)
(ascii-char-literal? #\6)
(ascii-char-literal? #\?)
(ascii-char-literal? #\space)
(char? #\λ)
(ascii-char-literal? #\λ)
]
}

@section{Misc Compiler Helpers}

@defproc[(make-begin [is (listof effect)] [t tail]) tail]{
A language-generic helper to make @racket[begin] statements in tail position.
The first arguments is a list of effect-context statements, while the final
argument is a tail-context statement.
@racket[make-begin] will construct @racket[`(begin ,is ... ,t)], but try to
minimize @racket[begins] in the process.

Assumes that @racket[t] has already been constructed using @racket[make-begin].

@examples[#:eval eg
(make-begin '() '(halt 5))
(make-begin '() '(begin (halt 5)))
(make-begin '((set! rax 5)) '(begin (halt 5)))
(make-begin '((set! rax 5)) '(begin (begin (halt 5))))
(make-begin '((begin (set! rax 5))) '(begin (halt 5)))
(make-begin '((begin (begin (set! rax 5)))) '(begin (halt 5)))
(make-begin '((begin (begin (set! rax 5)))) '(begin (begin (halt 5))))
(make-begin '((begin (begin (set! rax 5)))) (make-begin '() (make-begin '() '(halt 5))))
]
}

@defproc[(make-begin-effect [is (listof effect)]) effect]{
A language-generic helper to make @racket[begin] statements effect position.
The first arguments is a list of effect-context statements.
@racket[make-begin-effect] will construct @racket[`(begin ,is ...)], but try to
minimize @racket[begins] in the process.

@examples[#:eval eg
(make-begin-effect '())
(make-begin-effect '((begin (set! rax 5))))
(make-begin-effect '((set! rax 5)))
(make-begin-effect '((begin (begin (set! rax 5))) (begin (set! rax 5))))
]
}

@defproc[(check-assignment (p any/c)) any/c]{
Takes a program in any language where the @racket[second] element satisfies
@racketblock[
(let ([loc? (or/c register? fvar?)])
  (info/c
   (assignment ((aloc? loc?) ...))
   (conflicts ((aloc? (aloc? ...)) ...))
   (locals (aloc? ...))))
]

Check that the given assignment is sound with respect to the conflicts graph
and complete with respect the locals set.
Returns @racket[p] if so, or raises an error.

To be language agnostic, it doesn't actually check that the program is valid and
only depends on the info field.

@examples[#:eval eg
(check-assignment
 `(module
    ((locals (v.1 w.2 x.3 y.4 z.5 t.6 p.1))
     (conflicts
      ((p.1 (z.5 t.6 y.4 x.3 w.2))
       (t.6 (p.1 z.5))
       (z.5 (p.1 t.6 w.2 y.4))
       (y.4 (z.5 x.3 p.1 w.2))
       (x.3 (y.4 p.1 w.2))
       (w.2 (z.5 y.4 p.1 x.3 v.1))
       (v.1 (w.2))))
     (assignment
      ((v.1 r15) (w.2 r8) (x.3 r14) (y.4 r9) (z.5 r13) (t.6 r14) (p.1 r15))))))

(eval:error
 (check-assignment
 `(module
    ((locals (v.1 w.2 x.3 y.4 z.5 t.6 p.1))
     (conflicts
      ((p.1 (z.5 t.6 y.4 x.3 w.2))
       (t.6 (p.1 z.5))
       (z.5 (p.1 t.6 w.2 y.4))
       (y.4 (z.5 x.3 p.1 w.2))
       (x.3 (y.4 p.1 w.2))
       (w.2 (z.5 y.4 p.1 x.3 v.1))
       (v.1 (w.2))))
     (assignment
      ((w.2 r8) (x.3 r14) (y.4 r9) (z.5 r13) (t.6 r14) (p.1 r15)))))))

(eval:error
 (check-assignment
  `(module
     ((locals (v.1 w.2 x.3 y.4 z.5 t.6 p.1))
      (conflicts
       ((p.1 (z.5 t.6 y.4 x.3 w.2))
        (t.6 (p.1 z.5))
        (z.5 (p.1 t.6 w.2 y.4))
        (y.4 (z.5 x.3 p.1 w.2))
        (x.3 (y.4 p.1 w.2))
        (w.2 (z.5 y.4 p.1 x.3 v.1))
        (v.1 (w.2))))
      (assignment
       ((v.1 r8) (w.2 r8) (x.3 r14) (y.4 r9) (z.5 r13) (t.6 r14) (p.1 r15)))))))
]
}

@defproc[(map-n [n any/c] [f procedure?] [ls list?] ...+) any]{
Like @racket[map], but returns @racket[n] lists.
Expects @racket[f] to returns @racket[n] return values.
Support mapping over any non-zero number of lists.

@examples[
#:eval eg
(map-n 2 (lambda (x y) (values (add1 x) (sub1 y))) '(1 2 3) '(1 2 3))
(map-n 3 (lambda (x) (values (add1 x) (sub1 x) (* 2 x))) '(1 2 3))
]
}

@defproc[(map2 [f procedure?] [ls list?] ...+) any]{
Short-hand for @racket[(curry map-n 2)]

@examples[
#:eval eg
(map-n 2 (lambda (x y) (values (add1 x) (sub1 y))) '(1 2 3) '(1 2 3))
(map2 (lambda (x y) (values (add1 x) (sub1 y))) '(1 2 3) '(1 2 3))
]
}

;;;; Copyright (c) 2017 Henry Harrington <henry.harrington@gmail.com>
;;;; This code is licensed under the MIT license.

(in-package :mezzano.compiler.backend.x86-64)

(define-builtin mezzano.runtime::%car ((cons) result)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list result `(:car ,cons))
                       :inputs (list cons)
                       :outputs (list result))))

(define-builtin mezzano.runtime::%cdr ((cons) result)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list result `(:cdr ,cons))
                       :inputs (list cons)
                       :outputs (list result))))

(define-builtin (setf mezzano.runtime::%car) ((value cons) result)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list `(:car ,cons) value)
                       :inputs (list cons value)
                       :outputs '()))
  (emit (make-instance 'move-instruction
                       :destination result
                       :source value)))

(define-builtin (setf mezzano.runtime::%cdr) ((value cons) result)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list `(:cdr ,cons) value)
                       :inputs (list cons value)
                       :outputs '()))
  (emit (make-instance 'move-instruction
                       :destination result
                       :source value)))

(define-builtin sys.int::%value-has-tag-p ((object (:constant tag (typep tag '(unsigned-byte 4)))) :z)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:lea64
                         :operands (list temp `(,object ,(- tag)))
                         :inputs (list object)
                         :outputs (list temp)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:test64
                         :operands (list temp #b1111)
                         :inputs (list temp)
                         :outputs '()))))

(define-builtin mezzano.runtime::%%object-of-type-p ((object (:constant object-tag (typep object-tag '(unsigned-byte 6)))) :e)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov8
                       :operands (list :al `(:object ,object -1))
                       :inputs (list object)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:and8
                       :operands (list :al (ash (1- (ash 1 sys.int::+object-type-size+))
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp8
                       :operands (list :al (ash object-tag sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs '())))

(define-builtin mezzano.runtime::%functionp ((object) :be)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov8
                       :operands (list :al `(:object ,object -1))
                       :inputs (list object)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:sub8
                       :operands (list :al (ash sys.int::+first-function-object-tag+
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:and8
                       :operands (list :al (ash (1- (ash 1 sys.int::+object-type-size+))
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp8
                       :operands (list :al (ash (- sys.int::+last-function-object-tag+
                                                   sys.int::+first-function-object-tag+)
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs '())))

(define-builtin mezzano.runtime::%%simple-1d-array-p ((object) :be)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov8
                       :operands (list :al `(:object ,object -1))
                       :inputs (list object)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:and8
                       :operands (list :al (ash (1- (ash 1 sys.int::+object-type-size+))
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp8
                       :operands (list :al (ash sys.int::+last-simple-1d-array-object-tag+
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs '())))

(define-builtin mezzano.runtime::%%arrayp ((object) :be)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov8
                       :operands (list :al `(:object ,object -1))
                       :inputs (list object)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:and8
                       :operands (list :al (ash (1- (ash 1 sys.int::+object-type-size+))
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp8
                       :operands (list :al (ash sys.int::+last-complex-array-object-tag+
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs '())))

(define-builtin mezzano.runtime::%%complex-array-p ((object) :be)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov8
                       :operands (list :al `(:object ,object -1))
                       :inputs (list object)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:sub8
                       :operands (list :al (ash sys.int::+first-complex-array-object-tag+
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:and8
                       :operands (list :al (ash (1- (ash 1 sys.int::+object-type-size+))
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs (list :rax)))
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp8
                       :operands (list :al (ash (- sys.int::+last-complex-array-object-tag+
                                                   sys.int::+first-complex-array-object-tag+)
                                                sys.int::+object-type-shift+))
                       :inputs (list :rax)
                       :outputs '())))

(define-builtin sys.int::%unbound-value-p ((object) :e)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp64
                       :operands (list object :unbound-value)
                       :inputs (list object)
                       :outputs (list))))

(define-builtin sys.int::%undefined-function-p ((object) :e)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:cmp64
                       :operands (list object :undefined-function)
                       :inputs (list object)
                       :outputs (list))))

(define-builtin eq ((lhs rhs) :e)
  (cond ((constant-value-p rhs '(eql nil))
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs nil)
                              :inputs (list lhs)
                              :outputs '())))
        ((constant-value-p rhs '(eql t))
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs t)
                              :inputs (list lhs)
                              :outputs '())))
        ((constant-value-p rhs '(eql 0))
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:test64
                              :operands (list lhs lhs)
                              :inputs (list lhs)
                              :outputs '())))
        ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs (ash (fetch-constant-value rhs)
                                                       sys.int::+n-fixnum-bits+))
                              :inputs (list lhs)
                              :outputs '())))
        (t
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs rhs)
                              :inputs (list lhs rhs)
                              :outputs '())))))

(define-builtin sys.int::%object-ref-t ((object index) result)
  (cond ((constant-value-p index '(signed-byte 29))
         (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list result `(:object ,object ,(fetch-constant-value index)))
                       :inputs (list object)
                       :outputs (list result))))
        (t
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:mov64
                              :operands (list result `(:object ,object 0 ,index 4))
                              :inputs (list object index)
                              :outputs (list result))))))

(define-builtin (setf sys.int::%object-ref-t) ((value object index) result)
  (cond ((constant-value-p index '(signed-byte 29))
         (emit (make-instance 'x86-instruction
                       :opcode 'lap:mov64
                       :operands (list `(:object ,object ,(fetch-constant-value index)) value)
                       :inputs (list value object)
                       :outputs (list))))
        (t
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:mov64
                              :operands (list `(:object ,object 0 ,index 4) value)
                              :inputs (list value object index)
                              :outputs (list)))))
  (emit (make-instance 'move-instruction
                       :source value
                       :destination result)))

(define-builtin sys.int::%object-header-data ((object) result)
  (let ((temp1 (make-instance 'virtual-register))
        (temp2 (make-instance 'virtual-register)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list temp1 `(:object ,object -1))
                         :inputs (list object)
                         :outputs (list temp1)))
    (emit (make-instance 'x86-fake-three-operand-instruction
                         :opcode 'lap:and64
                         :result temp2
                         :lhs temp1
                         :rhs (lognot (1- (ash 1 sys.int::+object-data-shift+)))))
    (emit (make-instance 'x86-fake-three-operand-instruction
                         :opcode 'lap:shr64
                         :result result
                         :lhs temp2
                         :rhs (- sys.int::+object-data-shift+ sys.int::+n-fixnum-bits+)))))

(define-builtin sys.int::%%object-ref-unsigned-byte-32 ((object index) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    ;; Need to use :eax and a temporary here because it's currently impossible
    ;; to replace vregs with non-64-bit gprs.
    ;; Using a temporary & a move before the box allows the box to safely
    ;; eliminated.
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov32
                         :operands (list :eax `(:object ,object 0 ,index 2))
                         :inputs (list object index)
                         :outputs (list :rax)
                         :clobbers '(:rax)))
    (emit (make-instance 'move-instruction
                         :source :rax
                         :destination temp))
    (emit (make-instance 'box-fixnum-instruction
                         :source temp
                         :destination result))))

(define-builtin (setf sys.int::%%object-ref-unsigned-byte-32) ((value object index) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    ;; Need to use :eax and a temporary here because it's currently impossible
    ;; to replace vregs with non-64-bit gprs.
    ;; Using a temporary & a move before the box allows the box to safely
    ;; eliminated.
    (emit (make-instance 'unbox-fixnum-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'move-instruction
                         :source temp
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov32
                         :operands (list `(:object ,object 0 ,index 2) :eax)
                         :inputs (list object index :rax)
                         :outputs (list)))
    (emit (make-instance 'move-instruction
                         :source value
                         :destination result))))

(define-builtin sys.int::%%object-ref-unsigned-byte-64 ((object index) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list temp `(:object ,object 0 ,index 4))
                         :inputs (list object index)
                         :outputs (list temp)))
    (emit (make-instance 'box-unsigned-byte-64-instruction
                         :source temp
                         :destination result))))

(define-builtin (setf sys.int::%%object-ref-unsigned-byte-64) ((value object index) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-unsigned-byte-64-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list `(:object ,object 0 ,index 4) temp)
                         :inputs (list object index temp)
                         :outputs (list)))
    (emit (make-instance 'move-instruction
                         :source value
                         :destination result))))

;;; Knowledge Base and Inference Engine

(defpackage :symbolic-ai
  (:use :common-lisp)
  (:export #:knowledge-base #:add-fact #:add-rule #:query #:forward-chain))

(in-package :symbolic-ai)

;;; Data structures
(defclass knowledge-base ()
  ((facts :initform '() :accessor facts)
   (rules :initform '() :accessor rules)))

(defstruct rule
  name
  conditions
  conclusions)

;;; Macros for syntactic sugar
(defmacro fact (&rest assertions)
  "Define a fact in the knowledge base"
  `(list ,@(mapcar (lambda (assertion) `',assertion) assertions)))

(defmacro defrule (name (&rest conditions) &body conclusions)
  "Define a rule with conditions and conclusions"
  `(make-rule :name ',name
              :conditions ',(mapcar #'list conditions)
              :conclusions ',conclusions))

;;; Pattern matching functions
(defun variable-p (symbol)
  "Check if symbol is a variable (starts with ?)"
  (and (symbolp symbol)
       (char= (char (symbol-name symbol) 0) #\?)))

(defun match-pattern (pattern data &optional (bindings '()))
  "Pattern matcher with variable binding"
  (cond
    ((variable-p pattern)
     (let ((existing (assoc pattern bindings)))
       (if existing
           (if (equal (cdr existing) data) bindings nil)
           (cons (cons pattern data) bindings))))
    ((and (listp pattern) (listp data))
     (and (= (length pattern) (length data))
          (reduce (lambda (acc pair)
                    (and acc (match-pattern (car pair) (cdr pair) acc)))
                  (mapcar #'cons pattern data)
                  :initial-value bindings)))
    ((equal pattern data) bindings)
    (t nil)))

(defun substitute-bindings (pattern bindings)
  "Replace variables in pattern with their bindings"
  (cond
    ((variable-p pattern)
     (or (cdr (assoc pattern bindings)) pattern))
    ((listp pattern)
     (mapcar (lambda (elem) (substitute-bindings elem bindings)) pattern))
    (t pattern)))

;;; Knowledge base operations
(defmethod add-fact ((kb knowledge-base) fact)
  "Add a fact to the knowledge base"
  (pushnew fact (facts kb) :test #'equal))

(defmethod add-rule ((kb knowledge-base) rule)
  "Add a rule to the knowledge base"
  (pushnew rule (rules kb) :test #'equal))

(defmethod query ((kb knowledge-base) pattern)
  "Query the knowledge base for matching facts"
  (remove-if #'null
             (mapcar (lambda (fact)
                       (match-pattern pattern fact))
                     (facts kb))))

;;; Inference engine
(defun apply-rule (kb rule bindings)
  "Apply a rule with given bindings"
  (mapcar (lambda (conclusion)
            (substitute-bindings conclusion bindings))
          (rule-conclusions rule)))

(defun try-rule (kb rule)
  "Try to apply a rule by matching all conditions"
  (labels ((match-conditions (conditions bindings)
             (if (null conditions)
                 (list bindings)
                 (let ((matches (query kb (substitute-bindings 
                                          (first conditions) bindings))))
                   (mapcan (lambda (binding)
                             (match-conditions (rest conditions) binding))
                           matches)))))
    (let ((binding-sets (match-conditions (rule-conditions rule) '())))
      (mapcan (lambda (bindings)
                (apply-rule kb rule bindings))
              binding-sets))))

(defmethod forward-chain ((kb knowledge-base) &optional (max-iterations 10))
  "Forward chaining inference"
  (dotimes (i max-iterations)
    (let ((new-facts '())
          (old-count (length (facts kb))))
      
      (dolist (rule (rules kb))
        (let ((derived (try-rule kb rule)))
          (dolist (fact derived)
            (unless (member fact (facts kb) :test #'equal)
              (push fact new-facts)))))
      
      (dolist (fact new-facts)
        (add-fact kb fact))
      
      (when (= (length (facts kb)) old-count)
        (return-from forward-chain i))))
  max-iterations)

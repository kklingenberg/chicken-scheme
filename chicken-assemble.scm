#!/usr/local/bin/csi -script

(import (chicken format)
        (chicken io)
        (chicken process-context)
        (chicken sort)
        (chicken string)
        (clojurian syntax)
        records
        srfi-1
        srfi-69)

;; Parse command line arguments: [src-dir [core-module]]
;;   src-dir is the root directory for the project
;;   core-module is the file name of the 'main' module, whithout
;;   extension
(define-values (base-dir base-package)
  (let ((args (command-line-arguments)))
    (cond ((null? args) (values "src"  'core))
          ((null? (cdr args)) (values (car args) 'core))
          (else (values (car args) (string->symbol (cadr args)))))))

;; Translate a local package reference to a file path
(define (path package)
  (-> (symbol->string package)
      (string-split ".")
      (->> (cons base-dir))
      (string-intersperse "/")
      (conc ".scm")))

;; Define a struct for each module-file. The brethren are other local
;; package references found within the body of a module-file.
(define node-type (make-record-type 'node '(package brethren body)))
(define make-node (record-constructor node-type '(package brethren body)))
(define node-package (record-accessor node-type 'package))
(define node-brethren (record-accessor node-type 'brethren))
(define node-body (record-accessor node-type 'body))

;; Collect brethren given a body of s-expressions. Brethren are
;; imported 'local' modules.
(define (find-brethren body)
  (->> body
       (filter (lambda (form)
                 (eqv? (car form) 'import)))
       (map cdr)
       (concatenate)
       (filter list?)
       (filter (lambda (form)
                 (eqv? (car form) 'local)))
       (map cadr)))

;; Collect a piece of the modules graph given a source file.
(define (collect-from source graph)
  (let* ((body (with-input-from-file (path source) read-list))
         (brethren (find-brethren body)))
    (hash-table-set! graph source (make-node source brethren body))
    (->> brethren
         (remove (lambda (package)
                   (hash-table-exists? graph package)))
         (for-each (lambda (package)
                     (collect-from package graph))))
    graph))

;; The 'whole' graph, as required from the core-module.
(define graph (collect-from base-package (make-hash-table)))

;; Toposort said graph to define modules in logical order. This fails
;; on circular dependencies.
(define sorted-graph
  (-> (hash-table-values graph)
      (->> (map (lambda (node)
                  (cons (node-package node)
                        (node-brethren node)))))
      (topological-sort eqv?)
      reverse))

;; Replace an unofficial local import into a real chicken import,
;; using the module name as a prefix (plus a forward slash).
(define (replace-local-imports body)
  (define (rewrite-local-import form)
    (let* ((package (cadr form))
           (alias (if (>= (length form) 3)
                      (caddr form)
                      package)))
      (list 'prefix package (string->symbol (conc (symbol->string alias) "/")))))

  (map (lambda (form)
         (if (eqv? (car form) 'import)
             (map (lambda (import-form)
                    (if (and (list? import-form)
                             (eqv? (car import-form) 'local))
                        (rewrite-local-import import-form)
                        import-form))
                  form)
             form))
       body))

;; Build the assembled, single-file multi-module program.
(for-each (lambda (package)
            (let ((node (hash-table-ref graph package)))
              (write (append (list 'module package '*)
                             (replace-local-imports (node-body node))))
              (print)))
          sorted-graph)
(write (list 'import
             '(chicken process-context)
             (list 'prefix base-package 'core/)))
(print)
(write '(apply core/-main (command-line-arguments)))
(print)

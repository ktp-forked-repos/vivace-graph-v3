(in-package :graph-db)

(defgeneric backup (object location &key include-deleted-p))

(defmethod backup :around ((node node) location &key include-deleted-p)
  (when (or include-deleted-p (not (deleted-p node)))
    (call-next-method)))

(defmethod backup ((v vertex) (stream stream) &key include-deleted-p)
  (declare (ignore include-deleted-p))
  (let ((plist
         (list :v
               (type-of v)
               (when (slot-boundp v 'data)
                 (data v))
               :id (id v)
               :revision (revision v)
               :deleted-p (deleted-p v))))
    (let ((*print-pretty* nil))
      (format stream "~S~%" plist))))

(defmethod backup ((e edge) (stream stream) &key include-deleted-p)
  (declare (ignore include-deleted-p))
  (let ((plist
         (list :e
               (type-of e)
               (from e)
               (to e)
               (weight e)
               (when (slot-boundp e 'data)
                 (data e))
               :id (id e)
               :revision (revision e)
               :deleted-p (deleted-p e))))
    (let ((*print-pretty* nil))
      (format stream "~S~%" plist))))

(defmethod backup ((graph graph) location &key include-deleted-p)
  (ensure-directories-exist location)
  (let ((count 0))
    (with-open-file (out location :direction :output)
      (map-vertices (lambda (v)
                      (init-node-data v :graph graph)
                      (incf count)
                      (backup v out))
                    graph :include-deleted-p include-deleted-p)
      (map-edges (lambda (e)
                   (init-node-data e :graph graph)
                   (incf count)
                   (backup e out))
                 graph :include-deleted-p include-deleted-p)
      (values count location))))

(defmethod check-data-integrity ((graph graph) &key include-deleted-p)
  (let ((*cache-enabled* nil))
    (let ((problems nil) (count 0))
      (map-vertices (lambda (v)
                      (incf count)
                      (when (= 0 (mod count 1000))
                        (format t ".")
                        (force-output))
                      (handler-case
                          (init-node-data v :graph graph)
                        (error (c)
                          (push (cons (string-id v) c) problems))))
                    graph :include-deleted-p include-deleted-p)
      (map-edges (lambda (e)
                      (incf count)
                      (when (= 0 (mod count 1000))
                        (format t ".")
                        (force-output))
                   (handler-case
                       (init-node-data e :graph graph)
                     (error (c)
                       (push (cons (string-id e) c) problems))))
                 graph :include-deleted-p include-deleted-p)
      (terpri)
      problems)))






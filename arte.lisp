;; (arte) dvnmk 2015

;; heap exhausted faulty wget func
;;
;; (defun wget (url output-name)
;;   (with-open-file (my-stream (concatenate 'string output-name ".mp4")
;;                              :direction :output
;;                              :element-type '(unsigned-byte 8)
;;                              :if-does-not-exist :create
;;                              :if-exists :supersede)
;;     (let ((content (drakma:http-request url)))
;;       (loop for i across content do
;;            (write-byte i my-stream)))))

(ql:quickload "yason")
(ql:quickload "drakma")
(setf drakma:*header-stream* nil)
(defvar *speicher-dir* #P"~/arte7/")

(defparameter *tmp* nil)
(defparameter *prozess* '())

(defun cd (&optional dir)
  "Change directory and set default pathname"
  (cond
   ((not (null dir))
    (when (and (typep dir 'logical-pathname)
           (translate-logical-pathname dir))
      (setq dir (translate-logical-pathname dir)))
    (when (stringp dir)
      (setq dir (parse-namestring dir)))
    #+allegro (excl:chdir dir)
    #+clisp (#+lisp=cl ext:cd #-lisp=cl lisp:cd dir)
    #+(or cmu scl) (setf (ext:default-directory) dir)
    #+cormanlisp (ccl:set-current-directory dir)
    #+(and mcl (not openmcl)) (ccl:set-mac-default-directory dir)
    #+openmcl (ccl:cwd dir)
    #+gcl (si:chdir dir)
    #+lispworks (hcl:change-directory dir)
    #+sbcl (sb-posix:chdir dir)
    (setq cl:*default-pathname-defaults* dir))
   (t
    (let ((dir
       #+allegro (excl:current-directory)
       #+clisp (#+lisp=cl ext:default-directory #-lisp=cl lisp:default-directory)
       #+(or cmu scl) (ext:default-directory)
       #+sbcl (sb-unix:posix-getcwd/)
       #+cormanlisp (ccl:get-current-directory)
       #+lispworks (hcl:get-working-directory)
       #+mcl (ccl:mac-default-directory)
       #-(or allegro clisp cmu scl cormanlisp mcl sbcl lispworks) (truename ".")))
      (when (stringp dir)
    (setq dir (parse-namestring dir)))
      dir))))

(cd *speicher-dir*)

(defun nmr2json (nmr)
  (let* ((json-url (concatenate 'string
                                "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                                nmr
                                "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request json-url)
                                              :external-format :utf-8)))
    (yason:parse vec)))

(defun normalisieren (string)
  (flet ((slash2.s (x)
           (cl-ppcre:regex-replace-all "/" x ".s"))
         (apo22bar (x)
           (cl-ppcre:regex-replace-all "’" x "-"))
         (apo2bar (x)
           (cl-ppcre:regex-replace-all "'" x "-"))
         (blanko2underbar (x)
           (cl-ppcre:regex-replace-all " " x "_")))
    (slash2.s (apo22bar (apo2bar  (blanko2underbar string))))))

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (subseq (info "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (normalisieren (info "VTI" nivo-0))
                                 "+" kurz-datum
                                 "~" (info "genre" nivo-0)))
         (res (list :titl file-name
                    :info  (info "infoProg" nivo-0)
                    :kurz  (info "V7T" nivo-0)
                    :lang   (info "VDE" nivo-0)
                    ;;:mode  (alexandria:hash-table-keys (info "VSR" nivo-0))
                    :file   url
                    :id (info "VPI" nivo-0))))
    (progn
      (setf *tmp* res)
      (format t "~{*~A ~8T~A~%~}" res)
      (with-open-file (out (concatenate 'string "~/arte7/" file-name ".txt")
                           :direction :output
                           :if-exists :supersede)
        (format out "~{*~A ~8T~A~%~}" res))
      )
    t))

(defun arte-nimm (nmr)
  (arte-info nmr)
  (let* ((cmd (format nil "wget -c ~A -O ~A.mp4 --no-verbose -a ~a.txt --tries=4"
                     (getf *tmp* :file)
                     (getf *tmp* :titl) (getf *tmp* :titl)))
        (proz (run-program "/bin/sh" (list "-c" cmd)
                              :wait nil
                              :output *standard-output*
                              ;;:status-hook (format t "STATUS CHANGED")
                              ))
         (res (list :titl (getf *tmp* :titl)
                    :id (getf *tmp* :id)
                    :proz proz)))
    (push res *prozess*)
    t ))

(defun prozess-reset ()
  ":exited :signaled weg func"
  (setf *prozess* nil))

(defun kill (n)
  "sigint 2 sigkill 9"
  (signal-external-process (getf (nth n *prozess*) :proz) 2
                           :error-if-exited nil))

(defun check-nth (n)
  (let ((foo (getf (nth n *prozess*) :proz))
        (titl (getf (nth n *prozess*) :titl))
        (id (getf (nth n *prozess*) :id)))
    (format t "~D ~S ~%  ~A ~A <~A>~%~%"
            n titl id (external-process-id foo) (external-process-status foo))))

(defun check ()
  (do ((i 0 (+ 1 i)))
      ((equal i (length *prozess*)) t)
    (check-nth i)))

(defun arte-guck (nmr)
  (arte-info nmr)
  (let ( (cmd (format nil "mplayer -really-quiet -cache 10240 ~A"
                      (getf *tmp* :file))))
    (run-program "/bin/sh" (list "-c" cmd)
                 :wait nil
                 :output *standard-output*)))

(defun arte-quck (nmr)
  "arte-guck quicktime player ver."
  (arte-info nmr)
  (let ((cmd (format nil "open -a Quicktime\\ Player ~A"
                     (getf *tmp* :file))))
    (run-program "/bin/sh" (list "-c" cmd)
                 :wait nil
                 :output *standard-output*)))

(defmacro i (nmr-raw) 
  `(let ((nmr  (symbol-name ',nmr-raw)))
     (arte-info nmr)))
(defmacro n (nmr-raw)
  `(let ((nmr (symbol-name ',nmr-raw)))
     (arte-nimm nmr)))
(defmacro g (nmr-raw)
  `(let ((nmr (symbol-name ',nmr-raw)))
     (arte-guck nmr)))
(defmacro q (nmr-raw)
  `(let ((nmr (symbol-name ',nmr-raw)))
     (arte-quck nmr)))

;; (defun kill ()
;;   (run-program "/bin/sh" '("-c" "killall wget")
;;                :output *standard-output*)
;;   (run-program "/bin/sh" '("-c" "killall mplayer")
;;                :output *standard-output*))


;; ;;TODO
;; (format nil "~4,'0d - ~2,'0d - ~2,'0d" 2005 6 10)
;; "2005 - 06 - 10"

;; ;; prompt
;; (defun prompt-read (prompt)
;;   (format *query-io* "~A: " prompt)
;;   (force-output *query-io*)
;;   (read-line *query-io*))


;; (defun add-cds ()
;;   (loop (add-record (prompt-for-cd))
;;      (if (not (y-or-n-p "Another? [y/n]: "))
;;          (return))))



;; (defun save-db (filename)
;;   (with-open-file (out filename
;;                        :direction :output
;;                        :if-exists :supersede)
;;     (with-standard-io-syntax
;;       (print *db* out))))

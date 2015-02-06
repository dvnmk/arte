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
(defvar *speicher-dir* #P"~/arte7")

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

(defun nmr2json (nmr)
  (let* ((json-url (concatenate 'string
                                "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                                nmr
                                "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request json-url)
                                              :external-format :utf-8)))
    (yason:parse vec)))

(defun normalisierung (string)
  (labels ((slash2.s (x)
             (cl-ppcre:regex-replace-all "/" x ".s"))
           (apo22bar (x)
             (cl-ppcre:regex-replace-all "’" x "-"))
           (apo2bar (x)
             (cl-ppcre:regex-replace-all "'" x "-"))
           (blanko2underbar (x)
             (cl-ppcre:regex-replace-all " " x "_"))))
  (slash2.s (apo22bar (apo2bar  (blanko2underbar string)))))

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (subseq (info "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (normalisierung (info "VTI" nivo-0))
                                 "+" kurz-datum
                                 "~" (info "genre" nivo-0))))
    (format t "~&* TITL : ~S" (info "VTI" nivo-0))
    (format t "~&* KURZ : ~S" (info "V7T" nivo-0))
    (format t "~&* INFO : ~A ~A" (info "genre" nivo-0) (info "infoProg" nivo-0))
    (format t "~&* AIRD : ~A - ~A" (info "VDA" nivo-0)(info "VRU" nivo-0))
    (format t "~&* BESS : ~A" (info "VDE" nivo-0))
    (format t "~&* FILE : ~%  wget -c ~A -O ~A.mp4 --tries=4 ~%" url file-name)
    ;;(format t "~&* MODES : ~A" (alexandria:hash-table-keys (info "VSR" nivo-0 )))
    t))

(defun arte-nimm (nmr)
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (subseq (info "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (normalisierung (info "VTI" nivo-0))
                                 "+" kurz-datum
                                 "~" (info "genre" nivo-0)))
         (cmd (format nil "wget -c ~A -O ~A.mp4 --no-verbose -a ~A.txt --tries=4"
                           url file-name file-name)))
    (run-program "/bin/sh" (list "-c" cmd)
                 :wait nil
                 :output *standard-output*)))

(defun arte-guck (nmr)
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (cmd (format nil "mplayer -really-quiet -cache 10240 ~A" url)))
    (run-program "/bin/sh" (list "-c" cmd)
                 :wait nil
                 :output *standard-output*)))

(defun arte-quck (nmr)
  "arte-guck quicktime player ver."
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (cmd (format nil "open -a Quicktime\\ Player ~A" url)))
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

(cd *speicher-dir*)

(defun kill ()
  (run-program "/bin/sh" '("-c" "killall wget")
               :output *standard-output*)
  (run-program "bin/sh" '("-c" "killall mplayer")
               :output *standard-output*))


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

;; (arte) dvnmk 2015
;; heap exhausted faulty

;; (defun wget (url output-name)
;;   (with-open-file (my-stream (concatenate 'string output-name ".mp4")
;;                              :direction :output
;;                              :element-type '(unsigned-byte 8)
;;                              :if-does-not-exist :create
;;                              :if-exists :supersede)
;;     (let ((content (drakma:http-request url)))
;;       (loop for i across content do
;;            (write-byte i my-stream)))))
;;
;; ** DONE filename zv datum.
;; ** DONE fur shell / ccl only 
;; ** DONE Unicode suppport als file-name y alle.

(ql:quickload "yason")
(ql:quickload "drakma")
(setf drakma:*header-stream* nil)
(defvar *speicher-dir* #P"~/arte7")

(defun nmr2json (nmr)
  (let* ((json-url 
         (concatenate 'string
                      "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                      nmr
                      "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request json-url)
                                              :external-format :utf-8)))
    (yason:parse vec) ))

(defun blanko2underbar (string)
  (cl-ppcre:regex-replace-all " " string "_"))

(defun apo2bar (string)
  (cl-ppcre:regex-replace-all "'" string "-"))

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr))))
    (format t "~&* TITL : ~S" (info "VTI" nivo-0))
    (format t "~&* KURZ : ~S" (info "V7T" nivo-0))
    (format t "~&* INFO : ~A ~A" (info "genre" nivo-0) (info "infoProg" nivo-0))
    (format t "~&* AIRD : ~A - ~A" (info "VDA" nivo-0)(info "VRU" nivo-0))
    (format t "~&* BESS : ~A" (info "VDE" nivo-0))
    ;;(format t "~&* MODES : ~A" (alexandria:hash-table-keys (info "VSR" nivo-0 )))
    t))

(defun arte-nimm (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
         (url (alexandria:ensure-gethash "url"
                                         (alexandria:ensure-gethash "HTTP_MP4_SQ_1"
                                                                          (info "VSR" nivo-0))))
         (kurz-datum (subseq (alexandria:ensure-gethash "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (apo2bar (blanko2underbar (info "VTI" nivo-0)))
                                 "-" kurz-datum))
         (url-simple-string (format nil "~A" url))  ;base-string 2 simple-base-string!
         (wget-cmd (concatenate 'string
                                "wget -c " url-simple-string
                                " -O " file-name ".mp4"
                                ;;" --progress=dot:giga "
                                " --no-verbose "
                                " -o " file-name ".log"
                                " --tries=4")))
    (run-program "/bin/sh"
                 (list "-c" wget-cmd)
                 :wait nil
                 :output *standard-output*)))


(defun arte-guck (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
         (url (alexandria:ensure-gethash "url"
                                         (alexandria:ensure-gethash "HTTP_MP4_SQ_1"
                                                                          (info "VSR" nivo-0))))
         ;; (kurz-datum (subseq (alexandria:ensure-gethash "VS5" (info "VST" nivo-0))
         ;;                     0 4))
         ;; (file-name (concatenate 'string
         ;;                         (apo2bar (blanko2underbar (info "VTI" nivo-0)))
         ;;                         "-" kurz-datum))
         (url-simple-string (format nil "~A" url))  ;base-string 2 simple-base-string!
         (cmd (concatenate 'string
                           "mplayer -really-quiet -cache 10240 "
                           url-simple-string
                           ;;" --progress=dot:giga "
                           ;;" --no-verbose "
                           ;;" -o " file-name ".log"
                           ;;" --tries=4"
                           ;;" -O - " " | " " mplayer -really-quiet -cache 10240 - "
                           )))
    (run-program "/bin/sh"
                 (list "-c" cmd)
                 :wait nil
                 :output *standard-output*)))

(defmacro i (nmr6-nmr3) 
  `(let ((nmr  (symbol-name ',nmr6-nmr3)))
     (arte-info nmr)))

(defmacro n (nmr6-nmr3)
  `(let ((nmr (symbol-name ',nmr6-nmr3)))
     (arte-nimm nmr)))

(defmacro g (nmr6-nmr3)
  `(let ((nmr (symbol-name ',nmr6-nmr3)))
     (arte-guck nmr)))

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

(defun kill ()
  (run-program "/bin/sh" '("-c" "killall wget")
               :output *standard-output*)
  (run-program "bin/sh" '("-c" "killall mplayer")
               :output *standard-output*))



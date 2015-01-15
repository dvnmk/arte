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

(Defun arte-get (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
         (url (alexandria:ensure-gethash "url"
                                         (alexandria:ensure-gethash "HTTP_MP4_SQ_1"
                                                                          (info "VSR" nivo-0))))
         (kurz-datum (subseq (alexandria:ensure-gethash "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (apo2bar (blanko2underbar (info "VTI" nivo-0)))
                                 "-" kurz-datum
                                 ".mp4"))
         (url-simple-string (format nil "~A" url))  ;base-string 2 simple-base-string!
         (wget-cmd (concatenate 'string
                                "wget -c " url-simple-string " -O "
                                file-name
                                ;;" --progress=dot:giga "
                                " --no-verbose "
                                " -o " (concatenate 'string file-name ".log")
                                " --tries=4")))
    (run-program "sh"
                 (list "-c" wget-cmd)
                 :wait nil
                 :output *standard-output*)))

(defmacro i (nmr6-nmr3) 
  `(let ((nmr  (symbol-name ',nmr6-nmr3)))
     (arte-info nmr)))

(defmacro g (nmr6-nmr3)
  `(let ((nmr (symbol-name ',nmr6-nmr3)))
     (arte-get nmr)))

(cwd *speicher-dir*)

(defun kill ()
  (run-program "killall" '("wget")
               :output *standard-output*))

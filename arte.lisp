;#!/usr/local/bin/sbcl --noinform 

(ql:quickload "yason")
(ql:quickload "drakma")
(setf drakma:*header-stream* nil)
(load #P"~/arte/asciify.lisp")

(defun nmr2json (nmr)
  (let* ((url 
         (concatenate 'string
                      "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                      nmr
                      "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request url))))
    (yason:parse vec) ))


(defun blanko2underbar (string)
  (cl-ppcre:regex-replace-all " " string "_"))

(defun apo2bar (string)
  (cl-ppcre:regex-replace-all "'" string "-"))

;; QUALITY = LQ, MQ, EQ, SQ where LQ < MQ < EQ < SQ
;; 		SQ = 720p 1280x720 bitrate 2200 (HD)
;; 		EQ = 400p 720x406 bitrate 1500
;; 		MQ = 400p 720x406 bitrate 800
;; 		LQ = 220p 320x200 bitrate 300

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
        (url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
        (kurz-datum (alexandria:ensure-gethash "VS5" (info "VST" nivo-0)))
         (file-name
          (ASCIIFY (concatenate 'string
                                (apo2bar (blanko2underbar (info "VTI" nivo-0)))
                                "-" kurz-datum ".mp4")))
         (raw-cmd  (concatenate 'string  "wget -c " url " -O " file-name))
         )
    (format t "~&* TITEL : ~S" (info "VTI" nivo-0))
    (format t "~&* AIRED : ~A - ~A" (info "VDA" nivo-0)
            (info "VRU" nivo-0))
    (format t "~&* CASE  : ~A" (info "caseProgram" nivo-0))
    (format t "~&* INFO  : ~A" (info "infoProg" nivo-0))
    (format t "~&* KURZ  : ~S" (ASCIIFY (info "V7T" nivo-0)))
    (format t "~&* BES   : ~S" (info "VDE" nivo-0))
    (format t "~&* MODES : ~A" (alexandria:hash-table-keys (info "VSR" nivo-0 )))
    (format t "~&* CMD  :")
    (format t "~& ~A" raw-cmd)    ))

(defun arte-get (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
         (url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (alexandria:ensure-gethash "VS5" (info "VST" nivo-0)))
         (file-name (ASCIIFY
                     (concatenate 'string
                                  (apo2bar (blanko2underbar (info "VTI" nivo-0)))
                                  "-" kurz-datum ".mp4")))
         (raw-cmd  (concatenate 'string  "wget --progress=dot:mega -c " url " -O " file-name))
         )
    (format t "~& ~A" url)
    (format t "~& =>")
    (format t "~& ~A" file-name)
    (format t "~& ~A" raw-cmd)
;    (run-program "/usr/local/bin/wget" raw-cmd :wait nil)
    ))

(defmacro arte-info-m (nmr6-nmr3) 
  `(let ((nmr  (symbol-name ',nmr6-nmr3)))
     (arte-info nmr)))

(defmacro arte-get-m (nmr6-nmr3)
  `(let ((nmr (symbol-name ',nmr6-nmr3)))
     (arte-get nmr)))

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

;; (defun arte (nmr)
;;   (let ((res (arte-info nmr)))
;;     (wget (car res) (cadr res))))

;; ** DONE filename zv datum.
;; ** TODO fur shell / clisp, sbcl
;; ** TODO Unicode suppport als file-name
(defun ASCIIFY (x)
  "bypass"
  x)
(cwd #P"~/arte7")


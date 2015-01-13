;#!/usr/local/bin/sbcl --noinform 

(ql:quickload "yason")
(ql:quickload "drakma")
(setf drakma:*header-stream* nil)


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
;; ele
;; "videoJsonPlayer" -> 
;; VTI : titel
;; VDA : aired
;; VRU : bis gultig
;; VDE : beschreibung
;; V7T : kurz besch.
;; VSR 's key : video modes
;; (alexandria:hash-table-keys (key-aus-json foojson "VSR"))
;; kurz datum
;; (ALEXANDRIA:ensure-gethash "VS5" (VALUE-AUS-JSON foojson "VST"))

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr))))
    (format t "~&* TITEL : ~S" (info "VTI" nivo-0))
    (format t "~&* AIRED : ~S" (info "VDA" nivo-0))
    (format t "~&* BIS   : ~S" (info "VRU" nivo-0))
    (format t "~&* WAS   : ~S" (info "V7T" nivo-0))
    (format t "~&* INFO  : ~S" (info "infoProg" nivo-0))
    (format t "~&* BES   : ~S" (info "VDE" nivo-0))
    (format t "~&* MODES : ~S" (alexandria:hash-table-keys (info "VSR" nivo-0 )))))

(defun arte-get (nmr)
  (let* ((nivo-0 (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
         (url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (alexandria:ensure-gethash "VS5" (info "VST" nivo-0)))
         (file-name (ASCIIFY
                     (concatenate 'string
                                  (apo2bar (blanko2underbar (info "VTI" nivo-0)))
                                  "-" kurz-datum ".mp4")))
         (wget-cmd (list "-c" url "-O" file-name)))
    (format t "~& ~A" url)
    (format t "~& =>")
    (format t "~& ~A" file-name)
    (format t "~& ~A" wget-cmd)
    (sb-ext:run-program "/usr/local/bin/wget" wget-cmd :wait nil)
    ))

(defmacro arte-info-m (nmr6-nmr3) 
  `(let ((nmr  (symbol-name ',nmr6-nmr3)))
     (arte-info nmr)))

(defun arte-get-m (nmr6-nmr3)
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

#+:SBCL
(defun cwd (dir)
  (sb-posix:chdir dir))

(defun getcwd ()
  #+SBCL (sb-unix:posix-getcwd)
  #+CCL (current-directory))

(cwd "/Users/dvnmk/Desktop")

;;(load "asciify.lisp")


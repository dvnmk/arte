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

(defun info (key)
  (alexandria:ensure-gethash key *nivo*))

(defun arte-info (nmr)
  (defparameter *nivo* (alexandria:ensure-gethash "videoJsonPlayer"(nmr2json nmr)))
  (format t "~&* Titel : ~S" (info "VTI"))
  (format t "~&* Aired : ~S" (info "VDA"))
  (format t "~&* Bis   : ~S" (info "VRU"))
  (format t "~&* Kurz.Bes : ~S" (info "V7T"))
  (format t "~&* Bes : ~S" (info "VDE"))
  (format t "~&* Modes : ~S" (alexandria:hash-table-keys (info "VSR")))
  )

(defun arte-get (nmr)
  (defparameter *nivo* (alexandria:ensure-gethash "videoJsonPlayer" (nmr2json nmr)))
  (let* ((url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (info "VSR"))))
         (kurz-datum (alexandria:ensure-gethash "VS5" (info "VST")))
         (file-name (concatenate 'string
                                 (apo2bar (blanko2underbar (info "VTI")))
                                 kurz-datum
                                 ".mp4"))
         (wget-cmd (list "-c" url "-O" file-name)))
    (format t "~& ~A" url)
    (format t "~& =>")
    (format t "~& ~A" file-name)
    (princ wget-cmd)
    (sb-ext:run-program "/usr/local/bin/wget" wget-cmd :wait nil)))

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


(defmacro no-quote (string)
  `(symbol-name ',string))

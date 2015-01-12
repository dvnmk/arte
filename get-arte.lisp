#!/usr/local/bin/sbcl --noinform 

(ql:quickload "yason")
(ql:quickload "drakma")
(setf drakma:*header-stream* nil)

(defun get-json (nmr)
  (let* ((url 
         (concatenate 'string
                      "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                      nmr
                      "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request url))))
    (yason:parse vec) ))

(defun url-y-titel (jsn)
  (let ((url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (alexandria:ensure-gethash "VSR"                                                                       (alexandria:ensure-gethash "videoJsonPlayer" jsn)))))
        (titel (alexandria:ensure-gethash "VTI" (alexandria:ensure-gethash "videoJsonPlayer" jsn))))
    (list url (apo2bar (blanko2underbar titel)))))

;; QUALITY = LQ, MQ, EQ, SQ where LQ < MQ < EQ < SQ
;; 		SQ = 720p 1280x720 bitrate 2200 (HD)
;; 		EQ = 400p 720x406 bitrate 1500
;; 		MQ = 400p 720x406 bitrate 800
;; 		LQ = 220p 320x200 bitrate 300

(defun arte-info (nmr)
  (url-y-titel (get-json nmr)))

(defun blanko2underbar (string)
  (cl-ppcre:regex-replace-all " " string "_"))

(defun apo2bar (string)
  (cl-ppcre:regex-replace-all "'" string "-"))

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

(defun gogo (nmr)
  (let* ((info (arte-info nmr))
         (url (car info))
         (titel (cadr info))
         (wget-cmd (list "-c" url "-O" (concatenate 'string titel ".mp4"))))
    (princ wget-cmd)
    ;; (run-program "/usr/local/bin/wget" wget-cmd
    ;;                 :wait nil
    ;;                                     ;  :output *standard-output*
    ;;                 )
    ))


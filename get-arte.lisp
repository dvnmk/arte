(ql:quickload "yason") ;json
(ql:quickload "drakma") ;curl
(setf drakma:*header-stream* nil)
(ql:quickload "trivial-shell") ;wget
;;(ql:quickload "cl-ppcre") ;blanko2_

(defun get-json (nm)
  (let* ((url 
         (concatenate 'string
                      "http://arte.tv/papi/tvguide/videos/stream/player/D/"
                      nm
                      "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request url))))
    (yason:parse vec) ))

(defun get-url-y-titel (jsn)
  (let ((url (alexandria:ensure-gethash "url" (alexandria:ensure-gethash "HTTP_MP4_SQ_1" (alexandria:ensure-gethash "VSR"                                                                       (alexandria:ensure-gethash "videoJsonPlayer" jsn)))))
        (titel (alexandria:ensure-gethash "VTI" (alexandria:ensure-gethash "videoJsonPlayer" jsn))))
    (list url (apo2bar (blanko2underbar titel)))))

(defun arte-info (nm)
  (get-url-y-titel (get-json nm)))

(defun blanko2underbar (string)
  (cl-ppcre:regex-replace-all " " string "_"))

(defun apo2bar (string)
  (cl-ppcre:regex-replace-all "'" string "-"))

(defun wget-faulty (url output-name)
  (with-open-file (my-stream (concatenate 'string output-name ".mp4")
                             :direction :output
                             :element-type '(unsigned-byte 8)
                             :if-does-not-exist :create
                             :if-exists :supersede)
    (let ((content (drakma:http-request url)))
      (loop for i across content do
           (write-byte i my-stream)))))

(defun arte (nm)
  (let ((res (arte-info nm)))
    (wget (car res) (cadr res))))

(defun arte-bash (nm)
  (let* ((res (arte-info nm))
         (cmd (concatenate 'string "wget" " -q " (car res)
                           " -O " (concatenate 'string (cadr res)
                                               "mp4"))))
    (trivial-shell:shell-command cmd)))


(arte-info "042374-000")

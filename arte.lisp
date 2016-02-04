;; (arte) dvnmk 2015

(in-package #:arte)

(defvar *app-dir* #P"~/arte")
;; (load "asciify.lisp")
(setf drakma:*header-stream* nil)
(defvar *speicher-dir* #P"~/arte7/")

(defparameter *tmp* nil)
(defparameter *prozess* nil)

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
    #+gcl (si:chdir dir)
    #+lispworks (hcl:change-directory dir)
    #+openmcl (ccl:cwd dir)
    #+sbcl (sb-posix:chdir dir)
    (setq cl:*default-pathname-defaults* dir))
   (t
    (let ((dir
       #+allegro (excl:current-directory)
       #+clisp (#+lisp=cl ext:default-directory #-lisp=cl lisp:default-directory)
       #+(or cmu scl) (ext:default-directory)
       #+cormanlisp (ccl:get-current-directory)
       #+lispworks (hcl:get-working-directory)
       #+mcl (ccl:mac-default-directory)
       #+sbcl (sb-unix:posix-getcwd/)
       #-(or allegro clisp cmu scl cormanlisp mcl sbcl lispworks) (truename ".")))
      (when (stringp dir)
    (setq dir (parse-namestring dir)))
      dir))))

(cd *speicher-dir*)

(defun nmr2json (nmr)
  (let* ((json-url (concatenate
		    'string
		    "http://arte.tv/papi/tvguide/videos/stream/player/D/"
		    nmr
		    "_PLUS7-D/ALL/ALL.json"))
         (vec (flexi-streams:octets-to-string (drakma:http-request json-url)
                                              :external-format :utf-8)))
    (yason:parse vec)))

(defun normalisieren (string)
  (flet ((slash-2-.s (x)
           (cl-ppcre:regex-replace-all "/" x ".s"))
         (apo-2--2-bar (x)
           (cl-ppcre:regex-replace-all "’" x "-"))
         (apo-2-bar (x)
           (cl-ppcre:regex-replace-all "'" x "-"))
         (blanko-2-underbar (x)
           (cl-ppcre:regex-replace-all " " x "_"))
         (colon-2-o (x)
           (cl-ppcre:regex-replace-all ":" x "_"))
         (and-2-y (x)
           (cl-ppcre:regex-replace-all "&" x "y")))
    (asciify (and-2-y
	      (colon-2-o
	       (slash-2-.s
		(apo-2--2-bar
		 (apo-2-bar (blanko-2-underbar string)))))))))

(defun info (key tbl)
  (alexandria:ensure-gethash key tbl))

(defun arte-info (nmr)
  (let* ((nivo-0 (info "videoJsonPlayer" (nmr2json nmr)))
         (url (info "url" (info "HTTP_MP4_SQ_1" (info "VSR" nivo-0))))
         (kurz-datum (subseq (info "VS5" (info "VST" nivo-0))
                             0 4))
         (file-name (concatenate 'string
                                 (normalisieren (info "VTI" nivo-0))
                                 "-" kurz-datum
                                 "-" (info "genre" nivo-0)))
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
      (with-open-file (out (format nil "~A~A.txt" *speicher-dir*
				   (getf *tmp* :titl))
;; (concatenate 'string "~/arte7/" file-name ".txt")
                           :direction :output
                           :if-exists :supersede
                           :external-format :unix)
        (format out "~{*~A ~8T~A~%~}" res)))
    t))

(defun arte-nimm (nmr)
  (arte-info nmr)
  (let* ((cmd (format nil "wget -c ~A -O ~A.mp4 --no-verbose -a ~A.txt --tries=4"
                     (getf *tmp* :file)(getf *tmp* :titl) (getf *tmp* :titl)))
        (proz (ccl:run-program "/bin/sh" (list "-c" cmd)
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
    (format t "~&~2,D ~S ~% ~A ~A ~A ~%"
            n titl id (ccl:external-process-id foo) (ccl:external-process-status foo))))

(defun check ()
  (do ((i (length *prozess*) (- i 1)))
      ((zerop i) t)
    (check-nth (- i 1))))

(defun arte-guck (nmr)
  (arte-info nmr)
  (let ((cmd (format nil "mplayer -really-quiet -cache 10240 ~A"
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

(defun url-to-n (url)
  "http://www.arte.tv/guide/de/058313-015-A/
berlin-live-dave-stewart?autoplay=1 > 058313-015"
  (string-right-trim "-"
		     (cl-ppcre:scan-to-strings "[^b]*-"
				      (nth 5 (cl-ppcre:split "/" url)))))

;; house:
(defparameter *server* (bordeaux-threads:make-thread (lambda () (house:start 8888))))
 
(house:define-handler (i :content-type "text/html") ((u :string))
  (let ((n (url-to-n u)))
    (progn
      (arte-info n)
      (cl-who:with-html-output-to-string (*standard-output* nil
							    :prologue t
							    :indent t)
	(:html (:head (:title (format t "(ARTE-INFO ~s)" n)))
	       (:body :bgcolor "violet"
		      (:h1 (format t "~A" (nth 1 *tmp*)))
		      (:h2 (format t "~A" (nth 3 *tmp*)))
		      (:h2 (format t "~A" (nth 5 *tmp*)))
		      (:h2 (format t "~A" (nth 7 *tmp*)))
		      (:h1 (:a :href (nth 9 *tmp*) "(guck)"))
		      (:h1 (:a :href (format nil "./n?n=~A" n) "(nimm)"))
		      (:h1 (:a :href "./c" "(check)"))))))))


(house:define-handler (i :content-type "text/html") ((n :string))
  (progn
    (arte-info  n)
    (cl-who:with-html-output-to-string (*standard-output* nil
							  :prologue t
							  :indent t)
      (:html
       (:head
        (:title (format t "(ARTE-INFO ~A)" n)))
       (:body :bgcolor "violet"
              (:h1 (format t "~A" (nth 1 *tmp*)))
              (:h2 (format t "~A" (nth 3 *tmp*)))
              (:h2 (format t "~A" (nth 5 *tmp*)))
              (:h2 (format t "~A" (nth 7 *tmp*)))
              (:h1 (:a :href (nth 9 *tmp*) "(guck)"))
              (:h1 (:a :href (format nil "./n?n=~A" n) "(nimm)"))
              (:h1 (:a :href "./c" "(check)")))))))

(house:define-handler (n :content-type "text/html") ((n :string))
  (progn
    (arte-nimm  n)
    (cl-who:with-html-output-to-string (*standard-output* nil
							  :prologue t
							  :indent t)
      (:html
       (:head
        (:title (format t "(ARTE-NIMM ~A)" n)))
       (:body :bgcolor "violet"
              (:h1 (format t "~A" (nth 1 *tmp*)))
              (:h2 (format t "~A" (nth 3 *tmp*)))
              (:h2 (format t "~A" (nth 5 *tmp*)))
              (:h2 (format t "~A" (nth 7 *tmp*)))
              (:h1 (:a :href (nth 9 *tmp*) "(guck)"))
              (:h1 (:a :href "./c" "(check)"))             
              )))))

(house:define-handler (c :content-type "text/plain") ()
  (format nil "~{~A~}" *prozess*))


;; (house:define-handler (c :content-type "text/plain") ()
;;   (format nil "~A" (check-nth 1)))

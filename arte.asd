;;;; arte.asd

(asdf:defsystem #:arte
  :description "Describe arte here"
  :author "dvnmk <divinomko@gmail.com>"
  :license "Specify license here"
  :serial t
  :depends-on (#:cl-who #:yason #:drakma #:hunchentoot)
  :components (
	       (:file "package")
	       (:file "asciify")
               (:file "arte")))


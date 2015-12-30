;;;; arte.asd

(asdf:defsystem #:arte
  :description "Describe arte here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :serial t
  :depends-on (#:cl-who #:yason #:drakma #:house)
  :components (
	       (:file "package")
	       (:file "asciify")
               (:file "arte")))


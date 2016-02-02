 ;;;----------------------------------------------------------------------------
;;;
;;; $Source$
;;; $Id$
;;;
;;; (c) Copyright 9/10/2002-2007 Don Geddis.  No rights reserved.
;;; Released into the public domain 2007-06-28 by Don Geddis.
;;;
;;;----------------------------------------------------------------------------
;;;
;;; ASCIIFY
;;;
;;; Convert a string with European accented characters, into "equivalent"
;;; 7-bit ASCII (A-Z,a-z).
;;;
;;; Original code by Arthur Lemmens <alemmens@xs4all.nl>.
;;; Improved (multi-char rewriting) by Paul Foley <mycroft@actrix.gen.nz>.
;;; Additional character mappings by:
;;;	Gisle Sælensminde <gisle@apal.ii.uib.no>
;;;	Nils Goesche <cartan@cartan.de>
;;;	Hannah Schroeter <hannah@schlund.de>
;;; Final assembly by Don Geddis <don@geddis.org>.
;;;
;;; Implemented in ANSI Common Lisp.
;;;
;;; Code available from
;;;	http://don.geddis.org/lisp/asciify.lisp
;;;
;;; Original comp.lang.lisp Usenet newsgroup discussion at
;;;	http://groups.google.com/groups?threadm=m3n0qrkj5d.fsf%40maul.geddis.org
;;;
;;;----------------------------------------------------------------------------
;;;
;;; Examples:
;;; USER> (asciify "José árbol niño")
;;; "Jose arbol nino"
;;; USER> (asciify "¡no!" :default :skip)
;;; "no!"
;;; USER> (asciify "¡no!" :default #\!)
;;; "!no!"
;;;
;;; [Note: the last example no longer works, because "¡" is now part of the
;;;  built-in map.  But it should work for some other unknown character.]
;;;
;;;----------------------------------------------------------------------------
(in-package :arte)
(defparameter *accent-rewrites*
  '(
    ("áàâã" . #\a)
    ("ÁÀÂÃ" . #\A)
    ("å"    . "aa")
    ("Å"    . "Aa")
    ("äæ"   . "ae")
    ("ÄÆ"   . "Ae")
    ("ß"    . "ss")
    ("ç"    . #\c)
    ("Ç"    . #\C)
    ("ëéèê" . #\e)
    ("ËÉÈÊ" . #\E)
    ("ïíìî" . #\i)
    ("ÏÍÌÎ" . #\I)
    ("ñ"    . #\n)
    ("Ñ"    . #\N)
    ("óòôõ" . #\o)
    ("ÓÒÔÕ" . #\O)
    ("öø"   . "oe")
    ("Ö"    . "Oe")
    ("ðþ"   . "th")
    ("ÐÞ"   . "Th")
    ("úùû"  . #\u)
    ("ÚÙÛ"  . #\U)
    ("ü"    . "ue")
    ("Ü"    . "Ue")
    ("ý"    . #\y)
    ("ÿ"    . "ij")
    ("Ý"    . #\Y)
    ("¡¿"   . :skip)
 
    ))

;;;----------------------------------------------------------------------------

(defun asciify (string &key (default :skip))
  "Returns a string containing only 7-bit ASCII characters.  Non-ASCII
characters in the input string will be replaced by something resembling the
original, if possible.  Otherwise, they will be replaced by DEFAULT; or
removed, when DEFAULT is :SKIP; or left as is, when DEFAULT is NIL."

  (with-output-to-string (result)
     (loop for char across string
	   if (char<= char #\Rubout)
	   do
	   (write-char char result)
	   else do
	   (let ((replacement
		  (or (cdr (assoc char *accent-rewrites* :test #'position ))
		      default
		      char ))) ; keep it if DEFAULT is NIL
	     (unless (eq replacement :skip)
	       (princ replacement result) )
	     ))))

;;;----------------------------------------------------------------------------

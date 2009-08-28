(require :sb-bsd-sockets)
(defpackage :serv
  (:use :cl :sb-bsd-sockets))
(in-package :serv)

(defvar s (make-inet-socket :stream :tcp))
(setf (sockopt-reuse-address s) t)
(socket-bind s (make-inet-address "127.0.0.1") 8080)
(socket-listen s 5)
(format t "stream open~%")
(defvar sm (socket-make-stream (socket-accept s)
			      :output t
			      :input t
			      :external-format :default
			      :element-type 'character
			      :buffering :none)) 
(defvar a (make-string 10))
(read-sequence a sm)
(format t "~a~%" a)
(defvar cont "<html><body>hello world</body></html>")
; 200 means Ok, request fullfilled document follows
(format sm "HTTP/1.1 200~%Content-type: text/html~%Content-Length: ~a~%~%~a~%" (length cont) cont)
#|
(socket-close s) 
|#
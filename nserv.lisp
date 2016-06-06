(require :sb-bsd-sockets)


(defpackage :nserv
  (:use :cl :sb-bsd-sockets))
(in-package :nserv)

(defparameter *s* (make-instance 'inet-socket :type :stream :protocol :tcp))

(setf (non-blocking-mode *s*) t)
(setf (sockopt-reuse-address *s*) t)

(socket-bind *s* (make-inet-address "127.0.0.1") 8888)

(socket-listen *s* 5)

#+nil
(socket-close *s*)

(defparameter *str*
 (socket-make-stream (socket-accept *s*)
		     :output t
		     :input t
		     :element-type 'character
		     :buffering :none))

(when (listen *str*)
  (read-line *str*))

(format *str* "HTTP/1.1 200 OK~%Content-type: text/html~%~%")
(format *str* "<html><body>huhu</body></html>")
(close *str*)

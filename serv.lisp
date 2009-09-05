
(require :sb-bsd-sockets)
(defpackage :serv
  (:use :cl :sb-bsd-sockets))
(in-package :serv)

(declaim (optimize (speed 0) (safety 3) (debug 3)))

(defparameter cont "<html>
<body>
hello <a href=\"test.html\">world</a>
<script type=\"text/javascript\">
<!--
var c=new XMLHttpRequest();
c.onreadystatechange=function(){
  if(this.readyState == 2)
    print(c.getResponseHeader(\"Content-type\"));
}
c.open(\"GET\",\"test.txt\");
c.send(\"127.0.0.1\");
//-->
</script>
</body>
</html>")  

(defun init-serv ()
  (let ((s (make-inet-socket :stream :tcp)))
    (setf (sockopt-reuse-address s) t)
    (socket-bind s (make-inet-address "127.0.0.1") 8080)
    (socket-listen s 5)
    s))

(defun read-get-request (sm)
  (loop for line = (read-line sm)
	while line
	do (let ((index (search "GET" line)))
	     (when index
	       (return-from read-get-request
		 (let ((start (+ index 1 (length "GET"))))
		   (subseq line
			 start
			 (search " " line :start2 start)))))))
  (error "no GET found in request"))

(defun handle-connection (s)
  (let ((sm (socket-make-stream (socket-accept s)
				:output t
				:input t
				:element-type 'character
				:buffering :none)))
    
    ;;(read-sequence a sm)
    (format t "~a~%" (read-get-request sm)) 
    ;; 200 means Ok, request fullfilled document follows
    (format sm "HTTP/1.1 200 OK~%Content-type: text/html~%Content-Length: ~a~%~%~a~%" 
	    (length cont) cont)
    (close sm)))

;(get-internal-real-time)

;#|
(defvar s (init-serv))
(loop
 (handle-connection s))
(socket-close s) 
;|#


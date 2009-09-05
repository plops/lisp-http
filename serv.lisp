
(require :sb-bsd-sockets)
(require :cl-who)
(defpackage :serv
  (:use :cl :sb-bsd-sockets :cl-who))
(in-package :serv)

(declaim (optimize (speed 0) (safety 3) (debug 3)))



(defparameter cont "
<script type=\"text/javascript\">
<!--
function httpSuccess(r){
  try{
    return (r.status>=200 && r.status<300) || // anything in 200 range is good
            r.status==304; // from browser cache
  } catch(e){}
  return false;
}
function httpData(r,type){
  var ct=r.getResponseHeader(\"content-type\");
  var data=!type && ct && ct.indexOf(\"xml\") >=0;
  data=type == \"xml\" || data ? r.responseXML : r.responseText;
  if(type==\"script\")
    eval.call(window,data);
  return data;
}
window.onload=function(){
var c=new XMLHttpRequest();
c.onreadystatechange=function(){
  if(c.readyState==4){
   if(httpSuccess(c)){
    var s=document.getElementById(\"feed\");
    s.innerHTML=c.responseText;
   }
   c=null; 
  }
}
c.open(\"GET\",\"test.txt\");
c.send(\"127.0.0.1\");
}
//-->
</script>")  

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
    (let ((r (read-get-request sm)))
      (format t "~a~%" r) 
      ;; 200 means Ok, request fullfilled document follows
      (format sm "HTTP/1.1 200 OK~%Content-type: text/html~%~%")
      (cond ((string= r "/") 
	     (with-html-output (sm)
	       (htm (:html
		     (:body
		      (:div :id "feed"
			    (str (format nil "~a" (get-internal-real-time)))))
		     (str cont))))) 
	    ((string= r "/test.txt")
	     (format sm "<b>~a</b>" (get-internal-real-time)))
	    (t (format sm "error")))
      
      (close sm))))


;#|
(defvar s (init-serv))
(loop
 (handle-connection s))
(socket-close s) 
;|#


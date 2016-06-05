#+nil
(eval-when (:compile-toplevel)
  (ql:quickload :cl-who)
  (require :sb-bsd-sockets)
  (require :sb-concurrency)
  (require :cl-who))
(defpackage :serv
  (:use :cl :sb-bsd-sockets :cl-who))
(in-package :serv)

(declaim (optimize (speed 0) (safety 3) (debug 3)))


(defun read-ways ()
  (with-open-file (s "coords")
    (loop for line = (read-line s nil nil)
	  while line
	  collect
	  (cond ((= 1 (length line)) 'way)
		(t (multiple-value-bind (first st)
		       (read-from-string line) 
		     (list (* (- first 51.502) 100 200)
			   (* (+ (read-from-string (subseq line st)) 0.090) 100 200))))))))

(defun draw-ways (ways sm)
  (loop with j = 0  ;; start counting points in each way
	and k = 0 ;; count the ways
	for coords in ways
	;while (< k 3)
	do
	(cond ((eq coords 'way) 
	       (unless (= 0 k)
		 (format sm "q.stroke();~%"))
	       (format sm "q.beginPath(~a);~%" k)
	       (setf k (1+ k))
	       (setf j 0))
	      (t
	       (if (= 0 j)
		 (format sm "q.moveTo(~a,~a);~%" (first coords) (second coords))
		 (format sm "q.lineTo(~a,~a);~%" (first coords) (second coords)))
	       (setf j (1+ j)))))
  (format sm "q.stroke();~%"))

(defparameter cont1 "
<script type='text/javascript'>
<!--
function httpSuccess(r){
  try{
    return (r.status>=200 && r.status<300) || // anything in 200 range is good
            r.status==304; // from browser cache
  } catch(e){}
  return false;
}
function draw(){
  var q=document.getElementById('canvas').getContext('2d');
  q.save();
   q.clearRect(0,0,400,400);
   q.strokeStyle='black';
   q.lineWidth=1;
   q.save();")

(defparameter cont2 "
   q.restore();
  q.restore();
}
window.onload=function(){
var source = new EventSource('event');
source.addEventListener('message',function(e){
//  console.log(e.data);
  var s=document.getElementById('feed');
  s.innerHTML=e.data;
    },false);
var c=new XMLHttpRequest();
c.onreadystatechange=function(){
  if(c.readyState==4){
   if(httpSuccess(c)){
    var s=document.getElementById('feed');
    s.innerHTML=c.responseText;
    //draw();
   }
   c=null; 
  }
}
c.open('GET','test.txt');
c.send('127.0.0.1');
}
//-->
</script>")  

(defun init-serv ()
  (let ((s (make-instance 'inet-socket :type :stream :protocol :tcp)))
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

(defparameter *pusher-mb* (sb-concurrency:make-mailbox))


#+nil
(dotimes (k 1000)
  (sleep .01)
  (sb-concurrency:send-message
   *pusher-mb*
   (with-output-to-string (sm)
     (with-html-output (sm)
       (:table
	(loop for i below 25 by 5 do
	     (htm (:tr
		   (loop for j from i below (+ i 5)
		      do
			(htm (:td
			      (if (= j 11)
				  (htm (:font :color "red"
					      (fmt "~a" (get-internal-run-time))))
				  (fmt "~a" k)))))))))))))

(let ((old-msg ""))
 (defun pusher-kernel (sm)
   (when *pusher-mb*
     (format sm "data: ~a~C~C~C~C"
	     (let ((msg (sb-concurrency:receive-message *pusher-mb* :timeout 1)))
	       (if msg
		   (setf old-msg msg)
		   (format nil "<b>no update</b>~a" old-msg)))
	     #\return #\linefeed #\return #\linefeed))))


(defun pusher (sm)
  (format sm "HTTP/1.1 200 OK~%Content-type: text/event-stream~%~%")
  (loop for i below 10000 do
       (pusher-kernel sm))
  (close sm))

(defun handle-connection (s)
  (let ((sm (socket-make-stream (socket-accept s)
				:output t
				:input t
				:element-type 'character
				:buffering :none)))
    
    ;;(read-sequence a sm)
    (let ((r (read-get-request sm))
	  (cont (concatenate 'string 
			     cont1 
			     (with-output-to-string (stream)
			       (draw-ways (read-ways) stream))
			     cont2)))
      (format t "~a~%" r) 
      ;; 200 means Ok, request fullfilled document follows
      
      (cond ((string= r "/") 
	     (format sm "HTTP/1.1 200 OK~%Content-type: text/html~%~%")
	     (with-html-output (sm)
	       (htm (:html
		     (:body
		      (:div :id "feed"
			    (str (format nil "~a" (get-internal-real-time))))
		      (:canvas :id "canvas" :height 150 :width 150))
		     (str cont))))
	     (close sm)) 
	    ((string= r "/test.txt")
	     (format sm "HTTP/1.1 200 OK~%Content-type: text/html~%~%")
	     (format sm "<b>~a</b>" (get-internal-real-time))
	     (close sm))
	    ((string= r "/event")
	     (sb-thread:make-thread 
	      #'(lambda ()
		  (pusher sm))
	      :name "pusher"))
	    (t (format sm "error")
	       (close sm))))))


#+nil
(defvar s (init-serv))
#+nil
(sb-thread:make-thread
 #'(lambda ()
     (loop
	(handle-connection s)))
 :name "handle-connection")
#+nil
(socket-close s) 

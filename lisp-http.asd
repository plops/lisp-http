(asdf:defsystem lisp-http
    :version "0"
    :description "Simple Common Lisp HTTP server with send event support."
    :maintainer " <martin@localhost>"
    :author " <martin@localhost>"
    :licence "GPL"
    :depends-on (sb-concurrency sb-bsd-sockets cl-who)
    :serial t
    ;; components likely need manual reordering
    :components ((:file "serv"))
    ;; :long-description ""
    )

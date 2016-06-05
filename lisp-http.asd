(asdf:defsystem lisp-http
    :version "0"
    :description "Simple Common Lisp HTTP server with send event support."
    :maintainer " <martin@localhost>"
    :author " <martin@localhost>"
    :licence "GPL"
    :depends-on (sb-concurrency sb-threads sb-bsd-sockets)
    :serial t
    ;; components likely need manual reordering
    :components ((:file "serv"))
    ;; :long-description ""
    )

;; [[file:ox-canvashtml.org::*Requirements][Requirements:1]]
(require  'ox-html)
;; Requirements:1 ends here

;; [[file:ox-canvashtml.org::*Add a link type for internal canvas links][Add a link type for internal canvas links:1]]
;;; ol-canvas.el - Support for links to man pages in Org mode
;; Add a link type for internal canvas links:1 ends here

;; [[file:ox-canvashtml.org::*define the derived backend][define the derived backend:1]]
(org-export-define-derived-backend 'canvas-html 'html
  :translate-alist '((template . canvas-html-template)
                     (inner-template . org-canvas-html-inner-template)
                     (section . org-canvas-html-section)
                     (headline . org-canvas-html-headline))
    :menu-entry
  '(?2 "Export to HTML"
       ((?H "As HTML buffer" org-canvas-html-export-as-html)
	(?h "As HTML file" org-canvas-html-export-to-html)
	(?o "As HTML file and open"
	    (lambda (a s v b)
	      (if a (org-canvas-html-export-to-html t s v b)
		(org-open-file (org-canvas-html-export-to-html nil s v b)))))))

  )
;; define the derived backend:1 ends here

;; [[file:ox-canvashtml.org::*Replace the section function][Replace the section function:1]]
;;;; Section

(defun org-canvas-html-section (section contents info)
  "Transcode a SECTION element from Org to HTML.
CONTENTS holds the contents of the section.  INFO is a plist
holding contextual information."
  (let ((parent (org-export-get-parent-headline section)))
    ;; Before first headline: no container, just return CONTENTS.
    (if (not parent) contents
      ;; Get div's class and id references.
      (let* ((class-num (+ (org-export-get-relative-level parent info)
			   (1- (plist-get info :html-toplevel-hlevel))))
	     (section-number
	      (and (org-export-numbered-headline-p parent info)
		   (mapconcat
		    #'number-to-string
		    (org-export-get-headline-number parent info) "-"))))
        ;; Build return value.
        (if (org-element-property :CANVAS_NO_INNERDIV parent)
            (format "%s\n" (or contents ""))    
	  (format "<div class=\"outline-text-%d\" id=\"text-%s\">\n%s</div>\n"
		  class-num
		  (or (org-element-property :CUSTOM_ID parent)
		      section-number
		      (org-export-get-reference parent info))
		  (or contents "")))))))
;; Replace the section function:1 ends here

;; [[file:ox-canvashtml.org::*Define some options here][Define some options here:1]]

;; [[file:ox-canvashtml.org::*Unfortunately, have to replace the headline function too :-(][Unfortunately, have to replace the headline function too :-(:1]]
;;;; Headline

(defun org-canvas-html-headline (headline contents info)
  "Transcode a HEADLINE element from Org to HTML.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((numberedp (org-export-numbered-headline-p headline info))
           (numbers (org-export-get-headline-number headline info))
           (level (+ (org-export-get-relative-level headline info)
                     (1- (plist-get info :html-toplevel-hlevel))))
           (todo (and (plist-get info :with-todo-keywords)
                      (let ((todo (org-element-property :todo-keyword headline)))
                        (and todo (org-export-data todo info)))))
           (todo-type (and todo (org-element-property :todo-type headline)))
           (priority (and (plist-get info :with-priority)
                          (org-element-property :priority headline)))
           (text (org-export-data (org-element-property :title headline) info))
           (tags (and (plist-get info :with-tags)
                      (org-export-get-tags headline info)))
           (full-text (funcall (plist-get info :html-format-headline-function)
                               todo todo-type priority text tags info))
           (contents (or contents ""))
	   (id (org-html--reference headline info))
	   (formatted-text
	    (if (plist-get info :html-self-link-headlines)
		(format "<a href=\"#%s\">%s</a>" id full-text)
	      full-text)))
      (if (org-export-low-level-p headline info)
          ;; This is a deep sub-tree: export it as a list item.
          (let* ((html-type (if numberedp "ol" "ul")))
	    (concat
	     (and (org-export-first-sibling-p headline info)
		  (apply #'format "<%s class=\"org-%s\">\n"
			 (make-list 2 html-type)))
	     (org-html-format-list-item
	      contents (if numberedp 'ordered 'unordered)
	      nil info nil
	      (concat (org-html--anchor id nil nil info) formatted-text)) "\n"
	     (and (org-export-last-sibling-p headline info)
		  (format "</%s>\n" html-type))))
	;; Standard headline.  Export it as a section.
        (let ((extra-class
	       (org-element-property :HTML_CONTAINER_CLASS headline))
	      (headline-class
	       (org-element-property :HTML_HEADLINE_CLASS headline))
              (first-content (car (org-element-contents headline))))
          (format "<%s id=\"%s\" class=\"%s\">%s%s</%s>\n"
                  (org-html--container headline info)
                  (format "outline-container-%s" id)
                  (concat (format "outline-%d" level)
                          (and extra-class " ")
                          extra-class)
                  (format "\n<h%d id=\"%s\"%s>%s</h%d>\n"
                          level
                          id
			  (if (not headline-class) ""
			    (format " class=\"%s\"" headline-class))
                          (concat
                           (and numberedp
                                (format
                                 "<span class=\"section-number-%d\">%s</span> "
                                 level
                                 (concat (mapconcat #'number-to-string numbers ".") ".")))
                           formatted-text)
                          level)
                  ;; When there is no section, pretend there is an
                  ;; empty one to get the correct <div
                  ;; class="outline-...> which is needed by
                  ;; `org-info.js'.
                  (if (eq (org-element-type first-content) 'section) contents
                    (concat (org-canvas-html-section first-content "" info) contents))
                  (org-html--container headline info)))))))
;; Unfortunately, have to replace the headline function too :-(:1 ends here

;; [[file:ox-canvashtml.org::*Add the template functions][Add the template functions:1]]
(defun canvas-html-template (contents info)
  "Since <head> will in any case be stripped out,
return just the body with an extra CSS tag"
  ;; code statically for now
  (let* ((rawHtml  (concat ;;"<link rel=\"stylesheet\" type=\"text/css\" href=\"/home/matt/IFP100/extra-styles.css\" \\>\n "
                           ;; Document contents.
                           (let ((div (assq 'content (plist-get info :html-divs))))
                             (format "<%s id=\"%s\" class=\"%s\">\n"
                                     (nth 1 div)
                                     (nth 2 div)
                                     (plist-get info :html-content-class)))
                           ;; Document title.
                           (when (plist-get info :with-title)
                             (let ((title (and (plist-get info :with-title)
		                               (plist-get info :title)))
	                           (subtitle (plist-get info :subtitle))
	                           (html5-fancy (org-html--html5-fancy-p info)))
                               (when title
	                         (format
	                          (if html5-fancy
	                              "<header>\n<h1 class=\"title\">%s</h1>\n%s</header>"
	                            "<h1 class=\"title\">%s%s</h1>\n")
	                          (org-export-data title info)
	                          (if subtitle
	                              (format
	                               (if html5-fancy
		                           "<p class=\"subtitle\">%s</p>\n"
		                         (concat "\n" (org-html-close-tag "br" nil info) "\n"
			                         "<span class=\"subtitle\">%s</span>\n"))
	                               (org-export-data subtitle info))
	                            "")))))
                           contents
                           (format "</%s>\n" (nth 1 (assq 'content (plist-get info :html-divs))))
                           ))
         (tempFile (make-temp-file "canvas-html-export" nil ".html" rawHtml)))
    (call-process "juice" nil "*juice-process*" nil "--css" "/home/matt/IFP100/extra-styles.css" tempFile tempFile)
    (with-temp-buffer
      (insert-file-contents tempFile)
      (buffer-string))))

(defun org-canvas-html-inner-template (contents info)
  "Return body of document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (let* ((rawHtml
          (concat
           ;; Table of contents.
           (let ((depth (plist-get info :with-toc)))
             (when depth (org-html-toc depth info)))
           ;; Document contents.
           contents
           ;; Footnotes section.
           (org-html-footnote-section info)))
         (tempFile (make-temp-file "canvas-html-export" nil ".html" rawHtml)))
    (call-process "juice" nil "*juice-process*" nil "--css" "/home/matt/IFP100/extra-styles.css" tempFile tempFile)
    (with-temp-buffer
      (insert-file-contents tempFile)
      (buffer-string))))
;; Add the template functions:1 ends here

;; [[file:ox-canvashtml.org::*Add the export-to and export-as functions][Add the export-to and export-as functions:1]]
;;; End-user functions

;;;###autoload
(defun org-canvas-html-export-as-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org HTML Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'canvas-html "*Org HTML Export*"
    async subtreep visible-only body-only ext-plist
    (lambda () (set-auto-mode t)))
  ;; (save-excursion
  ;;   (set-buffer (get-buffer "*Org HTML Export*"))
  ;;   (call-process-region nil nil  "python" t t  (t nil)  nil "-m" "premailer"))
  )

;;;###autoload
(defun org-canvas-html-export-to-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a HTML file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension (concat
		     (when (> (length org-html-extension) 0) ".")
		     (or (plist-get ext-plist :html-extension)
			 org-html-extension
			 "html")))
	 (file (org-export-output-file-name extension subtreep))
	 (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'canvas-html file
      async subtreep visible-only body-only ext-plist)
    ;; (call-process "juice" nil "*juice-process*" nil file file)
    ;;file
    ))
;; Add the export-to and export-as functions:1 ends here

;; [[file:ox-canvashtml.org::*Provide the library][Provide the library:1]]
(provide 'ox-canvashtml)
;; Provide the library:1 ends here

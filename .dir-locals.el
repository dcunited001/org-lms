;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nil . ((fill-column . 78)
         (tab-width . 4)
         (sentence-end-double-space . t)))
 (org-mode

  ;; disable word-wrap for now
  (eval . (progn
            ;; cond falls through
            (if (local-variable-if-set-p 'word-wrap)
                (setq-local word-wrap 'nil))
            (if (local-variable-if-set-p '+word-wrap-mode)
                (setq-local word-wrap 'nil))))))

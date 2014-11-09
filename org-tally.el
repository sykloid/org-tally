;;; org-tally -- Lightweight gamification layer for org-mode.
;;; P.C Shyamshankar "sykora" <sykora@lucentbeing.com>

;;; Commentary:

;; org-tally is a lightweight gamification layer over org-mode's task management capabilities. It
;; provides functions to add incentives to tasks, tally the incentives in an org-mode file, and
;; report the results.

;;; Code:

(require 'org)
(require 'alist-utils)

(defgroup org-tally nil
  "Customization options for org-tally.")

(defcustom org-tally-property "TALLY"
  "The name of the property to store tally counts."
  :type '(string))

(defvar org-tally-totals nil)

(defun org-tally-skip ()
  "Return t if the entry at point is to be skipped for tally computation."
  (org-agenda-skip-entry-if 'nottodo 'done))

(defun org-tally-update-incentive (update)
  "Update the buffer total tally with `UPDATE'."
  (upsert-alist-with-default (car update) (cdr update) 0 + org-tally-totals))

(defun org-tally-update-entry ()
  "Update the buffer total tally with incentives from `UPDATE'."
  (mapc 'org-tally-update-incentive
        (car (read-from-string (org-entry-get (point) org-tally-property)))))

(defun org-tally-update-buffer ()
  "Update the buffer total tally with all entries."
  (interactive)
  (progn
    (set 'org-tally-totals nil))
    (org-map-entries 'org-tally-update-entry nil nil 'org-tally-skip)
    (message
     (concat "Totals: " (mapconcat (lambda (arg) (format "%d %s" (cdr arg) (car arg)))
                                   org-tally-totals ", "))))

(defun org-dblock-write:tally (params)
  "Org-mode dynamic block update function for tally blocks."
  (progn
    (org-tally-update-buffer)
    (save-excursion
      (insert "| Incentive | Total |\n")
      (insert (mapconcat (lambda (arg) (format "| %s | %d |" (car arg) (cdr arg))) org-tally-totals "\n"))
      (org-table-align))
    (org-table-insert-hline)
    (org-table-sort-lines t ?a)))

(defun org-tally-get-entry-tally ()
  "Get the current tally for entry at point, nil if there is no tally."
  (car (ignore-errors (read-from-string (org-entry-get (point) org-tally-property)))))

(defun org-tally-add-incentive (key value)
  "Prompt for a tally incentive to add to entry at point.

Will overwrite existing tally if one with the same name exists."
  (interactive "MIncentive: \nNValue: ")
  (let ((current (or (org-tally-get-entry-tally) '())))
    (upsert-alist key value current)
    (org-set-property org-tally-property (prin1-to-string current))))

(define-minor-mode org-tally-mode
  "Toggle org-tally mode.

Currently this mode provides basic key bindings; in the future,
it will provide lighter support for various tallies, among other
things.

Suggestions welcome!"

  :init-value nil
  :lighter " Tally"
  :keymap '(("\C-c\C-x#b" . org-tally-update-buffer)
            ("\C-c\C-x#i" . org-tally-add-incentive)))

(provide 'org-tally)

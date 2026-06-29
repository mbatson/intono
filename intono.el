;;; intono.el --- In(line) to(do) no(tes) for writing -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Matthew Batson

;; Author: Matthew Batson <mbatson@mbatson.net>
;; Created: 2026
;; Version: 1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: text

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Intono provides helper functions and (optionally) font-lock
;; highlighting for inline todo notes useful in the writing and
;; drafting of prose and poetry.
;;
;; An inline todo note for Intono's purposes is a markup construct
;; that by default begins with the text, `((TODO: ', and ends with
;; `))'. Between these two elements the user can insert any text they
;; want. This package provides functions to make the insertion and
;; deletion of such notes in a buffer easy and convenient. It also
;; provides a minor mode, `intono-mode', which highlights inline todo
;; notes with font-lock so that they are visually distinct from the
;; surrounding text.
;;
;; Inline todo notes do not need to be surrounded by whitespace, and
;; in fact it is better if they are not. Here is an example of how
;; inline todo notes might be used:
;;
;; `Shall I compare thee((TODO: modernise to "you"?)) to a summer's
;; day?((TODO: too clichéd, revise))'
;;
;; Note the absence of any additional whitespace to the text outside
;; the inline todo note. Using inline todo notes in this manner means
;; that if they are stripped from a file (like with
;; `intono-delete-all',for example), their removal will not leave
;; redundant whitespace behind in the text.
;;
;; The point of this style of todo note is to enable the user to
;; record notes or reminders relating to the immediate context of what
;; they are writing, without breaking the writing flow to open another
;; document, and in a form so that the notes remain embedded within
;; draft document and their original context, instead of recorded
;; elsewhere in a place where they may be forgotten or lost.
;;
;; How one works while writing is, however, highly personal. This
;; package was developed for my own, particular way of working. This
;; makes it rather niche. If you do find it useful though, or think it
;; would be if only it was tweaked in this or that minor way,
;; suggestions, contributions, and/or forks are of course always
;; welcome.

;;; Code:

(defgroup intono nil
  "In(line) to(do) no(tes)."
  :group 'text
  :prefix "intono-"
  :version "30.2"
  :link '(url-link :tag "Website" "https://github.com/mbatson/intono"))

(defcustom intono-delimiter-start "(("
  "String that denotes the beginning of an inline todo note."
  :type 'string
  :group 'intono
  :package-version '(intono . "0.2"))

(defcustom intono-delimiter-end "))"
  "String that denotes the ending of an inline todo note."
  :type 'string
  :group 'intono
  :package-version '(intono . "0.2"))

(defcustom intono-keyword "TODO: "
  "String that denotes the keyword of an inline todo note.

The keyword comes immediately following the starting delimiter (see
`intono-delimiter-start'), acting as an additional element to ensure
inline todo notes are syntactically unique within any document, and/or
as an indication of the notes purpose, like the default `TODO: '
keyword.

If you do not want to use a keyword at all (i.e., use only delimiter
symbols to syntactically mark inline todo notes), set this variable to
the empty string: `\"\"'."
  :type 'string
  :group 'intono
  :package-version '(intono . "0.2"))

(defcustom intono-hiding-marker ""
  "String that is displayed in place of inline todo notes when hidden."
  :type 'string
  :group 'intono
  :package-version '(intono . "1.0"))

(defvar intono--deleting-overlay nil
  "Overlay for highlighting inline todo notes during interactive deletion.")

(defvar-local intono--hiding-overlays nil
  "Overlay for hiding inline todo notes.")

(defun intono--clean-up-hiding-overlays ()
  "Delete any existing overlays in `intono--hiding-overlays'.

In effect, this reveals all hidden inline todo notes in the current
buffer.

For internal use only. For the user command to reveal hidden notes, see
`intono-toggle-note-hiding'."
  (when intono--hiding-overlays
    (mapc 'delete-overlay intono--hiding-overlays)
    (setq intono--hiding-overlays nil)))

;;;###autoload
(defun intono-toggle-note-hiding ()
  "Toggle between hiding and showing all inline todo notes in the buffer.

If `intono-hiding-marker' is a non-empty string, it will be displayed in
place of each hidden inline todo note as a marker.

This command does not alter the buffer's text in any way. The hiding of
inline todo notes, and their replacement by `intono-hiding-marker' is a
purely visual change."
  (interactive)
  (if intono--hiding-overlays
      (progn
        (intono--clean-up-hiding-overlays)
        (remove-hook 'before-revert-hook #'intono--clean-up-hiding-overlays t))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward (intono--regexp) nil t)
        (let ((overlay (make-overlay (match-beginning 0) (match-end 0) nil t nil)))
          (overlay-put overlay 'invisible t)
          (overlay-put overlay 'evaporate t)
          (when (> (length intono-hiding-marker) 0)
            (overlay-put overlay 'before-string intono-hiding-marker))
          (push overlay intono--hiding-overlays)))
      (add-hook 'before-revert-hook #'intono--clean-up-hiding-overlays nil t))))

(defun intono--regexp ()
  "Return a regular expression that matches any inline todo note."
  (concat (regexp-quote intono-delimiter-start)
          (regexp-quote intono-keyword)
          ".*?"
          (regexp-quote intono-delimiter-end)))

;;;###autoload
(defun intono-insert ()
  "Insert an inline todo note at point."
  (interactive)
  (insert intono-delimiter-start
          intono-keyword
          intono-delimiter-end)
  (backward-char (length intono-delimiter-end)))

;; `intono--highlight' modelled on `isearch-highlight' and
;; `replace-highlight'.
(defun intono--highlight (beg end)
  "Highlight the region from BEG to END with an `intono--deleting-overlay'.
If an overlay already exists, move its position, otherwise create it."
  (if intono--deleting-overlay
      (move-overlay intono--deleting-overlay beg end)
    (setq intono--deleting-overlay (make-overlay beg end))
    (overlay-put intono--deleting-overlay 'face 'query-replace)))

(defun intono--clean-up-deleting-overlay ()
  "Delete any existing `intono--deleting-overlay'."
  (when intono--deleting-overlay
    (delete-overlay intono--deleting-overlay)))

;;;###autoload
(defun intono-delete-all ()
  "Interactively delete inline todo notes in current buffer.

This is particularly useful for preparing text full of inline todo notes
for publication.

This function is destructive, removing inline todo notes in the buffer
by regexp matching on `intono--regexp'. While the default syntax of
inline todo notes is intended to be unique enough that this function
won't accidentally match any text that is not an inline todo note, the
user should still proceed with caution, particularly when pressing ! to
delete all remaining inline todo notes, and always ensure they have a
backup of the text in the buffer before running it."
  (interactive)
  (let ((case-fold-search nil)
        (inline-todo-note (intono--regexp)))
    (save-excursion
      (goto-char (point-min))
      (condition-case nil
          (map-y-or-n-p "Delete inline todo note before point? "
                        (lambda (x)
                          (delete-region (car x) (nth 1 x)))
                        (lambda ()
                          (if (re-search-forward inline-todo-note nil t)
                              (let ((beg (match-beginning 0))
                                    (end (match-end 0)))
                                (intono--highlight beg end)
                                (list beg end))
                            nil))
                        '("inline todo note" "inline todo notes" "delete")
                        nil
                        t)
        ;; Clean up overlay if user quits, like with C-g.
        (quit (intono--clean-up-deleting-overlay)))
      (intono--clean-up-deleting-overlay))))

;;;###autoload
(defun intono-delete-all-and-diff ()
  "Execute `intono-delete-all', then show a diff of changes made to buffer.

This command provides an alternative to `intono-delete-all', for users
who always want to review a diff of changes made to the buffer by that
command."
  (interactive)
  (call-interactively #'intono-delete-all)
  (diff-buffer-with-file (current-buffer)))

;;;###autoload
(define-minor-mode intono-mode
  "Toggle Intono mode in the current buffer.

Intono mode provides font-lock-based highlighting of inline todo notes
so they can be easily discerned within surrounding blocks of text. In
Intono mode, an inline todo note is a markup construct beginning with
the text, `((TODO: ', and ending with `))'.

Intono mode is designed for the writing of prose and poetry (rather than
computer programming). In Emacs, therefore, it is intended for use in
modes like `text-mode', `org-mode', `markdown-mode', and similar.

To insert an inline todo note at point, press \\[intono-insert].

Note that all Intono functions can be used without enabling this minor
mode. All this mode really does is enable font-lock highlighting of
inline todo notes, and is not necessary for Intono functions like
`intono-insert' to work."
  :lighter nil
  (require 'font-lock)
  (if intono-mode
      (progn
        (font-lock-add-keywords nil `((,(intono--regexp) 0 font-lock-comment-face)))
        (font-lock-flush))
    (font-lock-remove-keywords nil `((,(intono--regexp) 0 font-lock-comment-face)))
    (font-lock-flush)))

;;;###autoload
(define-globalized-minor-mode global-intono-mode
  intono-mode
  intono-mode
  :predicate '(text-mode)
  :group 'intono)

(provide 'intono)

;;; intono.el ends here

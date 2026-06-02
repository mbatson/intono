;;; intono.el --- In(line) to(do) no(tes) for writing -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Matthew Batson

;; Author: Matthew Batson <mbatson@mbatson.net>
;; Created: 2026
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
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
;; beginning with the text, `((TODO:', and ending with `))'. Between
;; these two elements the user can insert any text they want. This
;; package provides functions to make the insertion and deletion of
;; such notes in a buffer easy and convenient. It also provides a
;; minor mode, `intono-mode', which highlights inline todo notes with
;; font-lock so that they are visually distinct from the surrounding
;; text.
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
;; `intono-delete-all-in-buffer',for example), their removal will not
;; leave redundant whitespace behind in the text.
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

;; TODO: Make keyword customisable?
;; TODO: Make delimiters customisable?

(defgroup intono nil
  "In(line) to(do) no(tes)."
  :group 'text
  :prefix "intono-"
  :version "30.2"
  :link '(url-link :tag "Website" "https://github.com/mbatson/intono"))

(defvar intono--regexp "((TODO:.*?))")

;; TODO: Add user option for auto-inserting a space after keyword
;;;###autoload
(defun intono-insert ()
  "Insert an inline todo note at point."
  (interactive)
  (insert "((TODO: ))")
  (backward-char 2))

;; TODO: Enable confirmation of deleting each inline todo note like
;; `query-replace'?
;;;###autoload
(defun intono-delete-all-in-buffer ()
  "Delete all inline todo notes in buffer.

This is particularly useful for preparing text full of inline todo notes
for publication.

WARNING: This function is destructive to the buffer, removing all inline
todo notes in the buffer by regexp matching on `intono--regexp'. While
the syntax of inline todo notes are designed to be unique enough that
they can hopefully be matched without ever accidentally matching text
that is not an inline todo note, that cannot be guaranteed. Therefore,
the user should proceed with caution when using this function, and
always ensure they have a backup of the text in the buffer before
running it."
  (interactive)
  (let ((case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward intono--regexp nil t)
        (delete-region (match-beginning 0) (match-end 0))))))

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
        (font-lock-add-keywords nil `((,intono--regexp 0 font-lock-comment-face)))
        (font-lock-flush))
    (font-lock-remove-keywords nil `((,intono--regexp 0 font-lock-comment-face)))
    (font-lock-flush)))

;;;###autoload
(define-globalized-minor-mode global-intono-mode
  intono-mode
  intono-mode
  :predicate '(text-mode)
  :group 'intono)

(provide 'intono)

;;; intono.el ends here

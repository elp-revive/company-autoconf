;;; company-autoconf.el --- completion for autoconf script  -*- lexical-binding: t; -*-

;; Copyright (C) 2016, Noah Peart
;; Copyright (C) 2022, Jen-Chieh Shen

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; Maintainer: Jen-Chieh Shen <jcs090218@gmail.com>
;; Version: 0.0.1
;; URL: https://github.com/elp-revive/company-autoconf
;; Package-Requires: ((emacs "26.1") (company "0.8.12"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Description:

;;  Emacs company completion backend for autoconf files.  Currently completes
;;  for autoconf/automake macros and jumps html documentation for company doc-buffer.

;;; Code:

(eval-when-compile (require 'cl-lib))

(require 'company)

(defgroup company-autoconf nil
  "Company backend for autoconf completion."
  :group 'company
  :prefix "company-autoconf-")

(defcustom company-autoconf-ignore-case t
  "Ignore case when completing."
  :group 'company-autoconf
  :type 'boolean)

(defvar company-autoconf-data-file "macros.dat")

;; ------------------------------------------------------------

(defvar company-autoconf-urls)
(defvar company-autoconf-dir
  (file-name-directory (or load-file-name (buffer-file-name))))

(defun company-autoconf-load (file)
  (with-temp-buffer
    (insert-file-contents file)
    (car (read-from-string (buffer-substring-no-properties (point-min)
                                                           (point-max))))))

(defvar company-autoconf-keywords
  (let ((data (company-autoconf-load
               (expand-file-name company-autoconf-data-file company-autoconf-dir))))
    (setq company-autoconf-urls
          (cl-loop for url across (cdr (assoc-string "roots" data))
                   collect (concat (car (split-string url "html_node")) "html_node/")))
    (sort
     (cl-loop for (k . v) in data
              unless (string= k "roots")
              do
              (put-text-property 0 1 'annot (aref v 1) k)
              (put-text-property 0 1 'href (aref v 0) k)
              (put-text-property 0 1 'index (aref v 2) k)
              collect k)
     'string<)))

(defun company-autoconf-prefix ()
  (and (memq major-mode '(autoconf-mode m4-mode))
       (not (company-in-string-or-comment))
       (company-grab-symbol)))

;; retrieval methods

(defun company-autoconf-candidates (arg)
  (let ((completion-ignore-case company-autoconf-ignore-case))
    (all-completions arg company-autoconf-keywords)))

(defun company-autoconf-annotation (candidate)
  (or (get-text-property 0 'annot candidate) ""))

(defun company-autoconf-location (candidate)
  "Jump to CANDIDATE documentation in browser."
  (when-let* ((idx (get-text-property 0 'index candidate)))
    ;; TODO: ..
    ;;(browse-url
    ;; (concat (nth idx company-autoconf-urls)
    ;;         (get-text-property 0 'href candidate)))
    ))

;;;###autoload
(defun company-autoconf (command &optional arg &rest _args)
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-autoconf))
    (prefix (company-autoconf-prefix))
    (annotation (company-autoconf-annotation arg))
    (candidates (company-autoconf-candidates arg))
    (doc-buffer (company-autoconf-location arg))
    (meta (company-autoconf-annotation arg))
    (ignore-case company-autoconf-ignore-case)
    (duplicates nil)
    (sorted t)))

(provide 'company-autoconf)
;;; company-autoconf.el ends here

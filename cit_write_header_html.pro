
PRO cit_write_header_html, lun, title=title, width=width, heading=heading

;+
; NAME:
;     CIT_WRITE_HEADER_HTML
;
; PURPOSE:
;     Writes a standard header to an already open html output file.
;     The user should run cit_write_footer_html before closing the
;     file.
;
; CATEGORY:
;     ADS; citations; output.
;
; CALLING SEQUENCE:
;     CIT_WRITE_HEADER_HTML, Lun
;
; INPUTS:
;     Lun:  Logical Unit Number (LUN) for the file that is to be written
;           to.
;
; OPTIONAL INPUTS:
;     Title:  String specifying a title for the file.
;     Width:  Integer specifying the width of the html file. The default
;             is 700 pixels.
;     Heading:  A string that will be printed as the heading for the html 
;               file, using the <h1> format. A horizontal line will be 
;               inserted above and below the heading.
;
; OUTPUTS:
;     Writes a set of strings to the LUN that is assumed to be already
;     open. The LUN is not closed by this routine.
;
; EXAMPLE:
;      IDL> cit_write_header_html, lun, width=800, title='My webpage'
;
; MODIFICATION HISTORY:
;      Ver.1, 11-Mar-2023, Peter Young
;      Ver.2, 20-Dec-2024, Peter Young
;        Added heading= optional input.
;-


IF n_elements(title) EQ 0 THEN title=''
IF n_elements(width) EQ 0 THEN width=700


printf,lun,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lun,'<meta charset="utf-8"/>'
printf,lun,'<html>'
printf,lun,'<head>'
printf,lun,'<title>'+title+'</title>'
printf,lun,'</head>'
printf,lun,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lun,'<center>'
printf,lun,'<table border=0 cellpadding=0 cellspacing=0 width='+trim(width)+'>'
printf,lun,'<tbody>'
printf,lun,'<tr><td height=30></td></tr>'
printf,lun,'<tr><td align=left>'

if n_elements(heading) ne 0 then begin
  printf,lun,'<hr>'
  printf,lun,'<h1>'+heading+'</h1>'
  printf,lun,'<hr>'
endif



END

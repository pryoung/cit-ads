

PRO cit_group_country_info, data

;+
; NAME:
;	ROUTINE_NAME
;
; PURPOSE:
;
; CATEGORY:
;	Put a category (or categories) here.  For example:
;	Widgets.
;
; CALLING SEQUENCE:
;	Write the calling sequence here. Include only positional parameters
;	(i.e., NO KEYWORDS). For procedures, use the form:
;
;	ROUTINE_NAME, Parameter1, Parameter2, Foobar
;
;	Note that the routine name is ALL CAPS and arguments have Initial
;	Caps.  For functions, use the form:
; 
;	Result = FUNCTION_NAME(Parameter1, Parameter2, Foobar)
;
; INPUTS:
;     Data:   Structure that is returned by CIT_AUTHOR_GROUP.
;
; OPTIONAL INPUTS:
;	Parm2:	Describe optional inputs here. If you don't have any, just
;		delete this section.
;	
; KEYWORD PARAMETERS:
;	KEY1:	Document keyword parameters like this. Note that the keyword
;		is shown in ALL CAPS!
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;	Describe optional outputs here.  If the routine doesn't have any, 
;	just delete this section.
;
; COMMON BLOCKS:
;	BLOCK1:	Describe any common blocks here. If there are no COMMON
;		blocks, just delete this entry.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;	Please provide a simple example here. An example from the
;	DIALOG_PICKFILE documentation is shown below. Please try to
;	include examples that do not rely on variables or data files
;	that are not defined in the example code. Your example should
;	execute properly if typed in at the IDL command line with no
;	other preparation. 
;
; MODIFICATION HISTORY:
; 	Written by:	Your name here, Date.
;	July, 1994	Any additional mods get described here.  Remember to
;			change the stuff above if you add a new keyword or
;			something!
;-


top_dir=data.top_dir

htmlfile=concat_dir(top_dir,'country_index.html')



;
; get all countries
;
c=data.data.last_affil_country
nc=n_elements(c)

;
; get unique countries
; 
uc=c[uniq(c,sort(c))]
n=n_elements(uc)

n_coun=intarr(n)

FOR i=0,n-1 DO BEGIN
  k=where(c EQ uc[i],nk)
  n_coun[i]=nk
ENDFOR

j=reverse(sort(n_coun))
n_coun=n_coun[j]
uc=uc[j]



openw,lout,htmlfile,/get_lun

printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Country breakdown for authors</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Country breakdown of authors</h1>'
printf,lout,'<p>'

printf,lout,'<p><table border=1 cellpadding=3 align="center">'
printf,lout,'<tr><td><b>Country<b></td><td><b>No. of authors<b><td><b>Percentage</b></tr>'
FOR i=0,n-1 DO BEGIN
  coun=uc[i]
  IF trim(coun) EQ '' THEN coun='Unknown'
  cit_group_country_authors,data,coun,html_link=html_link
  perc=string(format='(f7.1,"%")',n_coun[i]/float(nc)*100.)
  printf,lout,'<tr><td><a href="'+html_link+'">'+coun+'</a><td align="center">'+trim(n_coun[i])+'<td align="center">'+perc+'</tr>'
ENDFOR

printf,lout,'</table>'

printf,lout,'<p><hr>'
foot_text='<i>Last revised on '+systime()+'</i>'

printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout

END

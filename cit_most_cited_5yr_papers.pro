

PRO cit_most_cited_5yr_papers, group_struc, basic=basic

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
;	Parm1:	Describe the positional input parameters here. Note again
;		that positional parameters are shown with Initial Caps.
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

IF ~ tag_exist(group_struc,'far_5') THEN 


IF NOT keyword_set(basic) THEN BEGIN
ENDIF 

IF keyword_set(far_5) AND tag_exist(group_struc,'far_5') THEN BEGIN 
  n=n_elements(group_struc.far_5.ncit)

  n=n_elements(group_struc.far_5.ncit)
  printf,lout,'<p><table border=1 cellpadding=3>'
  printf,lout,'<tr><td colspan=4><b>Most cited first-authored papers in last 5 years</b></td>'
  printf,lout,'<tr><td><b>Citations</b></td><td><b>Name</b></td><td><b>Bibcode</b><td><b>Title</td>'
  FOR i=0,n-1 DO BEGIN
    bcode=trim(group_struc.far_5.bcode[i])
    title=cit_clean_names(strpad(trim(string(format='(a70)',group_struc.far_5.title[i])),70,fill=' '))
    blink='https://ui.adsabs.harvard.edu/abs/'+bcode+'/abstract'
    printf,lout,'<tr><td align="center">'+trim(group_struc.far_5.ncit[i])+'</td>'+ $
           '<td>'+trim(group_struc.far_5.name[i])+'</td>'+ $
           '<td><a href="'+blink+'">'+bcode+'</a></td>'+ $
           '<td><a href="'+blink+'">'+title+'</a></td></tr>'
  ENDFOR
  printf,lout,'</table></p>'
ENDIF



END

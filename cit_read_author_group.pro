
FUNCTION cit_read_author_group, fname, title=title

;+
; NAME:
;     CIT_READ_AUTHOR_GROUP
;
; PURPOSE:
;     Read a text file containing a list of authors and additional
;     information related to their papers
;
; CATEGORY:
;     ADS; read.
;
; CALLING SEQUENCE:
;     Result = CIT_READ_AUTHOR_GROUP( Fname )
;
; INPUTS:
;     Fname:  Name of the text file. Can have an optional title that
;             is in the first line beginning with 'TITLE:'. The following
;             lines have Fortran format (a14,a26,i4,a1,a21) for first
;             name, surname, year of first paper, optional asterisk (if
;             set, then only astro papers are searched), and the Orcid ID
;             (optional).
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
;     An IDL structure with the following tags:
;      .first  First name of author
;      .last   Surname of author
;      .year   Year of first paper
;      .all    Indicates whether all papers are searched or just Astro.
;      .orcid  Orcid ID.
;
;     If a problem is found then -1 is returned.
;
; OPTIONAL OUTPUTS:
;     Title:  A string giving an identifier for the file. For example,
;             'Authors of the Solar Physics group at NASA-Goddard'.
;
; MODIFICATION HISTORY:
;     Ver.1, 08-Dec-2022, Peter Young
;       Code extracted from cit_author_group.pro.
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> s=cit_read_author_group( fname [, title=] )'
  return,-1
ENDIF 


chck=file_search(fname,count=count)
IF count EQ 0 THEN BEGIN
  print,'% CIT_READ_AUTHOR_GROUP: the author list file was not found. Returning...'
  return,-1
ENDIF ELSE BEGIN 
  str={first: '', last: '', year: '', all: '', orcid: ''}
  names=0
  str1=''
  openr,lin,fname,/get_lun
  WHILE eof(lin) NE 1 DO BEGIN
    readf,lin,str1
    IF strmid(str1,0,6) EQ 'TITLE:' THEN BEGIN
      title=trim(strmid(str1,6))
    ENDIF ELSE BEGIN
      reads,str1,format='(a14,a26,i4,a1,a21)',str
      IF n_tags(names) EQ 0 THEN names=str ELSE names=[names,str]
    ENDELSE 
  ENDWHILE
  free_lun,lin
  n=n_elements(names)
ENDELSE

;
; Trim the strings
;
names.first=trim(names.first)
names.last=trim(names.last)
names.year=trim(names.year)
names.all=trim(names.all)
names.orcid=trim(names.orcid)

return,names


END

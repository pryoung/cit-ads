
FUNCTION cit_read_country, affil_file=affil_file, count=count


;+
; NAME:
;     CIT_READ_COUNTRY
;
; PURPOSE:
;     Reads the text file that matches institutes to countries.
;
; CATEGORY:
;     ADS
;
; CALLING SEQUENCE:
;     Result = CIT_READ_COUNTRY( )
;
; INPUTS:
;     None.
;
; OPTIONAL INPUTS:
;     Affil_File:  The name of the affiliation-country file to read. Normally
;                  this does not need to be specified as the file
;                  automatically found.
;
; OUTPUTS:
;     An IDL structure array with the following tags:
;      .country  The country name.
;      .institute  A unique string that identifies an institute and that
;                  usually appears in the ADS affiliation. For example,
;                  "NASA Goddard", or "Princeton University".
;
; OPTIONAL OUTPUTS:
;     Count:  The number of elements in the output structure array.
;
; EXAMPLE:
;     IDL> str=cit_read_country()
;
; MODIFICATION HISTORY:
;     Ver.1, 03-Jan-2023, Peter Young
;     Ver.2, 11-Dec-2025, Peter Young
;       The routine now uses the country mapping file in the GitHub
;       repository rather than fetch it over the internet.
;-


n=n_elements(input)

str={country: '', institute: ''}
affilstr=0

;
;The priorities for the affiliation file are:
;  1. read the specified affil_file
;  2. read the affiliation file in the same directory as the
;     cit_read_country routine.
;
IF n_elements(affil_file) NE 0 THEN BEGIN
  chck=file_search(affil_file,count=count)
  IF count EQ 0 THEN BEGIN
    print,'% CIT_AFFIL_COUNTRY: the specified AUTHOR_FILE does not exist. Returning...'
  ENDIF
ENDIF ELSE BEGIN
  affil_dir=file_dirname(file_which('cit_read_country.pro'))
  affil_file=concat_dir(affil_dir,'cit_affil_country.txt')
ENDELSE

;
; If the internet option hasn't worked, then we need to read
; affil_file into 'page'.
;
IF n_elements(page) EQ 0 THEN BEGIN
  result=query_ascii(affil_file,info)
  nl=info.lines
  page=strarr(nl)
  openr,lin,affil_file,/get_lun
  readf,lin,page
  free_lun,lin
ENDIF 
    
np=n_elements(page)
FOR i=0,np-1 DO BEGIN
  s1=''
  s2=''
  IF trim(page[i]) NE '' THEN BEGIN 
    reads,page[i],format='(a13,a60)',s1,s2
    s2=trim(s2)
    s2=str_replace(s2,'*',' ')
    str.country=trim(s1)
    str.institute=s2
    IF n_tags(affilstr) EQ 0 THEN affilstr=str ELSE affilstr=[affilstr,str]
  ENDIF 
ENDFOR

count=n_elements(affilstr)

return,affilstr

END


FUNCTION cit_affil_mapping, input, country


;+
; NAME:
;     CIT_AFFIL_MAPPING
;
; PURPOSE:
;     Converts an author's full affiliation to a standard, more concise
;     form.
;
; CATEGORY:
;     ADS; affiliations.
;
; CALLING SEQUENCE:
;     Result = CIT_AFFIL_MAPPING( Input, Country )
;
; INPUTS:
;     Input:  A string containing an author's full affiliation.
;     Country: The country of the author's affiliation.
;
; OUTPUTS:
;     A string containing the concise name of the author's affiliation.
;     If a match isn't found, then an empty string is returned.
;
; EXAMPLE:
;     IDL> str='NASA Goddard Space Flight Center, Greenbelt, USA'
;     IDL> print,cit_affil_mapping(str,'US')
;      NASA Goddard
;
; MODIFICATION HISTORY:
;     Ver.1, 20-Jan-2023, Peter Young
;-


mapfile='~/github/cit-ads/cit_affil_mapping.txt'

chck=file_info(mapfile)
IF chck.exists EQ 0 THEN BEGIN
  message,/info,/cont,'The mapping file was not found. Returning...'
  return,''
ENDIF 

;
; Get rid of funny html text in the input.
;
input=str_replace(input,'&amp;','&')


openr,lin,mapfile,/get_lun

bits=str_sep(input,';')
aff=bits[0]

c=''
affil=''
search_str=''

WHILE ~ eof(lin) DO BEGIN
  readf,lin,format='(a13,a31,a50)',c,affil,search_str
  IF trim(search_str) EQ '' THEN search_str=affil
  chck1=strpos(strlowcase(aff),strlowcase(trim(search_str)))
  chck2=strlowcase(trim(c)) EQ strlowcase(trim(country))
  IF chck1 GE 0 AND chck2 THEN BEGIN
    free_lun,lin
    return,trim(affil)
  ENDIF
  
ENDWHILE 

free_lun,lin

return,input

END

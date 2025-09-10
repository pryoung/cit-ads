

FUNCTION cit_filter_keywords, input, count=count


;+
; NAME:
;     CIT_FILTER_KEYWORDS
;
; PURPOSE:
;     Filters a list of article keywords to remove certain types of keyword.
;     Examples include empty keywords and keywords that are numbers.
;
; CATEGORY:
;     ADS; keywords.
;
; CALLING SEQUENCE:
;     Result = CIT_FILTER_KEYWORDS( Input )
;
; INPUTS:
;     Input:  A string array containing article keywords.
;
; OUTPUTS:
;     A string array containing keywords.
;
; OPTIONAL OUTPUTS:
;     Count:  The size of the output string array.
;
; EXAMPLE:
;     IDL> keywords=cit_get_keywords(ads_data)
;     IDL> keywords2=cit_filter_keywords(keywords)
;
;     The above can also be done with:
;     IDL> keywords=cit_get_keywords(ads_data,/filter)
;
; MODIFICATION HISTORY:
;     Ver.1, 22-Aug-2023, Peter Young
;     Ver.2, 15-Jul-2025, Peter Young
;       Fixed bug in the case a keyword was an empty string.
;-

count=0

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> keywords=cit_filter_keywords( keywords [, count= ] )'
  return,''
ENDIF 


keywords=input

;
; Just in case there are any empty strings.
;
k=where(keywords NE '',n_key)
keywords=keywords[k]

;
; The following checks if any of the keywords can be converted to numbers. If
; yes, then they are ignored.
;
swtch=bytarr(n_key)+1b
FOR i=0,n_key-1 DO BEGIN
  IF valid_num(trim(keywords[i])) THEN swtch[i]=0b
ENDFOR
k=where(swtch EQ 1)
keywords=keywords[k]
n_key=n_elements(keywords)


count=n_elements(keywords)

return,keywords


END

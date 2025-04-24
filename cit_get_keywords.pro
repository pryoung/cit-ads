

FUNCTION cit_get_keywords, ads_data, count=count, filter=filter, add_random=add_random


;+
; NAME:
;     CIT_GET_KEYWORDS
;
; PURPOSE:
;     Extract all of the keywords from an author's ADS data structure.
;
; CATEGORY:
;     ADS; keywords.
;
; CALLING SEQUENCE:
;     Result = CIT_GET_KEYWORDS( Ads_Data )
;
; INPUTS:
;     Ads_Data:  An IDL structure containing an author's ADS data in the
;                format returned by cit_get_ads_entry.
;
; KEYWORD PARAMETERS:
;     FILTER:  If set, then the keyword list is processed with
;              cit_filter_keywords.
;     ADD_RANDOM:  If set, then any articles with no keywords are assigned
;                  two 6-letter keywords consisting of random letters.
;
; OUTPUTS:
;     A string array containing the keywords of the author's articles. If
;     no keywords are found, then an empty string is returned and COUNT is
;     set to zero.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of elements of the output string array.
;
; EXAMPLE:
;     IDL> keywords=cit_get_keywords(ads_data)
;     IDL> keywords=cit_get_keywords(ads_data,/add_random)
;     IDL> keywords=cit_get_keywords(ads_data,/filter)
;
; MODIFICATION HISTORY:
;     Ver.1, 22-Aug-2023, Peter Young
;     Ver.2, 23-Sep-2024, Peter Young
;       I now change all the keywords to lower case with capitalized first
;       letters.
;     Ver.3, 24-Apr-2025, Peter Young
;       Modified how keywords for articles in the journal Solar Physics are
;       treated
;-

count=0

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> keywords=cit_get_keywords( ads_data [, count=, /filter, /add_random ] )'
  return,''
ENDIF 

n=n_elements(ads_data)

;
; The following generates a single string of random letters that is 5000
; characters long. Six-character strings are extracted from this string and
; get added to the keywords string array.
;
; The "seed" for generating the random string is created from the author's
; data, so should be unique to that author.
;
IF keyword_set(add_random) THEN BEGIN 
  seed=0l
  FOR i=0,n-1 do seed=seed+(fix(ads_data[i].year)-1940)*(ads_data[i].citation_count+1)
  r=round(randomu(seed,5000)*25)
  r_string=string(byte(r+65))
ENDIF 

;
; Below you will see that I add 'sun: ' to all keywords for the journal Solar
; Physics. This is because all papers in this journal should be considered SHP
; articles. Plus, the standard list of Solar Physics keywords recommended by
; the journal seems to make the assumption that 'Sun' is implied for the
; keywords. For example, keywords such as 'convection zone', 'active region'
; and 'transition region'.
;
keywords=''
rcount=0
FOR i=0,n-1 DO BEGIN
  IF ads_data[i].keyword.count() NE 0 THEN BEGIN 
    keyw=ads_data[i].keyword.toarray()
    IF ads_data[i].pub EQ 'Solar Physics' THEN keyw='sun: '+keyw
    keywords=[keywords,keyw]
  ENDIF ELSE BEGIN
    IF keyword_set(add_random) THEN BEGIN 
      keywords=[keywords,strmid(r_string,rcount*6,6),strmid(r_string,(rcount+1)*6,6)]
      rcount=rcount+2
    ENDIF 
  ENDELSE 
ENDFOR

IF n_elements(keywords) EQ 1 THEN BEGIN
  count=0
  return,''
ENDIF

keywords=keywords[1:*]
count=n_elements(keywords)

IF keyword_set(filter) THEN keywords=cit_filter_keywords(keywords,count=count)

;
; Here I standardize the keywords so they are lower case with capitalized
; first letters.
;
kw=keywords.ToLower()
keywords=kw.CapWords()

return,keywords

END



FUNCTION cit_get_keywords, ads_data, count=count, filter=filter, add_random=add_random, $
                           years=years, limit=limit


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
; OPTIONAL INPUTS:
;     Years:  By default, keywords from all the author's articles are
;             returned. If YEARS is set, then only the most recent
;             articles will be used. For example, if years=5, then
;             articles from the last five years.
;     Limit:  An integer specifying the maximum number of keywords an
;             article can have.
;
; KEYWORD PARAMETERS:
;     FILTER:  If set, then the keyword list is processed with
;              cit_filter_keywords.
;     ADD_RANDOM:  If set, then any articles with no keywords are assigned
;                  two 6-letter keywords consisting of random letters; if
;                  an article has only one keyword, then an extra
;                  randomly-generated one is added.
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
;     Ver.4, 09-Sep-2025, Peter Young
;       Added limit= optional input; for /add_random, if there is only one
;       keyword for an article, then I add an extra, randomly-generated one.
;     Ver.5, 10-Sep-2025, Peter Young
;       Now filters out the PACS keyword codes.
;-

count=0

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> keywords=cit_get_keywords( ads_data [, count=, years=, /filter, /add_random, limit= ] )'
  return,''
ENDIF 

;
; If limit not set, then use very large number.
;
IF n_elements(limit) EQ 0 THEN limit=10000

ad=ads_data

curr_jd = systime(/julian, /utc)
jd_str = anytim2jd(ad.pubdate)
ad_jd = jd_str.int + jd_str.frac
IF n_elements(years) NE 0 THEN BEGIN
  check_jd=curr_jd-years*365.25
  k=where(ad_jd GE check_jd,nk)
  IF nk EQ 0 THEN BEGIN
    message,/info,/cont,'No articles satisfy the YEARS criterion. Returning...'
    return,''
  ENDIF ELSE BEGIN
    ad=ad[k]
  ENDELSE 
ENDIF 


n=n_elements(ad)

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
  FOR i=0,n-1 do seed=seed+(fix(ad[i].year)-1940)*(ad[i].citation_count+1)
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
  keyw=ad[i].keyword.toarray()
  nkeyw=ad[i].keyword.count()
  ;
  ; Get rid of PACS keywords (of the format 96.50.Uv) since ADS seems to
  ; convert these to English text.
  ;
  IF nkeyw GT 0 THEN BEGIN 
    chck=keyw.strlen()
    k=where(chck EQ 8,nk)
    IF nk NE 0 THEN BEGIN
      ind=make_array(nkeyw,/byte,value=1b)
      FOR j=0,nk-1 DO BEGIN
        bits=keyw[k[j]].split('\.')
        IF n_elements(bits) EQ 3 THEN ind[k[j]]=0b
      ENDFOR
      k=where(ind EQ 1)
      keyw=keyw[k]
      nkeyw=n_elements(keyw)
    ENDIF
  ENDIF 
  ;
  IF nkeyw NE 0 THEN BEGIN
    ;
    IF nkeyw GT limit THEN keyw=keyw[0:limit-1]
    IF ad[i].pub EQ 'Solar Physics' THEN keyw='sun: '+keyw
    ;
    ; If there is only one keyword, then I add an extra, randomly generated
    ; one if /add_random is set.
    ;
    IF n_elements(keyw) EQ 1 AND keyword_set(add_random) THEN BEGIN
      keyw=[keyw,strmid(r_string,rcount*6,6)]
      rcount=rcount+1
    ENDIF 
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

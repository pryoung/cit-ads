

FUNCTION cit_get_keywords, ads_data, count=count, filter=filter

keywords=''
n=n_elements(ads_data)
FOR i=0,n-1 DO BEGIN
  IF ads_data[i].keyword.count() NE 0 THEN BEGIN 
    keyw=ads_data[i].keyword.toarray()
    keywords=[keywords,keyw]
  ENDIF 
ENDFOR

IF n_elements(keywords) EQ 1 THEN BEGIN
  count=0
  return,''
ENDIF

keywords=keywords[1:*]
count=n_elements(keywords)

IF keyword_set(filter) THEN keywords=cit_filter_keywords(keywords,count=count)

return,keywords

END

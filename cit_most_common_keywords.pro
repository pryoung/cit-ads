

FUNCTION cit_most_COMMON_keywords, ads_data, count=count


;+
; NAME:
;     CIT_MOST_COMMON_KEYWORDS
;
; PURPOSE:
;     Find the most common keywords in the ADS data.
;
; CATEGORY:
;     ADS; keywords.
;
; CALLING SEQUENCE:
;     Result = CIT_MOST_COMMON_KEYWORDS( Ads_Data )
;
; INPUTS:
;     Ads_Data:  IDL structure in the format returned by CIT_GET_ADS_ENTRY.
;
; OUTPUTS:
;     A structure array with the tags:
;      .keyword  String giving keyword.
;      .n        Integer giving number of instances of keyword.
;
; OPTIONAL OUTPUTS:
;     Count:  No. of elements in the output.
;
; EXAMPLE:
;     IDL> kw=cit_most_common_keywords(ads_data)
;
; MODIFICATION HISTORY:
;     Ver.1, 14-Apr-2023, Peter Young
;-


count=0

n=n_elements(ads_data)

all_keywords=''
FOR i=0,n-1 DO BEGIN
  keyw=ads_data[i].keyword.toarray()
  all_keywords=[all_keywords,keyw]
ENDFOR
;
IF n_elements(all_keywords) EQ 1 THEN BEGIN
  message,/info,/cont,'No keywords found! Returning...'
  return,-1
ENDIF
;
all_keywords=all_keywords[1:*]

i_uniq_lo=uniq(strlowcase(all_keywords),sort(strlowcase(all_keywords)))
uniq_keywords=all_keywords[i_uniq_lo]
uniq_keywords_lo=strlowcase(all_keywords[i_uniq_lo])

chck=strpos(uniq_keywords_lo,'solar and stellar astrophysics')
k=where(chck LT 0)
uniq_keywords=uniq_keywords[k]
uniq_keywords_lo=uniq_keywords_lo[k]

nuk=n_elements(uniq_keywords)
swtch=bytarr(nuk)+1b
FOR i=0,nuk-1 DO BEGIN
  IF strnumber(uniq_keywords_lo[i]) THEN swtch[i]=0b
ENDFOR
k=where(swtch EQ 1)
uniq_keywords=uniq_keywords[k]
uniq_keywords_lo=uniq_keywords_lo[k]

nuk=n_elements(uniq_keywords)

str={ keyword: '', n: 0 }
output=replicate(str,nuk)
output.keyword=uniq_keywords

FOR i=0,nuk-1 DO BEGIN
  k=where(strlowcase(output[i].keyword) EQ strlowcase(all_keywords),nk)
  output[i].n=nk
ENDFOR

i=reverse(sort(output.n))
output=output[i]

count=n_elements(output)

return,output

END



FUNCTION cit_most_COMMON_keywords, input, count=count


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
;     Input:  A string array containing a set of keywords. This is
;             usually obtained with cit_get_keywords.pro.
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
;     IDL> keywords=cit_get_keywords(ads_data)
;     IDL> kw=cit_most_common_keywords(keywords)
;
; MODIFICATION HISTORY:
;     Ver.1, 14-Apr-2023, Peter Young
;-


count=0

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> output=cit_most_common_keywords(keywords [, count=])'
  return,-1
ENDIF 

IF input[0] EQ '' THEN return,-1

all_keywords=input


i_uniq_lo=uniq(strlowcase(all_keywords),sort(strlowcase(all_keywords)))
uniq_keywords=all_keywords[i_uniq_lo]
uniq_keywords_lo=strlowcase(all_keywords[i_uniq_lo])


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

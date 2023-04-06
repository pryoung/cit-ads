

FUNCTION cit_most_COMMON_keywords, ads_data

n=n_elements(ads_data)

all_keywords=''
FOR i=0,n-1 DO BEGIN
  keyw=ads_data[i].keyword.toarray()
  all_keywords=[all_keywords,keyw]
ENDFOR
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

return,output

END

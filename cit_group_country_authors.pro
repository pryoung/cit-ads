

PRO cit_group_country_authors, data, country, html_link=html_link, affil_str=affil_str

top_dir=data.top_dir
c_str=trim(country)
c_str=str_replace(c_str,' ','_')
c_str=str_replace(c_str,'.','')
c_str=strlowcase(c_str)
html_link='authors_'+c_str+'.html'
htmlfile=concat_dir(top_dir,html_link)


d=data.data
k=where(d.last_affil_country EQ country,nk)
d=d[k]

affil_str=0
str={curr_affil: '', country: country, count: 0}

n=n_elements(d)
curr_affil=strarr(n)
FOR i=0,n-1 DO curr_affil[i]=cit_affil_mapping(cit_clean_names(d[i].curr_affil),country)

;
; Get the unique affiliations
;
uca = curr_affil[UNIQ(curr_affil, SORT(curr_affil))]
n_uca=n_elements(uca)
FOR i=0,n_uca-1 DO BEGIN
  str.curr_affil=uca[i]
  IF n_tags(affil_str) EQ 0 THEN affil_str=str ELSE affil_str=[affil_str,str]
ENDFOR 

j=sort(curr_affil)

openw,lout,htmlfile,/get_lun

printf,lout,'<table border=1 cellpadding=3 align="center">'
printf,lout,'<tr><td><b>Author</b><td><b>Affiliation</b></td><td><b>Solar keyword %age</b></tr>'

FOR i=0,nk-1 DO BEGIN
  c_affil=curr_affil[j[i]]
  k=where(affil_str.curr_affil EQ c_affil,nk)
  IF nk NE 0 THEN affil_str[k[0]].count=affil_str[k[0]].count+1
  c_affil=cit_clean_names(strmid(c_affil,0,80))
  sun_keyword_frac=d[j[i]].sun_keyword_frac
  link=d[j[i]].htmlfile
  IF sun_keyword_frac EQ -1 THEN kywd_frac='-1' ELSE kywd_frac=string(format='(i3,"%")',round(sun_keyword_frac*100.))
  printf,lout,'<tr><td><a href="'+link+'">'+d[j[i]].name+'</a><td>'+c_affil+'<td align="center">'+kywd_frac
ENDFOR 

printf,lout,'</table>'

free_lun,lout

k=reverse(sort(affil_str.count))
affil_str=affil_str[k]

END

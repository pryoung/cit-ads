
PRO cit_first_author_html, ads_data, html_file=html_file, h_index=h_index, author=author, $
                           link_author=link_author, name=name

;+
; NAME:
;     CIT_FIRST_AUTHOR_HTML
;
; PURPOSE:
;     Creates two webpages giving information about an author's
;     first-authored, refereed publications. Intended to be called
;     from CIT_AUTHOR_HTML.
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     CIT_FIRST_AUTHOR_HTML, Ads_Data
;
; INPUTS:
;     Ads_Data:  An ADS data structure (from cit_get_ads_entry).
;
; OPTIONAL INPUTS:
;     Html_File:  The name of the output file for the list of
;                 first-authored, refereed publications, ordered by
;                 year. 
;     H_Index:    The h-index for the first-authored, refereed
;                 publications.
;     Name:       Surname of the author (can be an array).
;     Author:     String giving the name of the author of the html
;                 file.
;     Link_Author:  A link to be assigned to the author of the html
;                 file. 
;	
; OUTPUTS:
;     Creates an html file called HTML_FILE containing a list
;     of the author's publications, ordered by year. A second
;     file of the same name, but with '_cit' inserted is written
;     giving the same list, but ordered by citation number.
;
; EXAMPLE:
;     This routine is called by CIT_AUTHOR_HTML, so refer to that
;     routine for examples.
;
; MODIFICATION HISTORY:
;     Ver.1, 23-Jan-2022, Peter Young
;-


npapers=n_elements(ads_data)
tot_cit=total(ads_data.citation_count)

html_dir=file_dirname(html_file)
html_basename=file_basename(html_file,'.html')
html_link=html_basename+'_cit.html'
html_cit_file=concat_dir(html_dir,html_link)

chck=file_search(html_cit_file,count=count)
IF count NE 0 THEN file_delete,html_cit_file

;
; Open the html file and write out the introduction text.
;
openw,lout,html_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>First-authored, refereed publications, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>First-authored, refereed publications of '+name+'</h1>'
printf,lout,'<p>A list of first-authored, refereed publications of '+name+', derived from the ADS Abstracts Service. The number in brackets after each title indicates the number of citations that the paper has received.</p>'

printf,lout,'<p><a href="'+html_link+'">List of publications ordered by citations</a><br>'
printf,lout,'Number of papers: '+trim(npapers)+'<br>'
printf,lout,'No. of citations: '+trim(tot_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(h_index)+'<br>'
;

;
; Write the list of papers
;
s=cit_write_year_list(ads_data,count=n)
FOR i=0,n-1 DO printf,lout,s[i]


;
; Write the footer.
;
IF n_elements(author) NE 0 THEN BEGIN
  foot_text='<p><i>This page mantained by '
  IF keyword_set(link_author) THEN BEGIN
    foot_text=foot_text+ $
         '<a href='+link_author+'>'+author+'</a>'
  ENDIF ELSE BEGIN
    foot_text=foot_text+author
  ENDELSE
  foot_text=foot_text+', l'
ENDIF ELSE BEGIN
  foot_text='<p><i>L'
ENDELSE
foot_text=foot_text+'ast revised on '+systime()+'</i>'

printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout


;--------------------------------------------------------
; Now write the list of publications ordered by citations
;

;
; Print out the second html file containing the most-cited papers.
;
i=reverse(sort(ads_data.citation_count))
;
; Open the html file and write out the introduction text.
;
openw,lout,html_cit_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Publications ordered by citations, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Publications of '+name+' ordered by citations</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+name+', derived from the ADS Abstracts Service and sorted by the numbers of citations. Publications above the horizontal line count towards the h-index.</p>'

printf,lout,'<p><table>'
swtch=0
FOR j=0,npapers-1 DO BEGIN
  k=i[j]
  cit_count=ads_data[k].citation_count
 ;
  IF cit_count LT h_index AND swtch EQ 0 THEN BEGIN
    printf,lout,'</table>'
    printf,lout,'<p><hr></p>'
    printf,lout,'<p><table>'
    swtch=1
  ENDIF 
 ;
  printf,lout,'<tr>'
  printf,lout,'<td valign=top cellpadding=4><b>'+trim(cit_count)+'</b>'
  IF ads_data[k].title.count() GT 0 THEN atitle=ads_data[k].title[0] ELSE atitle='No title'
  printf,lout,'<td><a href='+ads_data[k].ads_link+'>'+atitle+'</a><br>'
  printf,lout,ads_data[k].author_string+', '+ads_data[k].year+', '+ads_data[k].article_string
  printf,lout,'</tr>'

ENDFOR
printf,lout,'</table></p>'
printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout



END


FUNCTION cit_write_year_list, ads_data, count=count

;+
; NAME:
;     CIT_WRITE_YEAR_LIST
;
; PURPOSE:
;     Creates a list of publications that are grouped by the
;     publication year. Years are listed in reverse order, with
;     publications for that year listed in alphabetical order.
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     Result = CIT_WRITE_YEAR_LIST( Ads_Data )
;
; INPUTS:
;     Ads_Data:  An ADS data structure (from cit_get_ads_entry).
;
; OUTPUTS:
;     A string array containing the list of publications in html
;     format. If a problem occurs then an empty string is returned. 
;
; EXAMPLE:
;     IDL> b=cit_author_papers('Young, P.',start=2010)
;     IDL> str=cit_get_ads_entry(b)
;     IDL> s=cit_write_year_list(str)
;
; MODIFICATION HISTORY:
;     Ver.1, 23-Jan-2022, Peter Young
;       Code extracted from cit_author_html.
;-


IF n_params() LT 1 OR n_tags(ads_data) EQ 0 THEN BEGIN
  print,'Use:  IDL> cit_write_year_list, ads_data'
  print,''
  print,'   ads_data  - an ADS data structure'
  return,''
ENDIF 


ostr=''   ; output string


;
; Now go through each year and print out the entries for that year.
;
minyr=min(fix(ads_data.year))
maxyr=max(fix(ads_data.year))
;
FOR i=maxyr,minyr,-1 DO BEGIN
  k=where(fix(ads_data.year) EQ i,nk)
  IF nk GT 0 THEN BEGIN
    ostr=[ostr,'<p><b>'+trim(i)+'</b></p>','<ol>']
   ;    
    auth=strarr(nk)
    FOR ia=0,nk-1 DO auth[ia]=ads_data[k[ia]].author[0]
    isort=sort(auth)
    FOR j=0,nk-1 DO BEGIN
      ii=k[isort[j]]
     ;
      web_link='https://ui.adsabs.harvard.edu/abs/'+ads_data[ii].bibcode
      IF ads_data[ii].title.count() GT 0 THEN atitle=ads_data[ii].title[0] ELSE atitle='No title'
      citstr=' ['+trim(ads_data[ii].citation_count)+']'
      ostr=[ostr,'<li><a href='+web_link+'>'+atitle+'</a>'+citstr+'<br>', $
            ads_data[ii].author_string+', '+ads_data[ii].article_string, $
            '</li>']
    ENDFOR
    ostr=[ostr,'</ol></p>']
  ENDIF 
ENDFOR 

ostr=ostr[1:*]

count=n_elements(ostr)

return,ostr

END

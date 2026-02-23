
FUNCTION cit_write_cit_list, ads_data, h_index=h_index, count=count

;+
; NAME:
;     CIT_WRITE_CIT_LIST
;
; PURPOSE:
;     Creates a list of publications that are ordered by citations 
;     (highest citations at the top).
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
; OPTIONAL INPUTS:
;     H_Index:  A scalar giving the author's h-index. Used to insert 
;     a horizontal line in the output separating those publications 
;     that count towards the h-index, and those that do not.
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
;     Ver.2, 12-Dec-2024, Peter Young
;       h_index is now an optional input.
;-


IF n_params() LT 1 OR n_tags(ads_data) EQ 0 THEN BEGIN
  print,'Use:  IDL> cit_write_cit_list, ads_data [, h_index=, count=count]'
  print,''
  print,'   ads_data  - an ADS data structure'
  return,''
ENDIF 


ostr='<p><table cellpadding="4">'   ; output string

npapers=n_elements(ads_data)
i=reverse(sort(ads_data.citation_count))

if n_elements(h_index) eq 0 then begin
  h_index=-1
  swtch=1b
endif


swtch=0b
FOR j=0,npapers-1 DO BEGIN
  k=i[j]
  cit_count=ads_data[k].citation_count
 ;
  IF cit_count LT h_index AND swtch EQ 0 THEN BEGIN
    ostr=[ostr,'</table>','<p><hr></p>','<p><table cellpadding=4>']
    swtch=1b
  ENDIF 
 ;
  ostr=[ostr,'<tr>']
  ostr=[ostr,'<td valign=top align="right"><b>'+trim(cit_count)+'</b>']
  IF ads_data[k].title.count() GT 0 THEN atitle=ads_data[k].title[0] ELSE atitle='No title'
  ostr=[ostr,'<td><a href='+ads_data[k].ads_link+'>'+atitle+'</a><br>']
  ostr=[ostr,ads_data[k].author_string+', '+ads_data[k].year+', '+ads_data[k].article_string]
  ostr=[ostr,'</tr>']
ENDFOR

ostr=[ostr,'</table></p>']

count=n_elements(ostr)

return,ostr


END

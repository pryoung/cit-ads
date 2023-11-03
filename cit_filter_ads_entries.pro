

FUNCTION cit_filter_ads_entries, ads_data


;+
; NAME:
;     CIT_FILTER_ADS_ENTRIES
;
; PURPOSE:
;     Removes certain types of entry from the structure returned by
;     cit_get_ads_entry.
;
; CATEGORY:
;     ADS; filter.
;
; CALLING SEQUENCE:
;     Result = CIT_FILTER_ADS_ENTRIES( Ads_Data )
;
; INPUTS:
;     Ads_Data:  Structure in the format returned by cit_get_ads_entry.
;
; OUTPUTS:
;     Structure in the same format as ADS_DATA, but it may have some
;     entries removed.
;
; EXAMPLE:
;     IDL> ads_data=cit_get_ads_entry(bibcode_list)
;     IDL> new_data=cit_filter_ads_entries()
;
; MODIFICATION HISTORY:
;     Ver.1, 12-Feb-2023, Peter Young
;       Extracted code that was originally part of cit_author_html.
;     Ver.2, 15-May-2023, Peter Young
;       Caught the case where the article has no title; modified the
;       preface check to only check the first word.
;     Ver.3, 01-Jun-2023, Peter Young
;       Fixed bug with last version.
;     Ver.4, 31-Oct-2023, Peter Young
;       Now removes SHINE abstracts.
;-


out_data=ads_data

;
; Do some filtering of bibcodes.
;
chck=strpos(out_data.bibcode,'EGUGA')
k=where(chck LT 0,nk)
IF nk NE 0 THEN out_data=out_data[k]
;
chck=strpos(strlowcase(out_data.bibcode),'tess')
k=where(chck LT 0,nk)
IF nk NE 0 THEN out_data=out_data[k]
;
chck=strpos(out_data.bibcode,'cosp')
k=where(chck LT 0,nk)
IF nk NE 0 THEN out_data=out_data[k]
;
chck=strpos(out_data.bibcode,'shin.conf')
k=where(chck LT 0,nk)
IF nk NE 0 THEN out_data=out_data[k]


;
; Now do filtering of doctype
;
k=where(out_data.doctype NE 'catalog',nk)
IF nk NE 0 THEN out_data=out_data[k]
;
k=where(out_data.doctype NE 'software',nk)
IF nk NE 0 THEN out_data=out_data[k]
;
k=where(out_data.doctype NE 'proposal',nk)
IF nk NE 0 THEN out_data=out_data[k]
;
k=where(out_data.doctype NE 'abstract',nk)
IF nk NE 0 THEN out_data=out_data[k]
;
k=where(out_data.doctype NE 'erratum',nk)
IF nk NE 0 THEN out_data=out_data[k]
;
k=where(out_data.doctype NE 'circular',nk)
IF nk NE 0 THEN out_data=out_data[k]

;
; Sometimes authors write prefaces to special issues and these come up
; as refereed articles.
;
n=n_elements(out_data)
title=strarr(n)
FOR i=0,n-1 DO BEGIN
  tcount=out_data[i].title.count()
  IF tcount NE 0 THEN title[i]=out_data[i].title[0]
ENDFOR 
;
chck=strpos(trim(strlowcase(title)),'preface')
k=where(chck NE 0,nk)
out_data=out_data[k]


return,out_data

END



FUNCTION cit_filter_ads_data, ads_data, thesis=thesis, count=count, $
                              year=year, refereed=refereed, $
                              min_year=min_year, max_year=max_year

;+
; NAME:
;     CIT_FILTER_ADS_DATA
;
; PURPOSE:
;     Performs some standard filtering of the ADS data structure, based
;     on doctype, year and whether articles are refereed.
;
; CATEGORY:
;     ADS; filter.
;
; CALLING SEQUENCE:
;     Result = CIT_FILTER_ADS_DATA( Ads_Data )
;
; INPUTS:
;     Ads_Data:  An IDL structure containing ADS data in the format
;                returned by cit_get_ads_entry.pro.
;
; OPTIONAL INPUTS:
;     Year:   An integer specifying a year. Only papers published in this
;             year will be returned.
;     Min_Year:  An integer specifying a year. Only papers published from
;                this year onwards will be returned.
;     Max_Year:  An integer specifying a year. Only papers published from
;                this year and earlier will be returned.
;	
; KEYWORD PARAMETERS:
;     REFEREED:  If set, then only refereed papers will be returned, as
;                identified by the refereed tag in ADS_DATA.
;     THESIS:  If set, then any doctypes including the word "thesis" are
;              kept.
;
; OUTPUTS:
;     A structure in the same format as ADS_DATA but with a reduced number
;     of entries based on the doctype tag. If the filtering
;     results in no entries then a value of -1 will be returned and COUNT
;     will be set to zero.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of entries in the output structure.
;
; EXAMPLE:
;     IDL> new_data=cit_filter_ads_data(ads_data)
;     IDL> new_data=cit_filter_ads_data(ads_data,/refereed)
;     IDL> new_data=cit_filter_ads_data(ads_data,year=2022)
;
; MODIFICATION HISTORY:
;     Ver.1, 09-Nov-2023, Peter Young
;     Ver.2, 27-Nov-2023, Peter Young
;       Added min_year= and max_year= optional inputs.
;     Ver.3, 12-Dec-2023, Peter Young
;       Now filters out SHINE abstracts.
;     Ver.4, 01-Apr-2024, Peter Young
;       Now removes preface articles.
;     Ver.5, 03-Apr-2024, Peter Young
;       Fixed a bug introduced in v.4.
;-

count=0

ads_data_out=ads_data

IF n_elements(year) NE 0 AND (n_elements(min_year) NE 0 OR n_elements(max_year) NE 0) THEN BEGIN
  message,/info,/cont,'You must specify either YEAR= or MIN_YEAR= [MAX_YEAR=], but not both. Returning...'
  return,-1
ENDIF 


;
; Filter on the year.
;
IF n_elements(year) NE 0 THEN BEGIN
  k=where(fix(ads_data_out.year) EQ year,nk)
  IF nk EQ 0 THEN BEGIN
    count=0
    return,-1
  ENDIF ELSE BEGIN
    ads_data_out=ads_data_out[k]
  ENDELSE 
ENDIF 

IF n_elements(min_year) NE 0 THEN BEGIN
  k=where(fix(ads_data_out.year) GE min_year,nk)
  IF nk EQ 0 THEN BEGIN
    count=0
    return,-1
  ENDIF ELSE BEGIN
    ads_data_out=ads_data_out[k]
  ENDELSE 
ENDIF 


IF n_elements(max_year) NE 0 THEN BEGIN
  k=where(fix(ads_data_out.year) LE max_year,nk)
  IF nk EQ 0 THEN BEGIN
    count=0
    return,-1
  ENDIF ELSE BEGIN
    ads_data_out=ads_data_out[k]
  ENDELSE 
ENDIF 


;
; Select only refereed articles.
;
IF keyword_set(refereed) THEN BEGIN
  k=where(ads_data_out.refereed EQ 1,nk)
  IF nk NE 0 THEN BEGIN
    ads_data_out=ads_data_out[k]
  ENDIF ELSE BEGIN
    count=0
    return,-1
  ENDELSE
ENDIF 


;
; SHINE conference abstracts get listed as "inproceedings" in ADS
; for some reason, so I remove them here.
;
chck=strmid(ads_data_out.bibcode,4,9)
k=where(chck NE 'shin.conf',nk)
ads_data_out=ads_data_out[k]


;
; If /thesis has not been set, then remove doctypes containing "thesis".
;
IF NOT keyword_set(thesis) THEN BEGIN
  chck=strpos(ads_data_out.doctype,'thesis')
  k=where(chck LT 0,nk)
  ads_data_out=ads_data_out[k]
ENDIF


;
; Remove any preface articles, which are identified by having "preface"
; as the first word of the title.
;
n=n_elements(ads_data_out)
all_titles=strarr(n)
FOR i=0,n-1 DO BEGIN
  IF ads_data_out[i].title.count() GT 0 THEN all_titles[i]=ads_data_out[i].title[0]
ENDFOR 
chck=strpos(strlowcase(all_titles),'preface')
k=where(chck NE 0)
ads_data_out=ads_data_out[k]

;
; The line below defines what types of article end up in the author's publication
; list.
; Note that 'erratum' is identified in doctype and so these are filtered out
; by the command below.
;
k=where(ads_data_out.doctype EQ 'article' OR $
        ads_data_out.doctype EQ 'inproceedings' OR $
        ads_data_out.doctype EQ 'inbook' OR $
        ads_data_out.doctype EQ 'eprint' OR $
        ads_data_out.doctype EQ 'book')


IF nk NE 0 THEN BEGIN
  ads_data_out=ads_data_out[k]
ENDIF ELSE BEGIN
  return,-1
ENDELSE 

count=n_elements(ads_data_out)

return,ads_data_out


END

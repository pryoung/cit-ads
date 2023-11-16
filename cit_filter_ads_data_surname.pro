

FUNCTION cit_filter_ads_data_surname, ads_data, surname, verbose=verbose, $
                                      count=count, refereed=refereed, $
                                      year=year, thesis=thesis


;+
; NAME:
;     CIT_FILTER_ADS_DATA_SURNAME
;
; PURPOSE:
;     This routine performs standard filtering of the ADS data structure
;     with cit_filter_ads_data, and then finds the first-author papers that
;     match the author's surname. If the ADS data structure contains the
;     author_norm tag, then surname is matched again this to better refine
;     the filtering.
;
; CATEGORY:
;     ADS; data; filter.
;
; CALLING SEQUENCE:
;     Result = CIT_FILTER_ADS_DATA_SURNAME( Ads_Data, Surname )
;
; INPUTS:
;     Ads_Data:  An IDL structure containing ADS data in the format
;                returned by cit_get_ads_entry.pro.
;     Surname:   The surname of the author to which ADS_DATA belongs.
;
; OPTIONAL INPUTS:
;     Year:   An integer specifying a year. Only papers published in this
;             year will be returned.
;	
; KEYWORD PARAMETERS:
;     REFEREED:  If set, then only refereed papers will be returned, as
;                identified by the refereed tag in ADS_DATA.
;     THESIS:  If set, then any doctypes including the word "thesis" are
;              kept.
;     VERBOSE: If set, then various information messages are printed to
;              the IDL window.
;
; OUTPUTS:
;     A structure in the same format as ADS_DATA but containing only
;     those articles that are first-authored by the author who matches
;     the input SURNAME.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of entries in the output structure.
;
; CALLS:
;     CIT_FILTER_ADS_DATA
;
; EXAMPLE:
;     IDL> ad=cit_filter_ads_data_surname(ads_data,'young')
;     IDL> ad=cit_filter_ads_data_surname(ads_data,'young',/refereed)
;
; MODIFICATION HISTORY:
;     Ver.1, 09-Nov-2023, Peter Young
;     Ver.2, 13-Nov-2023, Peter Young
;       Fixed bug whereby strlowcase was not being applied to surname.
;-


IF n_params() LT 2 THEN BEGIN
  print,'Use: IDL> new_data=cit_filter_ads_data_surname(ads_data,surname [,/refereed,year=,'
  print,'                         /thesis,count=,/verbose)'
  return,-1
ENDIF 

n1=n_elements(ads_data)
ads_data_out=cit_filter_ads_data(ads_data,refereed=refereed,year=year,count=count, $
                                thesis=thesis)

IF keyword_set(verbose) AND count LT n1 THEN message,/info,/cont,'Standard filtering reduced entries from '+trim(n1)+' to '+trim(count)+'.'

IF count EQ 0 THEN return,-1

;
; The tag author_norm contains standardized author names that include the
; first initial. I thus use the input surname to check which of the
; author_norms best matches surname. This author_norm is then used to
; search for first author papers.
; For example, if the article list belongs to "Young, P", but one paper
; was first-authored by "Young, S.", then simply using surname will not
; distinguish this paper. By using author_norm, however, they will be
; distinguished.
;
swtch=tag_exist(ads_data_out,'author_norm')

n=n_elements(ads_data_out)

IF swtch THEN BEGIN
  IF keyword_set(verbose) THEN message,/info,/cont,'The author_norm tag exists, so surname will be matched against this.'
  all_auth=''
  FOR i=0,n-1 DO all_auth=[all_auth,ads_data_out[i].author_norm.toarray()]
  all_auth=all_auth[1:*]
  chck=strpos(strlowcase(all_auth),strlowcase(surname))
  k=where(chck GE 0,nk)
  all_auth=all_auth[k]
  uauth=all_auth[uniq(all_auth,sort(all_auth))]
  nu=n_elements(uauth)
  num_auth=intarr(nu)
  FOR i=0,nu-1 DO BEGIN
    k=where(all_auth EQ uauth[i],nk)
    num_auth[i]=nk
  ENDFOR
  getmax=max(num_auth,imax)
  auth_norm=uauth[imax]
 ;
  k=where(ads_data_out.first_author_norm EQ auth_norm,count)
  IF keyword_set(verbose) THEN message,/info,/cont,'There are '+trim(count)+' first author papers by '+auth_norm+'.'
  return,ads_data_out[k]
ENDIF ELSE BEGIN
  IF keyword_set(verbose) THEN message,/info,/cont,'The author_norm tag does not exist, first authors will be matched only against surname.'
  first_auth=strarr(n)
  FOR i=0,n-1 DO first_auth[i]=ads_data_out[i].author[0]
  chck=strpos(strlowcase(first_auth),strlowcase(surname))
  k=where(chck GE 0,count)
  IF keyword_set(verbose) THEN message,/info,/cont,'There are '+trim(count)+' first author papers by '+surname+'.'
  return,ads_data_out[k]
ENDELSE 


END


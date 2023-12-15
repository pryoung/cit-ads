
FUNCTION cit_filter_ads_data_orcid, ads_data, orcid, refereed=refereed, year=year, $
                                    count=count, thesis=thesis, verbose=verbose, $
                                    author_norm=author_norm

;+
; NAME:
;     CIT_FILTER_ADS_DATA_ORCID
;
; PURPOSE:
;     Filters an ADS data structure to identify first-author papers
;     based on the ORCID ID. Additional papers are identified by linking
;     the ORCID ID to the author_norm tag and using this tag.
;
; CATEGORY:
;     ORCID; ADS; citations.
;
; CALLING SEQUENCE:
;     Result = CIT_FILTER_ADS_DATA_ORCID( Ads_Data )
;
; INPUTS:
;     Ads_Data:  An IDL structure containing ADS data in the format
;                returned by cit_get_ads_entry.pro.
;     Orcid:  A string containing an ORCID that is used to identify first
;             authors of papers. In addition, the ID is also used to
;             determine first_author_norm for the author, which is used
;             to identify additional first-author papers based on the
;             value of this tag in ADS_DATA.
;
; OPTIONAL INPUTS:
;     Year:   An integer specifying a year. Only papers published in this
;             year will be returned.
;	
; KEYWORD PARAMETERS:
;     REFEREED:  If set, then only refereed papers will be returned, as
;                identified by the refereed tag in ADS_DATA.
;     VERBOSE:  If set, then various informational messages are printed
;               to the IDL window.
;     THESIS:  If set, then any doctypes including the word "thesis" are
;              kept.
;
; OUTPUTS:
;     A structure in the same format as ADS_DATA but reduced to contain
;     only first-author papers, as identified by the ORCID ID.
;     In addition to directly checking the ORCID ID, the routine uses the
;     ORCID ID to identify the author's author_norm value, and this is
;     used to identify additional papers. If the filtering
;     results in no entries then a value of -1 will be returned and COUNT
;     will be set to zero.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of entries in the output structure.
;     Author_Norm:  The author_norm value for the author identified by the
;                   ORCID ID.
;
; EXAMPLE:
;     IDL> new_data=cit_filter_ads_data_orcid(ads_data,'0000-0001-9034-2925')
;     IDL> new_data=cit_filter_ads_data_orcid(ads_data,'0000-0001-9034-2925',/refereed)
;     IDL> new_data=cit_filter_ads_data_orcid(ads_data,'0000-0001-9034-2925',year=2018)
;
; MODIFICATION HISTORY:
;     Ver.1, 11-Mar-2023, Peter Young
;     Ver.2, 08-Nov-2023, Peter Young
;       Rewritten to become the general routine for filtering the ads_data
;       entries; now uses the ORCID input to determine "first_author_norm",
;       which is used to identify further first-author papers.
;     Ver.3, 09-Nov-2023, Peter Young
;       Now calls cit_filter_ads_data_doctype to filter on doctype.
;     Ver.4, 15-Nov-2023, Peter Young
;       Modified author_norm identification to pick the most common value
;       if there are more than one; updated header.
;     Ver.5, 15-Dec-2023, Peter Young
;       Added author_norm= optional output.
;-



IF n_params() LT 2 THEN BEGIN
  print,'Use: IDL> new_data=cit_filter_ads_data_orcid(ads_data,orcid [,/refereed,year=,'
  print,'                         /thesis,count=,/verbose)'
  return,-1
ENDIF 

n1=n_elements(ads_data)
ads_data_out=cit_filter_ads_data(ads_data,refereed=refereed,year=year,count=count, $
                                thesis=thesis)

IF keyword_set(verbose) THEN message,/info,/cont,'Standard filtering reduced entries from '+trim(n1)+' to '+trim(count)+'.'

IF count EQ 0 THEN return,-1




;
; The following uses the ORCID ID to determine first_author_norm. This is
; used later to identify additional first-author papers not picked up by
; the ORCID ID.
;
IF tag_exist(ads_data_out,'author_norm') THEN BEGIN
  n=n_elements(ads_data_out)
  anorm=strarr(n)
  FOR i=0,n-1 DO BEGIN
    orc=ads_data_out[i].orcid.toarray()
    anorm_arr=ads_data_out[i].author_norm.toarray()
    k=where(orc EQ orcid,nk)
    IF nk NE 0 THEN anorm[i]=trim(anorm_arr[k[0]])
  ENDFOR 
  k=where(anorm NE '',nk)
  IF nk GT 0 THEN BEGIN
   ;
   ; anorm contains the author_norm values associated with the ORCID ID.
   ; anorm_uniq contains the unique author_norm values (usually there
   ; will just be one). In the case where there is more than one (e.g.,
   ; someone changing their name after marriage), the most common
   ; author_norm is used.
   ;
    anorm=anorm[k]
    anorm_uniq=anorm[uniq(anorm,sort(anorm))]
    na=n_elements(anorm_uniq)
    IF na EQ 1 THEN BEGIN
      first_author_norm=anorm_uniq[0]
      IF keyword_set(verbose) THEN message,/info,/cont,'For '+trim(orcid)+' first_author_norm is: '+first_author_norm
    ENDIF ELSE BEGIN
      IF keyword_set(verbose) THEN message,/info,/cont,'For '+trim(orcid)+' there are '+trim(na)+' author_norm values.'
      num=intarr(na)
      FOR i=0,na-1 DO BEGIN
        k=where(anorm EQ anorm_uniq[i],nk)
        num[i]=nk
      ENDFOR
      getmax=max(num,imax)
      first_author_norm=anorm_uniq[imax]
      IF keyword_set(verbose) THEN message,/info,/cont,'Using first_author_norm='+trim(first_author_norm)
    ENDELSE 
  ENDIF ELSE BEGIN
    IF keyword_set(verbose) THEN message,/info,/cont,'A first_author_norm value could not be identified for '+orcid+'.'
  ENDELSE 
ENDIF ELSE BEGIN
  IF keyword_set(verbose) THEN message,/info,/cont,'The author_norm tag does not exist for '+orcid+'.'
ENDELSE 


;
; Author_norm is an optional output.
;
IF n_elements(first_author_norm) NE 0 THEN author_norm=trim(first_author_norm) ELSE author_norm=''

;
; Apply orcid to identify first authors
;
IF n_elements(orcid) NE 0 THEN BEGIN
 ;
  npapers=n_elements(ads_data_out)
  n_orcid=0
  swtch=bytarr(npapers)
  FOR i=0,npapers-1 DO BEGIN
    n_orc=ads_data_out[i].orcid.count()
    IF n_orc GT 0 THEN BEGIN 
      orc=ads_data_out[i].orcid.toarray()
      IF trim(orc[0]) EQ orcid THEN swtch[i]=1b
    ENDIF 
  ENDFOR 
  ind_orcid=where(swtch EQ 1,n_orcid)
  IF keyword_set(verbose) THEN message,/info,/cont,'No. of first author papers identified with ORCID ID: '+trim(n_orcid)+'.'
 ;
  n_norm=0
  IF n_elements(first_author_norm) THEN BEGIN
    chck=tag_exist(ads_data_out,'first_author_norm')
    IF chck EQ 1 THEN BEGIN 
      ind_norm=where(trim(ads_data_out.first_author_norm) EQ trim(first_author_norm),n_norm)
      IF keyword_set(verbose) THEN message,/info,/cont,'No. of first author papers identified with author_norm: '+trim(n_norm)+'.'
    ENDIF 
  ENDIF
 ;
  CASE 1 OF
    n_norm GT 0 AND n_orcid GT 0: BEGIN
      ind_comb=[ind_norm,ind_orcid]
      ind=ind_comb[uniq(ind_comb,sort(ind_comb))]
    END 
    n_norm EQ 0 AND n_orcid GT 0: ind=ind_orcid
    n_norm GT 0 AND n_orcid EQ 0: ind=ind_norm
    ELSE: junk=temporary(ind)
  ENDCASE 
 ;
  IF n_elements(ind) NE 0 THEN BEGIN
    ads_data_out=ads_data_out[ind]
  ENDIF ELSE BEGIN
    count=0
    return,-1
  ENDELSE 
ENDIF 


count=n_elements(ads_data_out)

IF keyword_set(verbose) THEN message,/info,/cont,'Total no. of first author papers: '+trim(count)+'.'

return,ads_data_out

END

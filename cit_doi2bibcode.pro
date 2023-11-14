
FUNCTION cit_doi2bibcode, doi, lookup_table=lookup_table, verbose=verbose


;+
; NAME:
;     CIT_DOI2BIBCODE
;
; PURPOSE:
;     Queries the ADS to convert a DOI to a bibcode.
;
; CATEGORY:
;     ADS; DOI; bibcode.
;
; CALLING SEQUENCE:
;     Result = CIT_DOI2BIBCODE( Doi )
;
; INPUTS:
;     Doi:  A string containing a DOI.
;
; OPTIONAL INPUTS:
;     LOOKUP_TABLE: The name of a text lookup table that matches DOIs to
;                   bibcodes. If the file does not exist, then it is
;                   created and the DOI-bibcode will be written to the
;                   file. This file is needed because many calls to ADS
;                   to retrieve the bibcodes quickly uses up the "quota"
;                   of ADS queries each day.
;
; KEYWORD PARAMETERS:
;     VERBOSE:  If set, then information messages are printed to the IDL
;               window.
;
; OUTPUTS:
;     A bibcode corresponding to the DOI. If no match is found, then an
;     empty string is returned. 
;
; EXAMPLE:
;     IDL> bibcode=cit_doi2bibcode('10.1071/PH850825')
;
; MODIFICATION HISTORY:
;     Ver.1, 30-Oct-2023, Peter Young
;     Ver.2, 31-Oct-2023, Peter Young
;       Caught the case where more than one bibcode is returned.
;     Ver.3, 13-Nov-2023, Peter Young
;       Added lookup_table= and /verbose.
;     Ver.4, 14-Nov-2023, Peter Young
;       Now tries calling ADS API five times before giving up; if doi is
;       empty then exit straight away ; add parameter check at beginning
;       of routine.
;-

IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> bcode=cit_doi2bibcode(doi [,lookup_table=,/verbose])'
  return,''
ENDIF 


IF trim(doi) EQ '' THEN return,''

swtch=0b
IF n_elements(lookup_table) NE 0 THEN BEGIN
  chck=file_info(lookup_table)
  IF chck.exists THEN BEGIN
    swtch=1b
    nlines=file_lines(lookup_table)
    data=strarr(2,nlines)
    openr,lin,lookup_table,/get_lun
    readf,lin,format='(a40,a20)',data
    free_lun,lin
    doi_list=trim(data[0,*])
    bcode_list=trim(data[1,*])
   ;
    k=where(trim(doi) EQ doi_list,nk)
    IF nk NE 0 THEN BEGIN
      IF keyword_set(verbose) THEN message,/info,/cont,'DOI '+doi+' found in lookup table.'
      return,bcode_list[k[0]]
    ENDIF 
  ENDIF ELSE BEGIN
    swtch=2b
  ENDELSE 
ENDIF




url='https://api.adsabs.harvard.edu/v1/search/query'

IF n_elements(doi) GT 1 THEN BEGIN
  ndoi=n_elements(doi)
  query_string='doi:("'+doi[0]+'"'
  FOR i=1,ndoi-1 DO query_string=query_string+' or "'+doi[i]+'"'
  query_string=query_string+')'
ENDIF ELSE BEGIN
  query_string='doi:"'+doi+'"'
ENDELSE 




;
; It's important to replace special characters with codes.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')
query_string=str_replace(query_string,',','%2C')
query_string=str_replace(query_string,'-','%2D')
query_string=str_replace(query_string,'/','%2F')
query_string=str_replace(query_string,'[','%5B')
query_string=str_replace(query_string,']','%5D')
query_string=str_replace(query_string,'^','%5E')


;
; Get ADS API dev_key
;
ads_key=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'***The ADS key was not found!  Returning...***'
  return,''
ENDIF 
headers=['Authorization: Bearer '+ads_key, $
         'Content-Type: application/json']

;
; Only return the bibcode.
;
chck_str=query_string+'&fl=bibcode'
input_url=url+'?q='+chck_str

;
; In case of internet problems, I run the query at most five times until I get an output that is not empty.
;
FOR j=0,4 DO BEGIN 
  headers_input=headers
  sock_list,input_url,json,headers=headers
  IF json[0] NE '' THEN BREAK
  wait,0.5
ENDFOR
;
IF json[0] EQ '' THEN BEGIN
  message,/info,/cont,'The call to the API failed for DOI '+doi+'. Returning...'
  return,''
ENDIF 

s=json_parse(json,/tostruct)
s_list=s.response.docs
ns=s_list.count()
IF ns EQ 0 THEN BEGIN
  return,''
ENDIF ELSE BEGIN
  bibcode=strarr(ns)
  FOR i=0,ns-1 DO BEGIN
    bibcode[i]=s_list[i].bibcode
  ENDFOR 
ENDELSE 

;
; I found one example (10.1038/s41586-018-0429-z) where two bibcodes were
; returned, although both pointed to the same paper.
;
n=n_elements(bibcode)
IF n GT 1 THEN BEGIN
  message,/info,/cont,'The DOI '+doi+' returned '+trim(n)+' bibcodes. Only the first one will be returned.'
  bibcode=bibcode[0]
ENDIF 

;
; [swtch=1] append the doi to the existing lookup table file.
;
IF swtch EQ 1 THEN BEGIN
  openw,lout,lookup_table,/get_lun,/append
  doi_pad=strpad(doi,40,fill=' ',/after)
  bcode_pad=strpad(bibcode,20,fill=' ',/after)
  printf,lout,doi_pad+bcode_pad
  free_lun,lout
  IF keyword_set(verbose) THEN message,/info,/cont,'DOI '+doi+' has been added to the lookup table.'
ENDIF 

;
; [swtch=2] need to create the lookup table file.
;
IF swtch EQ 2 THEN BEGIN
  openw,lout,lookup_table,/get_lun
  doi_pad=strpad(doi,40,fill=' ',/after)
  bcode_pad=strpad(bibcode,20,fill=' ',/after)
  printf,lout,doi_pad+bcode_pad
  free_lun,lout
  IF keyword_set(verbose) THEN message,/info,/cont,'Lookup table did not exist. It has been created.'
ENDIF

  

return,bibcode


END

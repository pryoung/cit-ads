
FUNCTION cit_doi2bibcode, doi


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
; OUTPUTS:
;     A bibcode corresponding to the DOI. If no match is found, then an
;     empty string is returned.
;
; EXAMPLE:
;     IDL> bibcode=cit_doi2bibcode('10.1071/PH850825')
;
; MODIFICATION HISTORY:
;     Ver.1, 30-Oct-2023, Peter Young
;-




url='https://api.adsabs.harvard.edu/v1/search/query'


query_string='doi:"'+doi+'"'


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



sock_list,input_url,json,headers=headers
;
; Sometimes the call fails, so I try again and if this fails exit the routine.
IF json[0] EQ '' THEN BEGIN
  sock_list,input_url,json,headers=headers
  IF json[0] EQ '' THEN BEGIN
      print,'%CIT_DOI2BIBCODE: the call to the API failed for DOI '+doi+'. Returning...'
      return,''
    ENDIF 
ENDIF
;
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


return,bibcode


END

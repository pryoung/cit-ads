
FUNCTION cit_abs_search, name, start_year=start_year, END_year=end_year, $
                         count=count



;+
; NAME:
;     CIT_ABS_SEARCH
;
; PURPOSE:
;     Retrieve a list of bibcodes of papers that contain a specified
;     search string in the abstract.
;
; CATEGORY:
;     ADS; citations; search.
;
; CALLING SEQUENCE:
;     Result = CIT_ABS_SEARCH( Name )
;
; INPUTS:
;     Name:  A string to be searched for.
;
; OPTIONAL INPUTS:
;     Start_Year:  The start year for the search. If not specified
;                  then 1900 is used.
;     End_Year:  The end year for the search. If not specified then
;                the current year is used.
;	
; OUTPUTS:
;     A string array containing a list of ADS bibcodes that satisfy
;     the search criteria.
;
; OPTIONAL OUTPUTS:
;     Count: Integer specifying number of bibcodes that have been found.
;
; EXAMPLE:
;     IDL> bcodes=cit_abs_search('coronal heating')
;
; MODIFICATION HISTORY:
;     Ver.1, 20-Mar-2021, Peter Young
;-


IF n_params() LT 1 THEN BEGIN
  print,'Use:  IDL> bcodes=cit_abs_search( Search_String [, start_year=, end_year=, count= ])'
  return,''
ENDIF 


count=0

IF n_elements(start_year) EQ 0 THEN start_year=1900
IF n_elements(end_year) EQ 0 THEN BEGIN
  t=systime(/julian,/utc)
  caldat,t,m,d,y
  END_year=y
ENDIF


url='https://api.adsabs.harvard.edu/v1/search/query'

;
; Create the query string.
;
IF keyword_set(orcid) THEN field='orcid' ELSE field='author'
field='abs'
;
nauth=n_elements(name)
query_string='( '+field+':("'+name[0]+'")'
IF nauth GT 1 THEN BEGIN 
  FOR i=1,nauth-1 DO BEGIN
    query_string=query_string+' OR '+field+':("'+name[i]+'")'
  ENDFOR
ENDIF 
query_string=query_string+') AND pubdate:['+trim(start_year)+'-01 TO '+trim(end_year)+'-12]'


;
; It's important to replace special characters with codes.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')
query_string=str_replace(query_string,',','%2C')
query_string=str_replace(query_string,'[','%5B')
query_string=str_replace(query_string,']','%5D')

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
; I'm restricting to 1000 results and also just the astronomy
; database (unless /all given).
;
chck_str=query_string+'&rows='+trim(1000)+'&fl=bibcode,doctype'
IF NOT keyword_set(all) THEN chck_str=chck_str+'&fq=database:astronomy'
input_url=url+'?q='+chck_str


sock_list,input_url,json,headers=headers
;
; Sometimes the call fails, so I try again and if this fails exit the routine.
IF json[0] EQ '' THEN BEGIN
  sock_list,input_url,json,headers=headers
  IF json[0] EQ '' THEN BEGIN
      print,'%CIT_GET_ADS_ENTRY: the call to the API failed. Please try again or check your inputs. Returning...'
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
  doctype=strarr(ns)
  bibcode=strarr(ns)
  FOR i=0,ns-1 DO BEGIN
    doctype[i]=s_list[i].doctype
    bibcode[i]=s_list[i].bibcode
  ENDFOR 
ENDELSE 


;
; Here I do a filter on the document type. Note that some abstracts
; get flagged as 'inproceedings' so these need to be manually removed
; later. 
;
k=where(doctype EQ 'article' OR doctype EQ 'inproceedings',nk)
IF nk eq 0 THEN return,''
bibcode=bibcode[k]

;
; SHINE abstracts seem to be classed as articles, so I remove them here.
;
s=strmid(bibcode,4,9)
k=where(s NE 'shin.conf',nk)
bibcode=bibcode[k]

count=n_elements(bibcode)

return,bibcode

END

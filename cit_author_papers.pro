
FUNCTION cit_author_papers, name, start_year=start_year, END_year=end_year, all=all, $
                            orcid=orcid, affil=affil, inst_file=inst_file, count=count, $
                            first_author=first_author


;+
; NAME:
;     CIT_AUTHOR_PAPERS
;
; PURPOSE:
;     Retrieve a list of bibcodes from the ADS for the specified
;     author. Only the Astronomy database is searched, unless /ALL is
;     set. 
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     Result = CIT_AUTHOR_PAPERS( Name )
;
; INPUTS:
;     Name:   The author's name, given in the format "Young,
;             Peter R.", i.e., "SURNAME, First
;             Middle-Initials". Can also give "Young, P." or
;             just "Young". Can be an array of names, in which case
;             the output will include the bibcodes for each of the
;             names. 
;
; OPTIONAL INPUTS:
;     Start_Year:  The start year for the search. If not specified
;                  then 1900 is used.
;     End_Year:  The end year for the search. If not specified then
;                the current year is used.
;     Affil:     Requires the ADS entries to match the specified
;                affiliation. For example, affil='Harvard'. Note that
;                this will match any of the authors'
;                affiliations (not just the specified author). Only
;                one affiliation can be specified.
;     Inst_File: The name of a file containing a list of the author's
;                institutes with start and end dates. The file should
;                be in CSV format and can be read by
;                cit_read_auth_inst.pro.
;
; KEYWORD PARAMETERS:
;     ALL:  If set, then all ADS databases are searched (not just
;           astronomy).
;     ORCID:  If set, then NAME is assumed to be an ORCID ID.
;     FIRST_AUTHOR: Only return first author papers.
;	
; OUTPUTS:
;     A string array containing a list of ADS bibcodes that satisfy
;     the search criteria.
;
; OPTIONAL OUTPUTS:
;     Count:  Number of bibcdes found.
;
; EXAMPLE:
;     IDL> bcodes=cit_author_papers('Young, Peter R.',start=1994)
;     IDL> cit_author_html,bcodes,html_file='young.html',name='Dr. Peter R. Young'
;
;     IDL> bcodes=cit_author_papers('0000-0001-9034-2925',/orcid)
;
;     IDL> bcodes=cit_author_paper('Young, Peter R.',affil='goddard')
;
; MODIFICATION HISTORY:
;     Ver.1, 2-Oct-2019, Peter Young
;     Ver.2, 8-Nov-2019, Peter Young
;       NAME is allowed to be an array now; added /ALL keyword.
;     Ver.3, 30-Mar-2021, Peter Young
;       Added /orcid keyword.
;     Ver.4, 25-Jun-2021, Peter Young
;       Added affil= optional input; fixed problem with a return statement.
;     Ver.5, 26-May-2022, Peter Young
;       Inserted quotes around the affiliation, which is needed if the
;       affiliation contains two words (e.g., "big bear").
;     Ver.6, 12-Aug-2022, Peter Young
;       Added count= optional output; added /first_author keyword.
;     Ver.7, 03-Jan-2023, Peter Young
;       The output bibcode list is now in reverse-date order.
;     Ver.8, 31-Oct-2023, Peter Young
;       The routine no longer filters the bibcodes
;-


IF n_params() LT 1 THEN BEGIN
   print,'Use:  IDL> bcodes=cit_author_papers( "Surname, First M.I." [, start_year=, end_year=, /all, /orcid'
   print,'                                         affil=, count=, /first_author ])'
  return,''
ENDIF


count=0

IF n_elements(start_year) EQ 0 THEN start_year=1900

t=systime(/julian,/utc)
caldat,t,m,d,y
curr_year=y
IF n_elements(end_year) EQ 0 THEN BEGIN
  END_year=curr_year
ENDIF ELSE BEGIN
  IF END_year EQ 0 THEN END_year=curr_year
ENDELSE 



url='https://api.adsabs.harvard.edu/v1/search/query'

IF keyword_set(first_author) THEN add_str='^' ELSE add_str=''

;
; Create the query string.
;
IF keyword_set(orcid) THEN field='orcid' ELSE field='author'
;
nauth=n_elements(name)
query_string='( '+field+':("'+add_str+name[0]+'")'
IF nauth GT 1 THEN BEGIN 
  FOR i=1,nauth-1 DO BEGIN
    query_string=query_string+' OR '+field+':("'+add_str+name[i]+'")'
  ENDFOR
ENDIF 
query_string=query_string+') AND pubdate:['+trim(start_year)+'-01 TO '+trim(end_year)+'-12]'

;
; Add affiliation to query.
;
IF n_elements(affil) NE 0 THEN BEGIN
   query_string=query_string+' AND affil:"'+affil[0]+'"'
ENDIF 

;
; It's important to replace special characters with codes.
;
query_string=str_replace(query_string,':','%3A')
query_string=str_replace(query_string,'"','%22')
query_string=str_replace(query_string,',','%2C')
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
; I'm restricting to 1000 results and also just the astronomy
; database (unless /all given).
;
; The sort command puts the papers in reverse date order.
;
;chck_str=query_string+'&rows='+trim(1000)+'&sort=date%20desc%2C%20bibcode%20desc&fl=bibcode,doctype'
chck_str=query_string+'&rows='+trim(1000)+'&sort=date%20desc&fl=bibcode,doctype'
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
;; k=where(doctype EQ 'article' OR doctype EQ 'inproceedings',nk)
;; IF nk eq 0 THEN return,''
;; bibcode=bibcode[k]


count=nk

return,bibcode

END


function cit_author_group, author_list, data_dir=data_dir, extra_data=extra_data

;+
; NAME:
;     CIT_AUTHOR_GROUP
;
; PURPOSE:
;     This routine creates a set of html citation pages for a group of
;     authors, with a master page giving statistics on each author.
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     CIT_AUTHOR_GROUP, Author_List
;
; INPUTS:
;     Author_List:  A text file containing a list of authors. The
;                   Fortran format is (a14,a26,i4,a1,a21), where the first
;                   column contains the author's name
;                   (including middle initials, if necessary), the
;                   second column contains the surname and the third
;                   column contains a start year for the publication
;                   search. The fourth column (optional) is a single
;                   character after the year. If it is not empty
;                   (e.g., a "*") then the entire ADS database will
;                   be searched, otherwise only Astronomy will be
;                   searched. Note that multiple surnames can be
;                   specified for a single author, by separating them
;                   with a comma. An optional 5th column can be used
;                   for an Orcid ID.
;
; OPTIONAL INPUTS:
;     Data_Dir:   Auxiliary files will be written to the sub-directory
;                 'data'. This can be modified with DATA_DIR.
;     Extra_Data: This is a structure with the same format as the
;                 output of CIT_AUTHOR_GROUP that is used to manually
;                 insert an author's statistics. This might be
;                 required if an author has a common name and it
;                 cannot be handled directly with CIT_AUTHOR_GROUP. 
;	
; OUTPUTS:
;     Creates an IDL structure with citation information for the
;     authors in AUTHOR_LIST (supplemented by information in
;     EXTRA_DATA, if specified). The tags are:
;      .title  The group's name
;      .data   A structure containing citation data
;      .time_stamp  Time at which structure created.
;      .far_5  Structure with information about the most-cited FAR
;              papers in the last 5 years.
;
;     The structure data has the tags below. Note that FAR stands for
;     first-authored refereed.
;      .htmlfile  Publication page for author.
;      .name     Author's name.
;      .h_index  h-index.
;      .h_far_index  h-index for FAR papers.
;      .n_cit    No. of citations.
;      .start_year  Year of first publication.
;      .start_year_far  Year of first FAR publication.
;      .years    Career length based on start_year.
;      .years_far  Career length based on start_year_far.
;      .h_years  h-index divided by years.
;      .h_far_years  h-index divided by years_far.
;      .n_first_ref  No. of FAR papers.
;      .far_year  5-element array giving the last 5 years.
;      .far_num   5-element array giving number of FAR papers in last
;                 5 years.
;      .yrs_since_last  No. of years since last FAR paper.
;      .category  Category assigned to author (e.g., A or A- or empty).
;
; EXAMPLE:
;     IDL> data=cit_author_group('authors.txt')
;
; MODIFICATION HISTORY:
;     Ver.1, 03-Mar-2022, Peter Young
;     Ver.2, 24-Mar-2022, Peter Young
;       Added the tag 'far_5' to the output structure, containing
;       information about the most-cited FAR papers in the last 5
;       years.
;     Ver.3, 22-Apr-2022, Peter Young
;       Now allows the input to have a column to specify /all to
;       cit_author_papers.
;     Ver.4, 16-May-2022, Peter Young
;       Modified so that /all is the default.
;     Ver.5, 26-Jul-2022, Peter Young
;       Added first_affil to output structure.
;     Ver.6, 01-Sep-2022, Peter Young
;       Changed first_affil to first_affil_country to be consistent
;       with cit_author_html.
;     Ver.7, 11-Oct-2022, Peter Young
;       Now sends add_file to cit_author_html.
;     Ver.8, 14-Oct-2022, Peter Young
;       Added /all keyword when there's an Orcid ID; fixed bug for
;       first_affil_country in extra_data.
;     Ver.9, 08-Nov-2022, Peter Young
;       Changed definition of category to give either A or A- or
;       empty.
;-

IF n_params() LT 1 THEN BEGIN
  print,' Use:  IDL> data=cit_author_group( author_list [, extra_data=, data_dir= ] )'
  return,-1
ENDIF 


IF n_elements(data_dir) EQ 0 THEN data_dir='data'
chck=file_info(data_dir)
IF chck.exists EQ 0 THEN file_mkdir,data_dir

chck=file_search(author_list,count=count)
IF count EQ 0 THEN BEGIN
  print,'% CIT_AUTHOR_GROUP: the author list file was not found. Returning...'
  return,-1
ENDIF ELSE BEGIN 
  str={first: '', last: '', year: '', all: '', orcid: ''}
  names=0
  str1=''
  openr,lin,author_list,/get_lun
  WHILE eof(lin) NE 1 DO BEGIN
    readf,lin,str1
    IF strmid(str1,0,6) EQ 'TITLE:' THEN BEGIN
      title=trim(strmid(str1,6))
    ENDIF ELSE BEGIN
      reads,str1,format='(a14,a26,i4,a1,a21)',str
      IF n_tags(names) EQ 0 THEN names=str ELSE names=[names,str]
    ENDELSE 
  ENDWHILE
  free_lun,lin
  n=n_elements(names)
ENDELSE 
  
t=systime(/jul,/utc)
caldat,t,mm,dd,cyr



str={ htmlfile: '', $
      name: '', $
      h_index: 0, $
      h_far_index: 0, $
      n_cit: 0, $
      start_year: 0, $
      start_year_far: 0, $
      years: 0, $
      years_far: 0, $
      h_years: 0, $
      h_far_years:0, $
      n_first_ref: 0, $
      far_year: intarr(5), $
      far_num: intarr(5), $
      yrs_since_last: 0, $
      first_affil_country: '', $
      category: ''}
data=0

far_5_ncit_all=-100
far_5_bcode_all=''
far_5_name_all=''

sname=strarr(n)
FOR i=0,n-1 DO BEGIN
  surname=trim(names[i].last)
  IF trim(names[i].all) EQ '' THEN all=1b ELSE all=0b
 ;
  k=where(sname EQ strlowcase(surname),nk)
  IF nk GT 0 THEN add_str=trim(nk+1) ELSE add_str=''
 ;
  bits=str_sep(surname,',')
  nb=n_elements(bits)
  search_name=strarr(nb)
  FOR j=0,nb-1 DO BEGIN
    search_name[j]=bits[j]+', '+trim(names[i].first)
  ENDFOR
  sname[i]=strlowcase(strcompress(bits[0],/remove_all))+add_str
 ;
  IF trim(names[i].orcid) EQ '' THEN BEGIN
     a=cit_author_papers(search_name,start=fix(names[i].year),all=all)
  ENDIF ELSE BEGIN 
     a=cit_author_papers(trim(names[i].orcid),/orcid,/all)
  ENDELSE
 ;
  IF a[0] EQ '' THEN continue
 ;
  bcode_file=concat_dir(data_dir,sname[i]+'_bcodes.txt')
  openw,bout,bcode_file,/get_lun
  FOR j=0,n_elements(a)-1 DO printf,bout,trim(a[j])
  free_lun,bout
 ;
  junk=temporary(htmlfile)
  htmlfile=concat_dir(data_dir,sname[i]+'.html')
  remove_file=concat_dir(data_dir,sname[i]+'_remove.txt')
  add_file=concat_dir(data_dir,sname[i]+'_add.txt')
  cit_author_html,bib_file=bcode_file,html=htmlfile,name='Dr. '+trim(names[i].first)+' '+trim(bits[0]), $
                  ads_data=ads_data, surname=bits, out_data=out_data, $
                  remove_file=remove_file, add_file=add_file

  str.htmlfile=htmlfile
  str.name=trim(names[i].first)+' '+trim(bits[0])
  str.h_index=out_data.h_index
  str.h_far_index=out_data.h_far_index
  str.n_cit=out_data.n_cit
  str.start_year=out_data.start_year
  str.start_year_far=out_data.start_year_far
  str.years=cyr-out_data.start_year+1
  str.years_far=cyr-out_data.start_year_far+1
  str.h_years=out_data.h_index-str.years
  str.far_year=out_data.far_year
  str.far_num=out_data.far_num
  str.h_far_years=out_data.h_far_index-str.years_far/2
  str.n_first_ref=out_data.n_first_ref
  str.first_affil_country=out_data.first_affil_country
  IF out_data.yr_last_paper EQ -1 OR out_data.yr_last_paper EQ 1900 THEN BEGIN
     str.yrs_since_last=-1
  ENDIF ELSE BEGIN
     str.yrs_since_last=cyr-out_data.yr_last_paper
  ENDELSE 

  IF n_tags(data) EQ 0 THEN data=str ELSE data=[data,str]

 ;
 ; This handles the FAR papers in the last 5 years.
 ;
  k=where(out_data.far_5_ncit GT 0,nk)
  IF nk GE 1 THEN BEGIN
    far_5_ncit_all=[far_5_ncit_all,out_data.far_5_ncit[k]]
    far_5_bcode_all=[far_5_bcode_all,out_data.far_5_bcode[k]]
    far_5_name_all=[far_5_name_all,make_array(nk,value=str.name)]
  ENDIF
  
  junk=temporary(ads_data)
ENDFOR


IF n_tags(extra_data) NE 0 THEN BEGIN
  n=n_elements(extra_data)
  FOR i=0,n-1 DO BEGIN
    IF tag_exist(extra_data,'htmlfile') THEN str.htmlfile=extra_data[i].htmlfile ELSE str.name=''
    IF tag_exist(extra_data,'name') THEN str.name=extra_data[i].name ELSE str.name=''
    str.h_index=extra_data[i].h_index
    str.h_far_index=extra_data[i].h_far_index
    str.n_cit=extra_data[i].n_cit
    str.start_year=extra_data[i].start_year
    str.start_year_far=extra_data[i].start_year_far
    str.h_years=extra_data[i].h_index-(cyr-extra_data[i].start_year+1)
    str.far_year=extra_data[i].far_year
    str.far_num=extra_data[i].far_num
    str.years=cyr+1-str.start_year
    str.years_far=cyr+1-str.start_year_far
    str.h_far_years=extra_data[i].h_far_index-str.years_far/2
    str.n_first_ref=extra_data[i].n_first_ref
    str.yrs_since_last=cyr-extra_data[i].yr_last_paper
    str.first_affil_country=extra_data[i].first_affil_country
   ;
    IF n_tags(data) EQ 0 THEN data=str ELSE data=[data,str]

 ;
 ; This handles the FAR papers in the last 5 years.
 ;
    k=where(extra_data[i].far_5_ncit GT 0,nk)
    IF nk GE 1 THEN BEGIN
      far_5_ncit_all=[far_5_ncit_all,extra_data[i].far_5_ncit[k]]
      far_5_bcode_all=[far_5_bcode_all,extra_data[i].far_5_bcode[k]]
      far_5_name_all=[far_5_name_all,make_array(nk,value=str.name)]
    ENDIF

  ENDFOR 
ENDIF 


;
; Set category A- initially. I require:
;  - paper within last 4 years
;  - at least 0.80 papers/yr over career
;  - f-index to be > 0.80 of age/2
; 
k=where(data.yrs_since_last LE 3 AND float(data.n_first_ref)/data.years_far GE 0.80 AND float(data.h_far_index)/data.years_far*2. GE 0.80,nk)
IF nk NE 0 THEN  data[k].category='A-'

;
; Then set the more restrictive category A to overwrite previous A- category.
;
k=where(data.yrs_since_last LE 2 AND data.h_far_years GT 0 AND float(data.n_first_ref)/data.years_far GE 1.0,nk)
IF nk NE 0 THEN data[k].category='A'



;; k=where(data.yrs_since_last GT 2 AND data.h_far_years GT 0 AND float(data.n_first_ref)/data.years_far GE 1.0,nk)
;; IF nk NE 0 THEN data[k].category='B1'+data[k].category

;; k=where(data.yrs_since_last LE 2 AND data.h_far_years LE 0 AND float(data.n_first_ref)/data.years_far GE 1.0,nk)
;; IF nk NE 0 THEN data[k].category='B3'+data[k].category

;; k=where(data.yrs_since_last LE 2 AND data.h_far_years GT 0 AND float(data.n_first_ref)/data.years_far LT 1.0  AND float(data.n_first_ref)/data.years_far GE 0.66,nk)
;; IF nk NE 0 THEN data[k].category='B2'+data[k].category


IF n_elements(far_5_ncit_all) GT 1 THEN BEGIN
  i=reverse(sort(far_5_ncit_all))
  IF n_elements(i) LT 11 THEN n=n_elements(i)-1 ELSE n=10
  far_5={ ncit: far_5_ncit_all[i[0:n-1]], $
          bcode: far_5_bcode_all[i[0:n-1]], $
          name: far_5_name_all[i[0:n-1]] }
ENDIF

IF n_tags(far_5) EQ 0 THEN BEGIN
  output={title: title, data: data, $
          time_stamp: systime() }
ENDIF ELSE BEGIN 
  output={title: title, data: data, $
          time_stamp: systime(), $
          far_5: far_5}
ENDELSE

return,output

END

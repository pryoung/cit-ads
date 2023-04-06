
function cit_author_group, author_list, data_dir=data_dir, extra_data=extra_data, $
                           orcid_remove=orcid_remove, n_most_cited=n_most_cited, $
                           min_age=min_age, min_papers=min_papers, $
                           yrs_last_paper=yrs_last_paper, limit=limit, $
                           cat_type=cat_type, sun_keyword_frac=sun_keyword_frac, $
                           top_dir=top_dir, time_update=time_update

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
;     Orcid_Remove:  A text file containing a list of Orcid IDs. Authors
;                 with these IDs are removed from the author list.
;     N_Most_Cited: A list is created of the most-cited papers from the
;                 author group. By default, this list contains 10 entries
;                 but this keyword can be used to change the number in the list.
;     Time_Update: An integer specifying the number of days after which an
;                 author's data is considered out-of-date and will be updated.
;                 The default is 28.
;     Min_Papers: Only list an author if they have at least MIN_PAPERS
;                 first-authored refereed papers.
;     Min_Age:    Only list an author if their age is greater or equal
;                 than MIN_AGE.
;     Yrs_Last_Paper: Only include authors whose last paper (either co-author
;                 or first-author) was less than YRS_LAST_PAPER ago.
;     Limit:     An integer specifying the maximum number of authors the
;                routine will process. This can help avoid you hitting the
;                ADS limit request when you're processing a lot of authors.
;     Cat_Type:  An integer specifying how to handle the author categories.
;                 0 - Default. Print A and A- types.
;                 1 - Print only A.
;                 2 - Don't print this column.
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
;      .cat_type The value of cat_type (see inputs).
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
;     Ver.10, 08-Dec-2022, Peter Young
;       Fixed bug in the case title is not defined in the input;
;       added orcid= option to the cit_author_html call.
;     Ver.11, 03-Jan-2023, Peter Young
;       Added limit= optional input.
;-

IF n_params() LT 1 THEN BEGIN
  print,' Use:  IDL> data=cit_author_group( author_list [, extra_data=, data_dir= ] )'
  return,-1
ENDIF 

IF n_elements(time_update) EQ 0 THEN time_update=28

IF n_elements(min_papers) EQ 0 THEN min_papers=1
IF n_elements(min_age) EQ 0 THEN min_age=-1
IF n_elements(yrs_last_paper) EQ 0 THEN yrs_last_paper=10000

IF n_elements(cat_type) EQ 0 THEN cat_type=0
IF n_elements(sun_keyword_frac) EQ 0 THEN sun_keyword_frac=-1
IF n_elements(top_dir) EQ 0 THEN top_dir='.'

IF n_elements(orcid_remove) NE 0 THEN BEGIN
  chck=file_info(orcid_remove)
  IF chck.exists EQ 0 THEN BEGIN
    message,/info,/cont,'The orcid_remove file was not found.'
  ENDIF ELSE BEGIN 
    openr,lin,orcid_remove,/get_lun
    str1=''
    oid_remove=''
    WHILE eof(lin) EQ 0 DO BEGIN
      readf,lin,str1
      IF trim(str1) NE '' THEN oid_remove=[oid_remove,str1]
    ENDWHILE 
    free_lun,lin
    oid_remove=oid_remove[1:*]
  ENDELSE 
ENDIF 


IF n_elements(data_dir) EQ 0 THEN data_dir='data'
top_data_dir=concat_dir(top_dir,data_dir)
chck=file_info(top_data_dir)
IF chck.exists EQ 0 THEN file_mkdir,top_data_dir

chck=file_search(author_list,count=count)
IF count EQ 0 THEN BEGIN
  print,'% CIT_AUTHOR_GROUP: the author list file was not found. Returning...'
  return,-1
ENDIF ELSE BEGIN 
  str={first: '', last: '', year: '', all: '', orcid: ''}
  names=0
  str1=''
  title=''
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

;
; Get current date.
;
t=systime(/jul,/utc)
caldat,t,mm,dd,cyr
date_string=trim(cyr)+'-'+trim(mm)+'-'+trim(dd)



str={ htmlfile: '', $
      name: '', $
      h_index: 0, $
      h_far_index: 0, $
      n_cit: 0, $
      num: 0, $
      start_year: 0, $
      start_year_far: 0, $
      years: 0, $
      years_far: 0, $
      h_years: 0, $
      h_far_years:0, $
      n_first_ref: 0, $
      far_year: intarr(5), $
      far_num: intarr(5), $
      far_cit: -1l, $
      yrs_since_last: 0, $
      first_affil_country: '', $
      last_affil_country: '', $
      curr_affil: '', $
      sun_keyword_frac: 0., $
      category: ''}
data=0

far_5_ncit_all=-100
far_5_bcode_all=''
far_5_name_all=''
far_5_title_all=''

ct_str={solar: 0, keyword_fail: 0, remove: 0, criteria_fail: 0}

IF n_elements(limit) EQ 0 THEN limit=n+1

sname=strarr(n)
count=0
limit_hit=0b
FOR i=0,n-1 DO BEGIN
  IF count GT limit THEN limit_hit=1b
 ;
 ; The output files use the author's surname. In the case where there are
 ; multiple authors with the same surname, the files will be appended with
 ; an integer. For example, 'smith', 'smith2', 'smith3', etc.
 ; Note that 'sname' records the surnames that have previously been
 ; processed in the for loop.
 ;
  surname=trim(names[i].last)
  IF trim(names[i].all) EQ '' THEN all=1b ELSE all=0b
 ;
  bits=str_sep(surname,',')
  nb=n_elements(bits)
  search_name=strarr(nb)
  FOR j=0,nb-1 DO BEGIN
    search_name[j]=bits[j]+', '+trim(names[i].first)
  ENDFOR
;  sname[i]=strlowcase(strcompress(surname,/remove_all))
  fname_base=strlowcase(strcompress(surname,/remove_all))
  fname_base=str_replace(fname_base,',','_')
 ;
  k=where(sname EQ fname_base,nk)
  IF nk GT 0 THEN add_str=trim(nk+1) ELSE add_str=''
 ;
 ; If author i corresponds to smith no. 6, then sname[i] will be smith,
 ; and fname_base will be smith6
 ;
  sname[i]=fname_base
  fname_base=fname_base+add_str
 ;
 ; If we're using Orcid IDs, then here I check if the ID is on the remove
 ; list and so I skip it.
 ;
  orcid_id=trim(names[i].orcid)
  IF orcid_id NE '' AND n_elements(oid_remove) NE 0 THEN BEGIN
    k=where(orcid_id EQ oid_remove,nk)
    IF nk NE 0 THEN BEGIN
      ct_str.remove=ct_str.remove+1
      CONTINUE
    END 
  ENDIF 
 ;
 ; Data for the author is stored in a save file. Here I check if the data
 ; needs updating (determined by time_update). If it doesn't need updating,
 ; then I skip the author.
 ;
  keep_data=0b
  save_file=fname_base+'.save'
  save_ads_file=fname_base+'_ads.save'
  save_file=concat_dir(top_data_dir,save_file)
  save_ads_file=concat_dir(top_data_dir,save_ads_file)
  chck=file_info(save_file)
  IF n_elements(time_update) NE 0 AND chck.exists EQ 1 THEN BEGIN
    restore,save_file
    t_tai=anytim2tai(out_data.time_stamp)
    curr_tai=anytim2tai(date_string)
    diff_days=(curr_tai-t_tai)/86400.
    IF diff_days LE time_update THEN keep_data=1b
   ;
   ; Just in case something's gone wrong with the save file, I
   ; check the ORCID ID to make sure it's correct.
   ;
    IF tag_exist(out_data,'orcid') THEN BEGIN       
      IF out_data.orcid NE orcid_id THEN BEGIN
        message,/info,/cont,'ORCID ID not correct ('+fname_base+'). Re-do data save file.'
        keep_data=0b
      ENDIF 
    ENDIF 
  ENDIF

 ;
 ; If the author is new, or we want to update the existing data, then need
 ; to generate a new publication list for the author.
 ;
  IF NOT keyword_set(keep_data) THEN BEGIN

    IF limit_hit THEN continue
    
    IF orcid_id EQ '' THEN BEGIN
      a=cit_author_papers(search_name,start=fix(names[i].year),all=all)
    ENDIF ELSE BEGIN 
      a=cit_author_papers(orcid_id,/orcid,/all)
    ENDELSE
 ;
    IF a[0] EQ '' THEN continue
 ;
    bcode_file=concat_dir(top_data_dir,fname_base+'_bcodes.txt')
    openw,bout,bcode_file,/get_lun
    FOR j=0,n_elements(a)-1 DO printf,bout,trim(a[j])
    free_lun,bout
 ;
    junk=temporary(htmlfile)
    htmlfile=concat_dir(top_data_dir,fname_base+'.html')
    htmllink=concat_dir(data_dir,fname_base+'.html')
    remove_file=concat_dir(top_data_dir,fname_base+'_remove.txt')
    add_file=concat_dir(top_data_dir,fname_base+'_add.txt')
    IF orcid_id EQ '' THEN junk=temporary(orcid_id)
    cit_author_html,bib_file=bcode_file,html=htmlfile,name='Dr. '+trim(names[i].first)+' '+trim(bits[0]), $
                    ads_data=ads_data, surname=bits, out_data=out_data, $
                    remove_file=remove_file, add_file=add_file,orcid=orcid_id
    count=count+1

    save,file=save_ads_file,ads_data
  ENDIF ELSE BEGIN
    htmlfile=concat_dir(top_data_dir,fname_base+'.html')
    htmllink=concat_dir(data_dir,fname_base+'.html')
  ENDELSE 

  IF out_data.sun_keyword_frac LT sun_keyword_frac AND out_data.sun_keyword_frac NE -1. THEN BEGIN
    ct_str.keyword_fail=ct_str.keyword_fail+1
    CONTINUE
  END 
  
 ;
 ; If min_age and/or min_papers and/or yrs_last_paper have been set, then do the check here.
 ;
  years_far=cyr-out_data.start_year_far+1
  IF tag_exist(out_data,'yr_last_paper_all') THEN BEGIN
    yrs_since_last=cyr-out_data.yr_last_paper_all
  ENDIF ELSE BEGIN
    yrs_since_last=0
  ENDELSE 
  IF years_far LT min_age OR out_data.n_first_ref LT min_papers OR yrs_since_last GT yrs_last_paper THEN BEGIN
    ct_str.criteria_fail=ct_str.criteria_fail+1
    continue
  END

  
  str.htmlfile=htmllink
  str.name=trim(names[i].first)+' '+trim(bits[0])
  str.h_index=out_data.h_index
  str.h_far_index=out_data.h_far_index
  str.n_cit=out_data.n_cit
  str.num=out_data.n_papers
  str.start_year=out_data.start_year
  str.start_year_far=out_data.start_year_far
  str.years=cyr-out_data.start_year+1
  str.years_far=cyr-out_data.start_year_far+1
  str.h_years=out_data.h_index-str.years
  str.far_year=out_data.far_year
  str.far_num=out_data.far_num
  IF tag_exist(out_data,'far_cit') THEN str.far_cit=out_data.far_cit ELSE str.far_cit=-1l
  str.h_far_years=out_data.h_far_index-str.years_far/2
  str.n_first_ref=out_data.n_first_ref
  str.first_affil_country=out_data.first_affil_country
  str.last_affil_country=out_data.last_affil_country
  str.curr_affil=out_data.curr_affil
  str.sun_keyword_frac=out_data.sun_keyword_frac
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
    far_5_title_all=[far_5_title_all,out_data.far_5_title[k]]
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
    str.curr_affil=extra_data[i].curr_affil
    str.sun_keyword_frac=extra_data[i].sun_keyword_frac
   ;
    IF n_tags(data) EQ 0 THEN data=str ELSE data=[data,str]

 ;
 ; This handles the FAR papers in the last 5 years.
 ;
    k=where(extra_data[i].far_5_ncit GT 0,nk)
    IF nk GE 1 THEN BEGIN
      far_5_ncit_all=[far_5_ncit_all,extra_data[i].far_5_ncit[k]]
      far_5_bcode_all=[far_5_bcode_all,extra_data[i].far_5_bcode[k]]
      far_5_title_all=[far_5_title_all,extra_data[i].far_5_title[k]]
      far_5_name_all=[far_5_name_all,make_array(nk,value=str.name)]
    ENDIF

  ENDFOR 
ENDIF 

print,format='("                     No. of authors: ",i7)',n
print,format='("               No. of solar authors: ",i7)',n_elements(data)
print,format='("      No. of authors on remove list: ",i7)',ct_str.remove
print,format='("No. of authors rejected by keywords: ",i7)',ct_str.keyword_fail
print,format='("No. of authors rejected by criteria: ",i7)',ct_str.criteria_fail
;
; Set category A- initially. I require:
;  - paper within last 4 years
;  - at least 0.80 papers/yr over career
;  - f-index to be > 0.80 of age/2
;
IF cat_type EQ 0 THEN BEGIN 
  k=where(data.yrs_since_last LE 3 AND float(data.n_first_ref)/data.years_far GE 0.80 $
          AND float(data.h_far_index)/data.years_far*2. GE 0.80,nk)
  IF nk NE 0 THEN  data[k].category='(*)'
ENDIF 

;
; Then set the more restrictive category A to overwrite previous A- category.
;
IF cat_type LT 2 THEN BEGIN 
  k=where(data.yrs_since_last LE 2 AND data.h_far_years GT 0 AND $
          float(data.n_first_ref)/data.years_far GE 1.0,nk)
  IF nk NE 0 THEN data[k].category='*'
ENDIF 



;; k=where(data.yrs_since_last GT 2 AND data.h_far_years GT 0 AND float(data.n_first_ref)/data.years_far GE 1.0,nk)
;; IF nk NE 0 THEN data[k].category='B1'+data[k].category

;; k=where(data.yrs_since_last LE 2 AND data.h_far_years LE 0 AND float(data.n_first_ref)/data.years_far GE 1.0,nk)
;; IF nk NE 0 THEN data[k].category='B3'+data[k].category

;; k=where(data.yrs_since_last LE 2 AND data.h_far_years GT 0 AND float(data.n_first_ref)/data.years_far LT 1.0  AND float(data.n_first_ref)/data.years_far GE 0.66,nk)
;; IF nk NE 0 THEN data[k].category='B2'+data[k].category


IF n_elements(far_5_ncit_all) GT 1 THEN BEGIN
  IF n_elements(n_most_cited) EQ 0 THEN n_most_cited=10
  i=reverse(sort(far_5_ncit_all))
  IF n_elements(i) LT n_most_cited+1 THEN n=n_elements(i)-1 ELSE n=n_most_cited
  far_5={ ncit: far_5_ncit_all[i[0:n-1]], $
          bcode: far_5_bcode_all[i[0:n-1]], $
          name: far_5_name_all[i[0:n-1]], $
          title: far_5_title_all[i[0:n-1]] }
ENDIF

IF n_tags(far_5) EQ 0 THEN BEGIN
  output={title: title, data: data, $
          time_stamp: systime(), cat_type: cat_type, $
          top_dir: top_dir}
ENDIF ELSE BEGIN 
  output={title: title, data: data, $
          time_stamp: systime(), $
          far_5: far_5, cat_type: cat_type, $
          top_dir: top_dir}
ENDELSE

return,output

END

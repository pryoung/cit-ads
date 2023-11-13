
PRO cit_author_html, bibcodes, bib_file=bib_file, html_file=html_file, $
                     name=name, ads_library=ads_library, $
                     author=author, ads_data=ads_data, remove_file=remove_file, $
                     link_author=link_author, surname=surname, $
                     self_cite_name=self_cite_name, $
                     out_data=out_data, quiet=quiet, nauthor_cutoff=nauthor_cutoff, $
                     add_file=add_file, orcid=orcid, time_update=time_update

;+
; NAME:
;     CIT_AUTHOR_HTML
;
; PURPOSE:
;     This routine takes a list of bibcodes and constructs a
;     publication list in html format. An additional file is also
;     created containing the list sorted according to the number of
;     citations. 
;
; CATEGORY:
;     Citations; ADS; publication list.
;
; CALLING SEQUENCE:
;     CIT_AUTHOR_HTML, Bibcodes
;
; INPUTS:
;     Bibcodes:  A string or string array containing Bibcodes. The
;                Bibcodes can also be specified through BIB_FILE=.
;
; OPTIONAL INPUTS:
;     Bib_File:  A text file containing a list of Bibcodes. Can be
;                specified instead of BIBCODES.
;     Html_File: The name of the html file to be created. If not
;                specified, then the file "author.html" is
;                written to the user's working directory.
;     Name:      The name of the person to which the publication list
;                belongs. This is placed in the title of the output
;                html file. 
;     Author:    The name of the person who created the file, which is
;                placed in the footer of the html file.
;     Link_Author: This is used to assign a link to the
;                author's name in the footer.
;     Surname:   The surname of the person to which the publication
;                list belongs. This is used to check how many first
;                author papers belong to the person (this information
;                is printed to the IDL screen). For authors with
;                multiple surnames (for example, a woman who changes
;                her name after getting married), SURNAME should be
;                given as a string array.
;     Ads_Library: This should be set to a URL pointing to an ADS
;                library containing the same publication list as the
;                html file. A link will be inserted in the html
;                pointing to this page.
;     Remove_file: This is the name of a file containing a list of
;                Bibcodes to be *removed* from the list contained in
;                Bibcodes. This can be useful if you have a common
;                name and want to keep a permanent list of wrong
;                matches.
;     Add_file:  This is the name of a file containing a list of
;                Bibcodes to be *added* to the list contained in
;                Bibcodes. 
;     Self_Cite_Name: This should be set to the surname of the
;                author. The routine will count the number of
;                self-citations and print the average self-citations
;                per paper to the html file. A self-citation is when a
;                paper in the author's publication list cites a
;                first-author paper of the author. WARNING: this slows
;                the routine down a lot!
;     Orcid:     The Orcid ID for the author. If specified, then a link
;                to the author's Orcid page is added to the html file.
;     Time_Update: If the author's data file already exists, then setting
;                this input to an integer makes the routine check to see
;                if the data file is more than TIME_UPDATE days old. If it
;                is not, then the author's data are not updated.
;
; KEYWORD PARAMETERS:
;     QUIET:     If set, then no information is printed to IDL
;                window.
;     NAUTHOR_CUTOFF:  Integer. If set, then any papers with
;                NAUTHOR_CUTOFF authors or more is removed from the
;                output. This is useful for removing particle physics
;                or gravitational wave papers.
;
; OPTIONAL OUTPUTS:
;     Ads_Data:  This is a structure containing the ADS data for each
;                Bibcode. The format is the same as that returned by
;                CIT_GET_ADS_ENTRY. 
;     Out_Data:  A structure containing the numbers that are printed
;                to the html file. The tags are:
;                 h_index: h-index
;                 n_first: no. of 1st author papers
;                 n_first_ref: no. of 1st author refereed papers
;                 n_papers: no. of papers
;                 n_cit: total citations
;                 start_year: year of first paper
;                 yr_last_paper: the year of the author's last
;                                first-author, refereed paper
;
; OUTPUTS:
;     Creates a html file containing a publication list. The name of
;     the file is set by HTML_FILE and by default is "author.html". A
;     second file is also created, with "_cit" appended (e.g.,
;     "author_cit.html") which contains the publications sorted by the
;     numbers of citations.
;
; CALLS:
;     CIT_GET_ADS_ENTRY, CIT_GET_ADS_KEY, CIT_JOUR_ABBREV,
;     CIT_GET_ADS_BIBTEX, CIT_FILL_STRINGS, CIT_BBL2STR, CIT_FIRST_AUTHOR_HTML
;
; EXAMPLE:
;      Search for an author in ADS, and save the output as bibtex. If
;      the file is called 'parker.bbl', then do:
;
;      IDL> str=cit_bib2str('parker.bbl')
;      IDL> cit_author_html,str.id,html_file='parker.html',name='Dr. E.N. Parker'
;
;      If you store the bibcodes in a text file called
;      'parker_bcodes.txt' in the working directory, then you can call
;      the routine as:
;
;      IDL> cit_author_html, surname='Parker'
;
;      The routine will automatically set bib_file='parker_bcodes.txt'
;      and it will also check if remove_file='parker_remove.txt'
;      exists. The author's name (NAME=) will be set to 'Dr. Parker'. 
;
; MODIFICATION HISTORY:
;      Ver.1, 12-Jul-2017, Peter Young
;      Ver.2, 26-Mar-2018, Peter Young
;        Now checks if the html file already exists and deletes it.
;      Ver.3, 6-Sep-2019, Peter Young
;        Updated web link to point to new ADS website.
;      Ver.4, 10-Sep-2019, Peter Young
;        Now calls cit_bbl2str to access bibtex information;
;        cit_fill_strings is now used to fill in the author and
;        article strings.
;      Ver.5, 16-Sep-2019, Peter Young
;        Added self_cite_name= optional input.
;      Ver.6, 19-Sep-2019, Peter Young
;        Number of first author papers is now printed to html file (if
;        surname is specified); added OUT_DATA optional output;
;        reduced information printed to IDL window; added /QUIET
;        keyword.
;      Ver.7, 28-Oct-2019, Peter Young
;        Fixed minor problem when counting refereed papers if
;        'property' is empty.
;      Ver.8, 12-Nov-2019, Peter Young
;        Fixed minor problem with h-index calculation.
;      Ver.9, 04-Mar-2020, Peter Young
;        SURNAME can be an array now.
;      Ver.10, 25-Mar-2021, Peter Young
;        Modified start_year in out_data to be the year of the first
;        refereed paper.
;      Ver.11, 30-Mar-2021, Peter Young
;        Fixed bug with yrs_last_paper.
;      Ver.12, 30-Jun-2021, Peter Young
;        Added far_year and far_num tags to out_data.
;      Ver.13, 08-Jul-2021, Peter Young
;        Added start_year_far to out_data.
;      Ver.14, 23-Jan-2022, Peter Young
;        Now uses cit_first_author_html to print out files for
;        first-authored, refereed papers.
;      Ver.15, 30-Jan-2022, Peter Young
;        Modified how first-author check is done.
;      Ver.16, 24-Mar-2022, Peter Young
;        Added the tags far_5_ncit and far_5_bcode to out_data. These
;        contain information about the authors' most-cited
;        papers in the last 5 years.
;      Ver.17, 07-Apr-2022, Peter Young
;        Fixed bug when author has no FAR papers.
;      Ver.18, 13-Apr-2022, Peter Young
;        Fixed bug for FAR papers.
;      Ver.19, 16-May-2022, Peter Young
;        Now does multiple calls to cit_get_ads_entry in case first
;        attempt fails (perhaps due to internet problems).
;      Ver.20, 26-Jul-2022, Peter Young
;        Added tag 'first_affil' to OUT_DATA, which gives the author's
;        affiliation for their first FAR paper.
;      Ver.21, 11-Oct-2022, Peter Young
;        Now require exact match for identifying first author papers;
;        added add_file= optional input.
;      Ver.22, 25-Oct-2022, Peter Young
;        Fixed bug in add_file implementation.
;      Ver.23, 01-Nov-2022, Peter Young
;        Fixed bug with yr_last_paper if surname not specified.
;      Ver.24, 08-Dec-2022, Peter Young
;        Added ORCID= optional input; added last_affil_country tag to
;        output for the country affiliation of the most recent paper.
;      Ver.25, 12-Dec-2022, Peter Young
;        Added time_stamp tag to output structure.
;      Ver.26, 15-Dec-2022, Peter Young
;        Added yr_last_paper_all to output tag.
;      Ver.27, 03-Jan-2023, Peter Young
;        Made tot_cit a long integer; added curr_affil to output structure,
;        and modified last_affil_country to be for the most recent paper
;        (first-author or co-author); added orcid tag to output.
;      Ver.28, 13-Jan-2023, Peter Young
;        Added far_cit (citations for FAR papers) to out_data.
;      Ver.29, 09-Nov-2023, Peter Young
;        Changed from cit_filter_ads_entries to cit_filter_ads_data.
;      Ver.30, 13-Nov-2023, Peter Young
;         Now using cit_filter_ads_data_orcid and
;         cit_filter_ads_data_surname to identify first-author papers.
;-



IF n_elements(bibcodes) EQ 0 AND n_elements(bib_file) EQ 0 AND n_elements(surname) EQ 0 THEN BEGIN
  print,'Use:  IDL> cit_author_html, bibcodes, [html_file=, bib_file=, name=, ads_library=, author='
  print,'                              ads_data=, remove_file=, surname=, self_cite_name=, out_data= ]'
  return
ENDIF 

;
; The following allows the inputs to cit_author_html to be simplified,
; but it requires the bib_file to exist.
;
; Note:
;  - a surname can have spaces (e.g., "Smith Jones"), so I removed the
;    spaces when creating the filenames below.
;  - surname can be an array, for example, if a woman gets married and
;    takes her partner's name. I use the first element of the
;    array (SNAME) for creating the filenames in this case.
;
IF n_elements(surname) NE 0 THEN BEGIN
  ns=n_elements(surname)
  sname=surname[0]
  IF n_elements(bib_file) EQ 0 AND n_elements(bibcodes) EQ 0 THEN bib_file=strlowcase(strcompress(sname,/remove_all))+'_bcodes.txt'
  IF n_elements(remove_file) EQ 0 THEN remove_file=strlowcase(strcompress(sname,/remove_all))+'_remove.txt'
  IF n_elements(add_file) EQ 0 THEN add_file=strlowcase(strcompress(sname,/remove_all))+'_add.txt'
  IF n_elements(html_file) EQ 0 THEN html_file=strlowcase(strcompress(sname,/remove_all))+'.html'
  IF n_elements(name) EQ 0 THEN name='Dr. '+sname
ENDIF


IF n_elements(name) EQ 0 THEN BEGIN
  name='the Author'
  print,"% CIT_AUTHOR_HTML: use the keyword NAME= to specify the author's name"
ENDIF


;
; Check if the user has an ADS key.
;
chck=cit_get_ads_key(status=status,/quiet)
IF status EQ 0 THEN BEGIN
  print,'% CIT_AUTHOR_HTML: You do not have an ADS key. Please check the webpage'
  print,'    https://pyoung.org/quick_guides/ads_idl_query.html'
  print,'for how to get one.'
  return
ENDIF 

IF n_elements(bib_file) NE 0 THEN BEGIN
  chck=file_search(bib_file,count=count)
  IF count EQ 0 THEN BEGIN
    print,'% CIT_AUTHOR_HTML: The specified bib_file does not exist. Returning...'
    return
  ENDIF
  openr,lin,bib_file,/get_lun
  str1=''
  bibcodes=''
  WHILE eof(lin) EQ 0 DO BEGIN
    readf,lin,str1
    bibcodes=[bibcodes,trim(str1)]
  ENDWHILE
  free_lun,lin
  bibcodes=bibcodes[1:*]
ENDIF



;
; Add bibcodes from the "add" file.
;
IF n_elements(add_file) NE 0 THEN BEGIN
  chck=file_info(add_file)
  IF chck.exists EQ 1 THEN BEGIN 
    str1=''
    openr,ladd,add_file,/get_lun
    WHILE eof(ladd) NE 1 DO BEGIN
      readf,ladd,str1
      IF trim(str1) NE '' THEN bibcodes=[bibcodes,trim(str1)]
    ENDWHILE
    free_lun,ladd
  ENDIF 
ENDIF


IF n_elements(html_file) EQ 0 THEN html_file='author.html'

html_dir=file_dirname(html_file)

;
; Get current year (curr_year).
;
jd=systime(/julian,/utc)
caldat,jd,m,d,curr_year
date_string=trim(curr_year)+'-'+trim(m)+'-'+trim(d)



;
; Create name of file containing list ordered by citations.
;
basename=file_basename(html_file,'.html')
out_file=basename+'_cit.html'
chck=file_search(out_file,count=count)
IF count NE 0 THEN file_delete,out_file

;
; File for saving the author's data.
;
save_file=basename+'.save'
save_file=concat_dir(html_dir,save_file)
chck=file_info(save_file)
IF n_elements(time_update) NE 0 AND chck.exists EQ 1 THEN BEGIN
  restore,save_file
  t_tai=anytim2tai(out_data.time_stamp)
  curr_tai=anytim2tai(date_string)
  diff_days=(curr_tai-t_tai)/86400.
  IF diff_days LE time_update THEN return
ENDIF 


;
; Here I check if the html file already exists. If yes, then I delete
; it. For some reason if I don't do this, then sometimes an
; empty file gets written.
;
chck=file_search(html_file,count=count)
IF count NE 0 THEN file_delete,html_file


;
; Remove any duplicate bibcodes.
;
bibcodes=bibcodes[uniq(bibcodes,sort(bibcodes))]


;
; This calls the ADS to retrieve information about the articles. Note
; that ads_data may contain less entries than bibcodes.
; The cit_fill_strings routine fills the "author_string" and
; "article_string" tags, which are used when writing out the html
; entries. 
;
FOR i=0,5 DO BEGIN
  ads_data=cit_get_ads_entry(bibcodes,/remove_abstracts)
  IF n_tags(ads_data) GT 0 THEN BREAK
  wait,0.5
ENDFOR
IF n_tags(ads_data) EQ 0 THEN BEGIN
  message,'No entries found for this author. Returning...',/CONTINUE,/info
  return
ENDIF
ads_data=cit_filter_ads_data(ads_data)
cit_fill_strings,ads_data
cit_affil_country,ads_data
;ads_data=cit_filter_ads_entries(ads_data)



;
; Remove any entries that are flagged in the remove_file
;
IF n_elements(remove_file) NE 0 THEN BEGIN
  chck=file_info(remove_file)
  IF chck.exists EQ 1 THEN BEGIN
    str1=''
    openr,lrem,remove_file,/get_lun
    WHILE eof(lrem) NE 1 DO BEGIN
      readf,lrem,str1
      i=where(ads_data.bibcode NE trim(str1),ni)
      IF ni NE 0 THEN ads_data=ads_data[i]
    ENDWHILE
    free_lun,lrem
  ENDIF 
ENDIF


;
; Implement nauthor_cutoff, which removes papers with GE
; nauthor_cutoff authors.
;
IF n_elements(nauthor_cutoff) THEN BEGIN
   n=n_elements(ads_data)
   chck=intarr(n)
   FOR i=0,n-1 DO BEGIN
      chck[i]=ads_data[i].author.count()
   ENDFOR
   k=where(chck LT nauthor_cutoff,nk)
   IF nk GT 0 THEN BEGIN 
      IF NOT keyword_set(quiet) THEN print,'% CIT_AUTHOR_HTML: nauthor_cutoff has removed '+trim(n-nk)+' entries.'
      ads_data=ads_data[k]
   ENDIF 
ENDIF 

;
; Total number of papers
;
npapers=n_elements(ads_data)

;
; Get total citations
;
tot_cit=fix(total(long(ads_data.citation_count)))

;
; Get year of last paper
;
yr_all=fix(ads_data.year)
i=reverse(sort(yr_all))
yr_last_paper_all=yr_all[i[0]]

;
; Compute "h-index"
;
cit_list=fix(ads_data.citation_count)
j=reverse(sort(cit_list))
cit_list=cit_list[j]
nj=n_elements(j)
h_index=-1
i=0
WHILE h_index LT 0 AND i LE nj-1 DO BEGIN
  IF i+1 GT cit_list[i] THEN h_index=i
  i=i+1
ENDWHILE
IF h_index EQ -1 THEN h_index=nj   ; in case min(citations) > nj


;
; Some information related to conference proceedings is not obtained
; with cit_get_ads_entry, so I need to access it from the bibtex
; entries. It's quicker to get all the bibtex in one go rather
; than for individual entries, so I get them here and convert to a
; structure. 
;
;bibtex=cit_get_ads_bibtex(ads_data.bibcode)
;bibstr=cit_bbl2str(bib_strarr=bibtex)

;
; Check number of refereed articles.
;
refereed=bytarr(npapers)
k=where(ads_data.refereed EQ 1,nref)
refereed[k]=1b
;; FOR i=0,npapers-1 DO BEGIN
;;   np=ads_data[i].property.count()
;;   swtch=0
;;   j=0
;;   IF np NE 0 THEN BEGIN 
;;     WHILE swtch EQ 0 DO BEGIN
;;       IF trim(ads_data[i].property[j]) EQ 'REFEREED' THEN BEGIN
;;         refereed[i]=1b
;;         swtch=1
;;       ENDIF 
;;       j=j+1
;;       IF j EQ np THEN swtch=1
;;     ENDWHILE
;;   ENDIF 
;; ENDFOR 
;; iref=where(refereed EQ 1,nref)
;
;
;
; Now get stats for first author papers. This requires the routine to
; know the author's surname, hence the keyword 'surname'. Note
; that multiple surnames can be input (e.g., for women who change
; their name after marriage).
;
;  n_first - no. of first-authored papers
;  n_first_ref  - no. of first-authored, refereed papers
;  yr_last_paper  - year of last first-authored, refereed paper
;  h_far_index  - h-index for first-authored, refereed papers
;  start_year_far - year of first first-authored, refereed paper
;
; Note: if the first author has the same surname as SURNAME, then the
; paper will get flagged as a first-author paper. Also, if
; you're searching for "Young" and first author is "Younger"
; then this will also get flagged.
;
; Update: I now check for an exact match of the surnames (to fix the
; Young-Younger issue mentioned above)
;
; Update: if orcid has been specified, then use the Orcid number to
; identify first author papers.
;
yr_last_paper=1900

n_first=0
n_first_ref=0
far_cit=0
far_index=-1

IF n_elements(orcid) NE 0 THEN BEGIN
  ads_data_far=cit_filter_ads_data_orcid(ads_data,orcid,count=n_first)
  ads_data_far=cit_filter_ads_data_orcid(ads_data,orcid,/ref,count=n_first_ref)
  IF n_first_ref GT 0 THEN BEGIN 
    yr_last_paper=max(ads_data_far.year)
    far_cit=total(ads_data_far.citation_count)
  ENDIF 
ENDIF ELSE BEGIN
  ads_data_far=cit_filter_ads_data_surname(ads_data,surname,count=n_first)
  ads_data_far=cit_filter_ads_data_surname(ads_data,surname,/ref,count=n_first_ref)
  IF n_first_ref GT 0 THEN BEGIN 
    yr_last_paper=max(ads_data_far.year)
    far_cit=total(ads_data_far.citation_count)
  ENDIF 
ENDELSE

  
;; IF n_elements(orcid) NE 0 THEN BEGIN
;;   FOR i=0,npapers-1 DO BEGIN
;;     orc=ads_data[i].orcid.toarray()
;;     IF trim(orc[0]) EQ orcid THEN BEGIN
;;       n_first=n_first+1
;;       IF refereed[i] EQ 1 THEN BEGIN
;;         far_cit=far_cit+ads_data[i].citation_count
;;         n_first_ref=n_first_ref+1
;;         far_index=[far_index,i]
;;         IF fix(ads_data[i].year) GT yr_last_paper THEN yr_last_paper=fix(ads_data[i].year)
;;       ENDIF
;;     ENDIF
;;   ENDFOR 
;; ENDIF ELSE BEGIN
;;   IF n_elements(surname) NE 0 THEN BEGIN
;;     ns=n_elements(surname)
;;     FOR i=0,npapers-1 DO BEGIN
;;       swtch=0b
;;       FOR j=0,ns-1 DO BEGIN
;;         sname1=cit_clean_names(strlowcase(ads_data[i].author[0]))
;;         bits=str_sep(sname1,',')
;;         sname1=bits[0]
;;         sname2=strlowcase(surname[j])
;;         IF sname1 EQ sname2 AND swtch EQ 0 THEN BEGIN
;;           n_first=n_first+1
;;           IF refereed[i] EQ 1 THEN BEGIN
;;             n_first_ref=n_first_ref+1
;;             far_cit=far_cit+ads_data[i].citation_count
;;             far_index=[far_index,i]
;;             IF fix(ads_data[i].year) GT yr_last_paper THEN yr_last_paper=fix(ads_data[i].year)
;;           ENDIF
;;           swtch=1b
;;         ENDIF
;;       ENDFOR 
;;     ENDFOR
;;   ENDIF
;; ENDELSE 

;
; If we have first-author refereed papers, then populate the far_5 arrays.
;
far_5_ncit=intarr(5)-1
far_5_bcode=strarr(5)
far_5_title=strarr(5)
IF n_first_ref GT 0 THEN BEGIN 
  ads_data_far=ads_data_far
     ;
  yr=fix(ads_data_far.year)
  start_year_far=min(yr)
     ;
  cit_list=ads_data_far.citation_count
  j=reverse(sort(cit_list))
  cit_list=cit_list[j]
  nj=n_elements(j)
  h_far_index=-1
  i=0
  WHILE h_far_index LT 0 AND i LE nj-1 DO BEGIN
    IF i+1 GT cit_list[i] THEN h_far_index=i
    i=i+1
  ENDWHILE
  IF h_far_index EQ -1 THEN h_far_index=fix(nj)   ; in case min(citations) > nj
    ;
    ; The following records the five FAR papers with the highest
    ; citations in the last 5 years.
    ;
  k=where(ads_data_far.year GE curr_year-4,nk)
  IF nk GE 1 THEN BEGIN
    ncit=ads_data_far[k].citation_count
    icit=reverse(sort(ncit))
    n=min([nk,5])
    FOR i=0,n-1 DO BEGIN
      far_5_ncit[i]=ncit[icit[i]]
      far_5_bcode[i]=ads_data_far[k[icit[i]]].bibcode
      far_5_title[i]=ads_data_far[k[icit[i]]].title[0]
    ENDFOR 
  ENDIF 
ENDIF ELSE BEGIN
ENDELSE 


;
; Open the html file and write out the introduction text.
;
openw,lout,html_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Publications, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Publications of '+name+'</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+name+', derived from the ADS Abstracts Service. The number in brackets after each title indicates the number of citations that the paper has received.</p>'
IF n_elements(ads_library) NE 0 THEN BEGIN
  printf,lout,'<p>This publication list is also maintained as an <a href="'+ads_library+'">ADS library</a>.</p>'
ENDIF
IF n_elements(orcid) NE 0 THEN BEGIN
  orcid_link='https://orcid.org/'+trim(orcid)
  printf,lout,'<p>Orcid ID: <a href="'+orcid_link+'">'+trim(orcid)+'</a>.</p>'
ENDIF 
printf,lout,'<p><a href="'+out_file+'">List of publications ordered by citations</a><br>'
printf,lout,'Number of papers: '+trim(npapers)+' (refereed: '+trim(nref)+')<br>'
printf,lout,'No. of citations: '+trim(tot_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(h_index)+'<br>'
;
; The following handles the printing of the information about
; first-authored, refereed papers.
;
IF n_elements(n_first) NE 0 THEN BEGIN
  IF n_first_ref GT 0 THEN BEGIN
    html_basename=file_basename(html_file,'.html')
    html_fa_link=html_basename+'_first_author.html'
    html_fa_file=concat_dir(html_dir,html_fa_link)
    chck=file_search(html_fa_file,count=count)
    IF count NE 0 THEN file_delete,html_fa_file
 ;
    cit_first_author_html,ads_data_far,html_file=html_fa_file, h_index=h_far_index, $
                          author=author, link_author=link_author, name=name
    printf,lout,'First author papers: '+trim(n_first)+' (<a href="'+html_fa_link+'">refereed</a>: '+trim(n_first_ref)+')<br>'
  ENDIF ELSE BEGIN
    printf,lout,'First author papers: '+trim(n_first)+' (refereed: '+trim(n_first_ref)+')<br>'
  ENDELSE 
ENDIF 
;
; The following does a check on self-citation. For each publication in
; the author's list, the routine downloads the citing papers
; and checks if the first author matches the surname given by
; SELF_CITE_NAME. The author's "self-citation index" is the
; number of self-citations per paper. I only include refereed journal
; articles (doctype='article').
;
IF n_elements(self_cite_name) THEN BEGIN
  k=where(ads_data.doctype EQ 'article',nk)
  ad=ads_data[k]
  self_cite=intarr(nk)
  npap=nk
  FOR i=0,nk-1 DO BEGIN
    bibs=cit_get_citing_papers(ad[i].bibcode)
    s=cit_get_ads_entry(bibs)
    IF n_tags(s) NE 0 THEN BEGIN 
      ns=n_elements(s)
      count=0
      FOR j=0,ns-1 DO BEGIN
        IF s[j].author.count() GT 0 THEN BEGIN
          chck=strpos(strlowcase(s[j].author[0]),strlowcase(self_cite_name))
          IF chck GE 0 THEN count=count+1
        ENDIF 
      ENDFOR
    ENDIF ELSE BEGIN
      npap=npap-1   ; removed bad paper
    ENDELSE 
    self_cite[i]=count
  ENDFOR
  nsc=float(total(self_cite))/float(npap)
  printf,lout,'Self-citations: '+trim(string(format='(f7.2)',nsc))+' per paper'
ENDIF 

;
; Now go through each year and print out the entries for that year.
;
ostr=cit_write_year_list(ads_data,count=nstr)
FOR i=0,nstr-1 DO printf,lout,ostr[i]



IF n_elements(author) NE 0 THEN BEGIN
  foot_text='<p><i>This page mantained by '
  IF keyword_set(link_author) THEN BEGIN
    foot_text=foot_text+ $
         '<a href='+link_author+'>'+author+'</a>'
  ENDIF ELSE BEGIN
    foot_text=foot_text+author
  ENDELSE
  foot_text=foot_text+', l'
ENDIF ELSE BEGIN
  foot_text='<p><i>L'
ENDELSE
foot_text=foot_text+'ast revised on '+systime()+'</i>'

printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout


;
; Now print some information to the IDL window
;
IF NOT keyword_set(quiet) THEN print,html_file+' has been written.'


;
; Print out the second html file containing the most-cited papers.
;
i=reverse(sort(ads_data.citation_count))
;
; Open the html file and write out the introduction text.
;
out_file=concat_dir(html_dir,out_file)
openw,lout,out_file,/get_lun
printf,lout,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"> '
;
; The line below makes sure that the characters in the strings are
; printed correctly.
;
printf,lout,'<meta charset="utf-8"/>'
;
printf,lout,'<html>'
printf,lout,'<head>'
printf,lout,'<title>Publications ordered by citations, '+name+'</title>'
printf,lout,'</head>'
printf,lout,'<body  bgcolor="#FFFFFF" vlink="#CC33CC">'
printf,lout,'<center>'
printf,lout,'<table border=0 cellpadding=0 cellspacing=0 width=700>'
printf,lout,'<tbody>'
printf,lout,'<tr><td height=30></td></tr>'
printf,lout,'<tr><td align=left>'
printf,lout,'<h1>Publications of '+name+' ordered by citations</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+name+', derived from the ADS Abstracts Service and sorted by the numbers of citations. Publications above the horizontal line count towards the h-index.</p>'

printf,lout,'<p><table>'
swtch=0
FOR j=0,npapers-1 DO BEGIN
  k=i[j]
  cit_count=ads_data[k].citation_count
 ;
  IF cit_count LT h_index AND swtch EQ 0 THEN BEGIN
    printf,lout,'</table>'
    printf,lout,'<p><hr></p>'
    printf,lout,'<p><table>'
    swtch=1
  ENDIF 
 ;
  printf,lout,'<tr>'
  printf,lout,'<td valign=top cellpadding=4><b>'+trim(cit_count)+'</b>'
  IF ads_data[k].title.count() GT 0 THEN atitle=ads_data[k].title[0] ELSE atitle='No title'
  printf,lout,'<td><a href='+ads_data[k].ads_link+'>'+atitle+'</a><br>'
  printf,lout,ads_data[k].author_string+', '+ads_data[k].year+', '+ads_data[k].article_string
  printf,lout,'</tr>'
ENDFOR
printf,lout,'</table></p>'
printf,lout,'<p><hr>'
printf,lout,foot_text
printf,lout,'</p></td></tr></tbody></table></center></body></html>'

free_lun,lout

;
; Create the output data structure.
;
IF n_elements(n_first) EQ 0 THEN n_first=-1
IF n_elements(n_first_ref) EQ 0 THEN n_first_ref=-1
IF yr_last_paper EQ 1900 THEN yr_last_paper=-1
IF n_elements(h_far_index) EQ 0 THEN h_far_index=-1
;
jd=systime(/julian,/utc)
caldat,jd,m,d,y
far_year=indgen(5)+y-4
far_num=intarr(5)
IF n_first_ref GT 0 THEN BEGIN
   ad=ads_data_far
   FOR i=0,4 DO BEGIN
      k=where(fix(ad.year) EQ far_year[i],nk)
      far_num[i]=nk
   ENDFOR 
 ENDIF
;
; Get affiliation for the author's first FAR paper.
;
first_affil_country=''
IF n_tags(ads_data_far) NE 0 THEN BEGIN
  j=sort(ads_data_far.year)
  nfar=n_elements(ads_data_far)
  FOR i=0,nfar-1 DO BEGIN
    IF trim(ads_data_far[j[i]].country[0]) NE '' THEN BEGIN
      first_affil_country=ads_data_far[j[i]].country[0]
      BREAK
    ENDIF
  ENDFOR 
ENDIF 
;
; Get affiliation for the author's most-recent FAR paper. The routine
; cit_author_papers automatically sorts the papers in reverse-time order,
; so I just have to take the most recent paper
;
last_affil_country=''
curr_affil=''
IF n_tags(ads_data) NE 0 THEN BEGIN
  IF n_elements(orcid) NE 0 THEN BEGIN
    n=n_elements(ads_data)
    FOR i=0,n-1 DO BEGIN
      orc=ads_data[i].orcid.toarray()
      k=where(trim(orc) EQ trim(orcid),nk)
      IF nk NE 0 THEN BEGIN
        aff_str=ads_data[i].aff.toarray()
        curr_affil=aff_str[k[0]]
        last_affil_country=ads_data[i].country[k[0]]
        IF curr_affil NE '-' THEN break
      ENDIF
    ENDFOR 
  ENDIF 
ENDIF 


;
; For the keywords assigned to the author's papers, determine what fraction
; include 'sun' or 'solar'. This is taken as an indication of whether the
; author is a solar physicist. I require there to be at least 20 keywords
; to do the check.
;
keywords=''
n=n_elements(ads_data)
FOR i=0,n-1 DO BEGIN
  IF ads_data[i].keyword.count() NE 0 THEN BEGIN 
    keyw=ads_data[i].keyword.toarray()
    keywords=[keywords,keyw]
  ENDIF 
ENDFOR
IF n_elements(keywords) GT 20 THEN BEGIN
  keywords=keywords[1:*]
;
  chck1=strpos(strlowcase(keywords),'sun')
  chck2=strpos(strlowcase(keywords),'solar')
  swtch=(chck1 GE 0) OR (chck2 GE 0)
  k=where(swtch EQ 1b,nk)
;
  sun_keyword_frac=float(nk)/float(n_elements(keywords))
ENDIF ELSE BEGIN
  sun_keyword_frac=-1.
ENDELSE 

;
; Get a time stamp for the data.
;
jd=systime(/julian,/utc)
mjd=jd-2400000.5d
mjd_str={ mjd: floor(mjd), time: (mjd-floor(mjd))*8.64d7 }
time_stamp=anytim2utc(/ccsds,mjd_str,/trunc)
;
IF n_elements(orcid) EQ 0 THEN orc='' ELSE orc=orcid
;
IF n_elements(start_year_far) EQ 0 THEN start_year_far=-1
k=where(refereed EQ 1,nk)
IF nk NE 0 THEN start_year=min(fix(ads_data[k].year)) ELSE start_year=min(fix(ads_data.year))
out_data={ h_index: fix(h_index), $
           h_far_index: fix(h_far_index), $
           n_first: fix(n_first), $
           n_first_ref: fix(n_first_ref), $
           n_papers: fix(npapers), $
           n_papers_ref: fix(nref), $
           n_cit: tot_cit, $
           start_year: start_year, $
           start_year_far: start_year_far, $
           far_year: far_year, $
           far_num: far_num, $
           far_cit: far_cit, $
           yr_last_paper: yr_last_paper, $
           yr_last_paper_all: yr_last_paper_all, $
           first_affil_country: first_affil_country, $
           last_affil_country: last_affil_country, $
           curr_affil: curr_affil, $
           far_5_ncit: far_5_ncit, $ 
           far_5_bcode: far_5_bcode, $
           far_5_title: far_5_title, $
           orcid: orc, $
           sun_keyword_frac: sun_keyword_frac, $
           time_stamp: time_stamp}

save,file=save_file,out_data

END

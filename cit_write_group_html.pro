
PRO cit_write_group_html, group_struc, html_file=html_file, sort_col=sort_col, $
                          reverse=reverse, year_papers=year_papers, outdir=outdir, $
                          far_5=far_5, min_age=min_age, min_papers=min_papers

;+
; NAME:
;     CIT_WRITE_GROUP_HTML
;
; PURPOSE:
;     Writes out an html file giving a list of authors with their
;     citation statistics. To be used in conjunction with
;     CIT_AUTHOR_GROUP. 
;
; CATEGORY:
;     ADS; citations.
;
; CALLING SEQUENCE:
;     CIT_WRITE_GROUP_HTML, Group_Struc
;
; INPUTS:
;     Group_Struc:  The structure returned by CIT_AUTHOR_GROUP.
;
; OPTIONAL INPUTS:
;     Sort_Col:   By default the routine sorts the authors according
;                 to the year of their first paper. By specifying an
;                 integer corresponding to a column in the output file you
;                 can change which column is used.
;     Outdir:     A string specifying the output directory for the
;                 html files.
;     Min_Papers: Only list an author if they have at least MIN_PAPERS
;                 first-authored refereed papers.
;     Min_Age:    Only list an author if their age is greater or equal
;                 than MIN_AGE.
;	
; KEYWORD PARAMETERS:
;     REVERSE: By default the authors are arranged in ascending order
;              based on the numbers in the specified column. This
;              keyword reverses the order.
;     YEAR_PAPERS: If set, then an additional table is added, giving
;                  the numbers of first-authored, refereed papers for
;                  the last 5 years for all authors.
;     FAR_5:  If set, then an extra table is printed giving the 10
;             most-cited first-author papers of the last 5 years.
;
; OUTPUTS:
;     Creates the html file 'index.html' in the working directory
;     (unless OUTDIR specified) containing the author statistics. A
;     copy of this file with the current date appended (e.g.,
;     index_20220303.html) is placed in the sub-directory 'archive'. 
;
; EXAMPLE:
;     IDL> data=cit_author_group('authors.txt')
;     IDL> cit_write_group_html, data
;     IDL> cit_write_group_html, data, /year_papers
;
; MODIFICATION HISTORY:
;     Ver.1, 03-Mar-2022, Peter Young
;     Ver.2, 24-Mar-2022, Peter Young
;       Added the keyword /far_5.
;     Ver.3, 14-Oct-2022, Peter Young
;       Added column for career origin country; added output table giving
;       demographics information.
;     Ver.4, 08-Dec-2022, Peter Young
;       Added MIN_AGE= and MIN_PAPERS= optional inputs.
;-


IF n_params() LT 1 THEN BEGIN
  print,' Use: IDL> cit_write_group_html, data [, sort_col=, outdir=, /reverse, /year_papers, /far_5 ]'
  return 
ENDIF 

IF n_elements(min_papers) EQ 0 THEN min_papers=1
IF n_elements(min_papers) EQ 0 THEN min_age=-1

;
; Get today's date
;
jd=systime(/julian,/utc)
mjd=jd-2400000.5d
mjd_str={ mjd: floor(mjd), time: (mjd-floor(mjd))*8.64d7 }
t_utc=anytim2utc(/ccsds,mjd_str)
date_str=time2fid(t_utc,/full_year)

;
; The following sets up the locations of the output files. 
;
html_file='index.html'
backup_file='index_'+date_str+'.html'
archive_dir='archive'
IF n_elements(outdir) NE 0 THEN BEGIN
  chck=file_info(outdir)
  IF chck.directory EQ 0 THEN file_mkdir,outdir
 ;
  html_file=concat_dir(outdir,html_file)
  archive_dir=concat_dir(outdir,archive_dir)
ENDIF 
chck=file_info(archive_dir)
IF chck.directory EQ 0 THEN file_mkdir,archive_dir
backup_file=concat_dir(archive_dir,backup_file)

;; IF n_elements(html_file) EQ 0 THEN BEGIN
;;    html_file='index.html'
;;    archive_dir='archive'
;;    date_file='index_'+date_str+'.html'
;; ENDIF ELSE BEGIN
;;    dir=file_dirname(html_file)
;;    fname=file_basename(html_file,'.html')
;;    fname=fname+'_'+date_str+'.html'
;;    IF dir NE '' THEN BEGIN
;;      archive_dir=concat_dir(dir,'archive')
;;      date_file=concat_dir(dir,fname)
;;    ENDIF ELSE BEGIN
;;    ENDELSE 
;; ENDELSE 

title=group_struc.title

openw,lout,html_file,/get_lun
printf,lout,'<p><table border=1 cellpadding=3>'
IF n_elements(title) NE 0 THEN BEGIN 
  printf,lout,'<tr><td colspan=13><b>'+title+'</br></tr>'
ENDIF 
printf,lout,'<tr><td align="center"><b>Name<td><b>Career origin</b><td><b>Career start<td><b>Years<td><b>h-index<td><b>far-index<td><b>Citations<td><b>No. 1st, refereed<td><b>h-years<td><b>far-years/2<td><b>1st per year<td><b>Yrs since last<td><b>Category</tr>'

IF n_elements(sort_col) EQ 0 THEN sort_col=4

data=group_struc.data

n=n_elements(data)

CASE sort_col OF
  2: k=sort(data.h_index)
  3: k=sort(data.n_cit)
  5: k=sort(data.h_years)
  6: k=sort(data.n_first_ref)
  7: k=sort(data.yrs_since_last)
  ELSE: k=sort(data.start_year_far)
ENDCASE
IF keyword_set(reverse) THEN k=reverse(k)

d=data[k]

FOR i=0,n-1 DO BEGIN
  IF d[i].years_far GE min_age AND d[i].n_first_ref GE min_papers THEN BEGIN 
    printf,lout,'<tr>'
    printf,lout,'<td align="center"><a href="'+d[i].htmlfile+'">'+d[i].name+'</a>'
    printf,lout,'<td align="center">'+d[i].first_affil_country
    printf,lout,'<td align="center">'+trim(d[i].start_year_far)
    printf,lout,'<td align="center">'+trim(d[i].years_far)
    printf,lout,'<td align="center">'+trim(d[i].h_index)
    printf,lout,'<td align="center">'+trim(d[i].h_far_index)
    printf,lout,'<td align="center">'+trim(d[i].n_cit)
    printf,lout,'<td align="center">'+trim(d[i].n_first_ref)
 ;
    IF d[i].h_years GT 0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
    printf,lout,'<td align="center">'+bstr[0]+trim(d[i].h_years)+bstr[1]
 ;
    IF d[i].h_far_years GT 0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
    printf,lout,'<td align="center">'+bstr[0]+trim(d[i].h_far_years)+bstr[1]
 ;
    first_ratio=d[i].n_first_ref/float(d[i].years_far)
    IF first_ratio GE 1.0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
    printf,lout,'<td align="center">'+bstr[0]+trim(string(format='(f4.2)',first_ratio))+bstr[1]
 ;
    IF d[i].yrs_since_last LE 2 AND d[i].yrs_since_last GE 0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
    IF d[i].yrs_since_last EQ -1 THEN yrs_since_last='-' ELSE yrs_since_last=trim(d[i].yrs_since_last)+bstr[1]
    printf,lout,'<td align="center">'+bstr[0]+yrs_since_last
    printf,lout,'<td align="center">'+d[i].category
  ENDIF 
ENDFOR

printf,lout,'</table></p>'

;
; Write table summarizing total papers each year
;
IF keyword_set(year_papers) THEN BEGIN
   printf,lout,'<p><table border=1 cellpadding=3>'
   printf,lout,'<tr><td colspan=7><b>Numbers of first-authored papers in last 5 years.</b></td>'
   far_year=d[0].far_year
   nf=n_elements(far_year)
   tstr='<tr><td><b>Name<b></td>'
   FOR i=0,nf-1 DO tstr=tstr+'<td align="center"><b>'+trim(far_year[i])+'</b></td>'
   tstr=tstr+'<td align="center"><b>Total</b></td></tr>'
   printf,lout,tstr
  ;
   FOR i=0,n-1 DO BEGIN
      far_num=d[i].far_num
      astr='<tr><td>'+d[i].name+'</td>'
      FOR j=0,nf-1 DO astr=astr+'<td align="center">'+trim(far_num[j])+'</td>'
      printf,lout,astr+'<td align="center"><b>'+trim(total(far_num))+'</b></td></tr>'
   ENDFOR
  ;
   bstr='<tr><td><b>Total</b></td>'
   tot_far_num=fix(total(d.far_num,2))
   FOR i=0,nf-1 DO bstr=bstr+'<td align="center"><b>'+trim(tot_far_num[i])+'</b></td>'
   printf,lout,bstr+'<td align="center"><b>'+trim(total(tot_far_num))+'</b></td></tr>'
   printf,lout,'</table></p>'
ENDIF 


;
; Write table with the 10 most-cited FAR papers in the last 5 years.
;
IF keyword_set(far_5) AND tag_exist(group_struc,'far_5') THEN BEGIN 
  n=n_elements(group_struc.far_5.ncit)
  printf,lout,'<p><table border=1 cellpadding=3>'
  printf,lout,'<tr><td colspan=3><b>Most cited first-authored papers in last 5 years</b></td>'
  printf,lout,'<tr><td><b>Citations</b></td><td><b>Name</b></td><td><b>Bibcode</b></td>'
  FOR i=0,n-1 DO BEGIN
    bcode=trim(group_struc.far_5.bcode[i])
    blink='https://ui.adsabs.harvard.edu/abs/'+bcode+'/abstract'
    printf,lout,'<tr><td align="center">'+trim(group_struc.far_5.ncit[i])+'</td>'+ $
           '<td>'+trim(group_struc.far_5.name[i])+'</td>'+ $
           '<td><a href="'+blink+'">'+bcode+'</a></td></tr>'
  ENDFOR
  printf,lout,'</table></p>'
ENDIF 


;
; For the citation criteria, I only want to use people whose career is 5 years or more. I thus
; defined "data2" to contain this subset of authors. The demographics data will use "data".
;
k=where(data.years_far GE 5)
data2=data[k]
nd2=n_elements(data2)

printf,lout,'<p><table border=1 cellpadding=3>'
printf,lout,'<tr><td colspan=3><b>Demographics</b></td>'
nd=n_elements(data)
printf,lout,'<tr><td>No. of group members</td><td>'+trim(nd)+'<td></tr>'
;
k=where(data.first_affil_country EQ 'US',nk)
printf,lout,'<tr><td>No. of US-born researchers</td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
printf,lout,'<tr><td>No. of foreign-born researchers</td><td>'+trim(nd-nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*(nd-nk)/nd))+'%</td></tr>'
k=where(data.years_far le 15,nk)
printf,lout,'<tr><td>No. of junior researchers (<16 yrs)</td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
k=where(data.years_far GT  15 AND data.years_far LE 35,nk)
printf,lout,'<tr><td>No. of mid-career researchers </td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
k=where(data.years_far GT 35,nk)
printf,lout,'<tr><td>No. of senior researchers (>35 yrs)</td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
printf,lout,'<tr><td>Median age </td><td>'+trim(median(data.years_far))+'</td><td></tr>'
av_pap=total(d.far_num)/5.0/nd
printf,lout,'<tr><td>Average papers per year per researcher (5 years) </td><td>'+ $
       trim(string(format='(f10.2)',av_pap))+'</td><td></tr>'
av_cit=mean(group_struc.far_5.ncit)
printf,lout,'<tr><td>Average citations (top-10 papers)</td><td>'+ $
       trim(string(format='(i4)',av_cit))+'</td><td></tr>'
printf,lout,'<tr><td>No. group members (> 4 years)</td><td>'+trim(nd2)+ $
       '</td><td></tr>'
k=where(data2.yrs_since_last LE 2,nk)
printf,lout,'<tr><td>No. achieving C1</td><td>'+trim(nk)+ $
       '</td><td>'+ trim(string(format='(i4)',100.*nk/nd2))+'%</tr>'
jd=systime(/julian,/utc)
caldat,jd,month,dday,yr
ratio=data2.n_first_ref/(yr-data2.start_year_far+1)
k=where(ratio GE 1,nk)
printf,lout,'<tr><td>No. achieving C2</td><td>'+trim(nk)+ $
       '</td><td>'+ trim(string(format='(i4)',100.*nk/nd2))+'%</tr>'
k=where(data2.h_far_years GT 0,nk)
printf,lout,'<tr><td>No. achieving C3</td><td>'+trim(nk)+ $
       '</td><td>'+ trim(string(format='(i4)',100.*nk/nd2))+'%</tr>'
k=where(data2.category EQ 'A',nk)
printf,lout,'<tr><td>No. of Cat. A staff</td><td>'+trim(nk)+ $
       '</td><td>'+ trim(string(format='(i4)',100.*nk/nd2))+'%</tr>'


printf,lout,'</table></p>'



free_lun,lout

file_copy,html_file,backup_file,/overwrite

print,'% CIT_WRITE_GROUP_HTML: The index file, '+html_file+', has been written.'

END

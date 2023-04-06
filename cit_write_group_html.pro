
PRO cit_write_group_html, group_struc, html_file=html_file, sort_col=sort_col, $
                          reverse=reverse, year_papers=year_papers, outdir=outdir, $
                          far_5=far_5, min_age=min_age, min_papers=min_papers, $
                          solar_only=solar_only

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
;     SOLAR_ONLY: If set, then only researchers with sun_keyword_frac >
;             0.10 are listed
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
;     Ver.5, 07-Jan-2023, Peter Young
;       Made some updates to html formatting; added /solar_only.
;-


IF n_params() LT 1 THEN BEGIN
  print,' Use: IDL> cit_write_group_html, data [, sort_col=, outdir=, /reverse, /year_papers, /far_5 ]'
  return 
ENDIF 

IF n_elements(min_papers) EQ 0 THEN min_papers=1
IF n_elements(min_age) EQ 0 THEN min_age=-1
IF n_elements(sort_col) EQ 0 THEN sort_col=4

top_dir=group_struc.top_dir

cat_type=group_struc.cat_type

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
html_file=concat_dir(top_dir,'index.html')
backup_file='index_'+date_str+'.html'
archive_dir=concat_dir(top_dir,'archive')
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

ncols=15
IF cat_type NE 2 THEN ncols=ncols+1

data=group_struc.data
n=n_elements(data)

;
; This is the number of FAR papers per year (column 14)
;
first_ratio=data.n_first_ref/float(data.years_far)


cols=make_array(/string,ncols,value='white')
bgcolor='lightgoldenrodyellow'

CASE sort_col OF
  4: BEGIN
    k=sort(data.start_year_far)
    cols[3]=bgcolor
  END
  6: BEGIN
    k=sort(data.num)
    cols[5]=bgcolor
  END
  7: BEGIN
    k=sort(data.n_cit)
    cols[6]=bgcolor
  END 
  8: BEGIN
    k=sort(data.h_index)
    cols[7]=bgcolor
  END 
  9: BEGIN
    k=sort(data.h_years)
    cols[8]=bgcolor
  END 
  10: BEGIN
    k=sort(data.n_first_ref)
    cols[9]=bgcolor
  END 
  11: BEGIN
    k=sort(data.far_cit)
    cols[10]=bgcolor
  END  
  12: BEGIN
    k=sort(data.h_far_index)
    cols[11]=bgcolor
  END 
  13: BEGIN
    k=sort(data.yrs_since_last)
    cols[12]=bgcolor
  END 
  14: BEGIN
    k=sort(first_ratio)
    cols[13]=bgcolor
  END 
  15: BEGIN
    k=sort(data.h_far_years)
    cols[14]=bgcolor
  END 
  ELSE: BEGIN
    k=sort(surname)
    cols[0]=bgcolor
  END 
ENDCASE
IF keyword_set(reverse) THEN k=reverse(k)

d=data[k]
first_ratio=first_ratio[k]


openw,lout,html_file,/get_lun
printf,lout,'<p><table border=1 cellpadding=3>'
IF n_elements(title) NE 0 THEN BEGIN 
  printf,lout,'<tr><td colspan='+trim(ncols)+'><b>'+title+'</br></tr>'
ENDIF
header0='<tr><td colspan=5>' +$
        '<td colspan=4 align="center"><b>All papers' + $
        '<td colspan=6 align="center"><b>First-author refereed papers only'
header='<tr><td align="center" style="background-color:'+cols[1]+'";><b>Name'+ $
       '<td align="center" style="background-color:'+cols[1]+'";><b>Career origin</b>' + $
       '<td align="center" style="background-color:'+cols[2]+'";><b>Country</b>' + $
       '<td align="center" style="background-color:'+cols[3]+'";><b>Career start'+ $
       '<td align="center" style="background-color:'+cols[4]+'";><b>Years' + $
       '<td align="center" style="background-color:'+cols[5]+'";><b>No. papers' + $
       '<td align="center" style="background-color:'+cols[6]+'";><b>Citations' + $
       '<td align="center" style="background-color:'+cols[7]+'";><b>h-index' + $
       '<td align="center" style="background-color:'+cols[8]+'";><b>h-years' + $
       '<td align="center" style="background-color:'+cols[9]+'";><b>No. papers' + $
       '<td align="center" style="background-color:'+cols[10]+'";><b>Citations' + $
       '<td align="center" style="background-color:'+cols[11]+'";><b>f-index' + $
       '<td align="center" style="background-color:'+cols[12]+'";><b>Yrs since last' + $
       '<td align="center" style="background-color:'+cols[13]+'";><b>Papers/year' + $
       '<td align="center" style="background-color:'+cols[14]+'";><b>f-years/2</td>'

IF ncols NE 2 THEN BEGIN
  header0=header0+'<td>'
  header=header+'<td><b>Category</tr>'
ENDIF 
printf,lout,header0
printf,lout,header




surname=strarr(n)
FOR i=0,n-1 DO BEGIN
  bits=data[i].name.split(' ')
  surname[i]=bits[-1]
ENDFOR 


;
; Filter using min_age and min_papers
;
k=where(d.years_far GE min_age AND d.n_first_ref GE min_papers,nk)
IF nk NE n THEN BEGIN
  message,/info,/CONTINUE,'Removed '+trim(n-nk)+' authors due to MIN_AGE and/or MIN_PAPERS keywords.'
ENDIF 
IF nk NE 0 THEN d=d[k]

n=n_elements(d)

;
; Filter on solar keyword fraction
;
IF keyword_set(solar_only) THEN BEGIN
  k=where(d.sun_keyword_frac GE 0.1 OR d.sun_keyword_frac EQ -1.,nk)
  IF nk NE n THEN BEGIN
    message,/info,/CONTINUE,'Removed '+trim(n-nk)+' authors due to SOLAR_ONLY keyword.'
  ENDIF 
  IF nk NE 0 THEN d=d[k]
ENDIF

n=n_elements(d)



FOR i=0,n-1 DO BEGIN
  printf,lout,'<tr>'
  printf,lout,'<td align="center" style="background-color:'+cols[0]+'";><a href="'+d[i].htmlfile+'">'+d[i].name+'</a>'
  printf,lout,'<td align="center" style="background-color:'+cols[1]+'";>'+d[i].first_affil_country
  printf,lout,'<td align="center" style="background-color:'+cols[2]+'";>'+d[i].last_affil_country
  printf,lout,'<td align="center" style="background-color:'+cols[3]+'";>'+trim(d[i].start_year_far)
  printf,lout,'<td align="center" style="background-color:'+cols[4]+'";>'+trim(d[i].years_far)
  printf,lout,'<td align="center" style="background-color:'+cols[5]+'";>'+trim(d[i].num)
  printf,lout,'<td align="center" style="background-color:'+cols[6]+'";>'+trim(d[i].n_cit)
  printf,lout,'<td align="center" style="background-color:'+cols[7]+'";>'+trim(d[i].h_index)
  printf,lout,'<td align="center" style="background-color:'+cols[8]+'";>'+trim(d[i].h_years)
  printf,lout,'<td align="center" style="background-color:'+cols[9]+'";>'+trim(d[i].n_first_ref)
 ;
  printf,lout,'<td align="center" style="background-color:'+cols[10]+'";>'+trim(d[i].far_cit)
  printf,lout,'<td align="center" style="background-color:'+cols[11]+'";>'+trim(d[i].h_far_index)
 ;
  IF d[i].yrs_since_last LE 2 AND d[i].yrs_since_last GE 0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
  IF d[i].yrs_since_last EQ -1 THEN yrs_since_last='-' ELSE yrs_since_last=trim(d[i].yrs_since_last)+bstr[1]
  printf,lout,'<td align="center">'+bstr[0]+yrs_since_last
 ;
  IF first_ratio[i] GE 1.0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
  printf,lout,'<td align="center" style="background-color:'+cols[13]+'";>'+ $
         bstr[0]+trim(string(format='(f4.2)',first_ratio[i]))+bstr[1]
 ;
  IF d[i].h_far_years GT 0 THEN bstr=['<b>','</b>'] ELSE bstr=['','']
  printf,lout,'<td align="center" style="background-color:'+cols[14]+'";>'+bstr[0]+trim(d[i].h_far_years)+bstr[1]
 ;
  IF cat_type NE 2 THEN printf,lout,'<td align="center">'+d[i].category
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
   IF n GT 1 THEN BEGIN 
     bstr='<tr><td><b>Total</b></td>'
     tot_far_num=fix(total(d.far_num,2))
     FOR i=0,nf-1 DO bstr=bstr+'<td align="center"><b>'+trim(tot_far_num[i])+'</b></td>'
     printf,lout,bstr+'<td align="center"><b>'+trim(total(tot_far_num))+'</b></td></tr>'
   ENDIF 
   printf,lout,'</table></p>'
ENDIF 


;
; Write table with the 10 most-cited FAR papers in the last 5 years.
;
IF keyword_set(far_5) AND tag_exist(group_struc,'far_5') THEN BEGIN 
  n=n_elements(group_struc.far_5.ncit)
  printf,lout,'<p><table border=1 cellpadding=3>'
  printf,lout,'<tr><td colspan=4><b>Most cited first-authored papers in last 5 years</b></td>'
  printf,lout,'<tr><td><b>Citations</b></td><td><b>Name</b></td><td><b>Bibcode</b><td><b>Title</td>'
  FOR i=0,n-1 DO BEGIN
    bcode=trim(group_struc.far_5.bcode[i])
    title=cit_clean_names(strpad(trim(string(format='(a70)',group_struc.far_5.title[i])),70,fill=' '))
    blink='https://ui.adsabs.harvard.edu/abs/'+bcode+'/abstract'
    printf,lout,'<tr><td align="center">'+trim(group_struc.far_5.ncit[i])+'</td>'+ $
           '<td>'+trim(group_struc.far_5.name[i])+'</td>'+ $
           '<td><a href="'+blink+'">'+bcode+'</a></td>'+ $
           '<td><a href="'+blink+'">'+title+'</a></td></tr>'
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
printf,lout,'<tr><td>No. of US-origin researchers</td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
printf,lout,'<tr><td>No. of foreign-origin researchers</td><td>'+trim(nd-nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*(nd-nk)/nd))+'%</td></tr>'
k=where(data.last_affil_country EQ 'US',nk)
printf,lout,'<tr><td>No. of US researchers</td><td>'+trim(nk)+'</td><td>'+ $
       trim(string(format='(i4)',100.*nk/nd))+'%</td></tr>'
printf,lout,'<tr><td>No. of foreign researchers</td><td>'+trim(nd-nk)+'</td><td>'+ $
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
IF cat_type NE 2 THEN BEGIN
  k=where(data2.category EQ '*',nk)
  printf,lout,'<tr><td>No. of starred staff</td><td>'+trim(nk)+ $
         '</td><td>'+ trim(string(format='(i4)',100.*nk/nd2))+'%</tr>'
ENDIF 

printf,lout,'</table></p>'



free_lun,lout

file_copy,html_file,backup_file,/overwrite

print,'% CIT_WRITE_GROUP_HTML: The index file, '+html_file+', has been written.'

END

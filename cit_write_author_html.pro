
PRO cit_write_author_html, author_data, ads_data, outfile=outfile, outdir=outdir, $
                           ads_data_far=ads_data_far


IF n_params() LT 2 THEN BEGIN
  print,'Use:  IDL> cit_write_author_html, author_data, ads_data [, outfile=, outdir='
  print,'                      ads_data_far= ]'
  return
ENDIF 

IF keyword_set(far_only) THEN file_ext='_first_author' ELSE file_ext=''
IF keyword_set(cit_sort) THEN file_ext=file_ext+'_cit'


IF n_elements(outdir) NE 0 THEN BEGIN
  chck=file_info(outdir)
  IF chck.exists EQ 0 THEN file_mkdir,outdir
ENDIF ELSE BEGIN
  outdir='.'
ENDELSE 

orcid=author_data.author.orcid

IF n_tags(ads_data_far) EQ 0 THEN BEGIN
  ads_data_far=cit_filter_ads_data(ads_data,orcid=orcid,/ref)
ENDIF 

;
; The following isn't very elegant, but I do it to get n_papers for
; the first-author papers (including non-refereed) which can't be
; obtained from ads_data_far.
;
ads_data_first_author=cit_filter_ads_data(ads_data,orcid=orcid)
author_data.far.n_papers=n_elements(ads_data_first_author)

;
; Get filenames for the four output html files.
;
file_base=trim(orcid)
outfile=file_base+'.html'
outfile_cit=file_base+'_cit.html'
outfile_far=file_base+'_far.html'
outfile_far_cit=file_base+'_far_cit.html'

full_name=author_data.author.name

;
; PAGE 1
; ------
; Write the main page showing all papers sorted by year.
;
write_file=concat_dir(outdir,outfile)
openw,lout,write_file,/get_lun
cit_write_header_html,lout,title='All papers of '+full_name+', sorted by publication year'
;
printf,lout,'<h1>Publications of '+full_name+'</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+full_name+', derived from the SAO/NASA Astrophysics Data System (ADS). The number in brackets after each title indicates the number of citations that the paper has received.</p>'

IF n_elements(orcid) NE 0 THEN BEGIN
  orcid_link='https://orcid.org/'+trim(orcid)
  printf,lout,'<p>Orcid ID: <a href="'+orcid_link+'">'+trim(orcid)+'</a></p>'
ENDIF 
printf,lout,'<p><a href="'+outfile_cit+'">List of publications ordered by citations</a><br>'
printf,lout,'Number of papers: '+trim(author_data.all.n_papers)+' (refereed: '+trim(author_data.all.n_papers_ref)+')<br>'
printf,lout,'No. of citations: '+trim(author_data.all.n_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(author_data.all.h_index)+'<br>'
printf,lout,'First author papers: '+trim(author_data.far.n_papers)+' (<a href="'+outfile_far+'">refereed</a>: '+trim(author_data.far.n_papers_ref)+')<br>'
;
; Now go through each year and print out the entries for that year.
;
ostr=cit_write_year_list(ads_data,count=nstr)
FOR i=0,nstr-1 DO printf,lout,ostr[i]
;
cit_write_footer_html,lout
free_lun,lout


;
; PAGE 2
; ------
; Write the main page showing all papers sorted by citations.
;
write_file=concat_dir(outdir,outfile_cit)
openw,lout,write_file,/get_lun
cit_write_header_html,lout,title='All papers of '+full_name+', sorted by citations'
;
printf,lout,'<h1>Publications of '+full_name+' ordered by citations</h1>'
printf,lout,'<p>A list of publications authored or co-authored by '+full_name+', derived from the SAO/NASA Astrophysics Data System (ADS) and ordered by the numbers of citations. Publications above the horizontal line count towards the h-index.'

IF n_elements(orcid) NE 0 THEN BEGIN
  orcid_link='https://orcid.org/'+trim(orcid)
  printf,lout,'<p>Orcid ID: <a href="'+orcid_link+'">'+trim(orcid)+'</a></p>'
ENDIF 
printf,lout,'Number of papers: '+trim(author_data.all.n_papers)+'<br>'
printf,lout,'No. of citations: '+trim(author_data.all.n_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(author_data.all.h_index)+'<br>'
;
; Now go through each year and print out the entries for that year.
;
ostr=cit_write_cit_list(ads_data,author_data.all.h_index,count=nstr)
FOR i=0,nstr-1 DO printf,lout,ostr[i]
;
cit_write_footer_html,lout
free_lun,lout


;
; PAGE 3
; ------
; Write the page showing only FAR papers, sorted by year.
;
write_file=concat_dir(outdir,outfile_far)
openw,lout,write_file,/get_lun
cit_write_header_html,lout,title='First-authored, refereed publications of '+full_name
;
printf,lout,'<h1>First-authored, refereed papers of '+full_name+'</h1>'
printf,lout,'<p>A list of first-authored, refereed publications of '+full_name+', derived from the SAO/NASA Astrophysics Data System (ADS). The number in brackets after each title indicates the number of citations that the paper has received.</p>'

IF n_elements(orcid) NE 0 THEN BEGIN
  orcid_link='https://orcid.org/'+trim(orcid)
  printf,lout,'<p>Orcid ID: <a href="'+orcid_link+'">'+trim(orcid)+'</a></p>'
ENDIF 
printf,lout,'<p><a href="'+outfile_far_cit+'">List of publications ordered by citations</a><br>'
printf,lout,'Number of papers: '+trim(author_data.far.n_papers_ref)+'<br>'
printf,lout,'No. of citations: '+trim(author_data.far.n_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(author_data.far.h_index)
;
; Now go through each year and print out the entries for that year.
;
ostr=cit_write_year_list(ads_data_far,count=nstr)
FOR i=0,nstr-1 DO printf,lout,ostr[i]
;
cit_write_footer_html,lout
free_lun,lout



;
; PAGE 4
; ------
; Write the page showing only FAR papers, sorted by citations.
;
write_file=concat_dir(outdir,outfile_far_cit)
openw,lout,write_file,/get_lun
cit_write_header_html,lout,title='First-authored, refereed papers of '+full_name+', ordered by citations'
;
printf,lout,'<h1>First-authored, refereed papers of '+full_name+' ordered by citations</h1>'
printf,lout,'<p>A list of first-authored, refereed publications of  '+full_name+', derived from the SAO/NASA Astrophysics Data System (ADS) and ordered by the numbers of citations. Publications above the horizontal line count towards the h-index.'

IF n_elements(orcid) NE 0 THEN BEGIN
  orcid_link='https://orcid.org/'+trim(orcid)
  printf,lout,'<p>Orcid ID: <a href="'+orcid_link+'">'+trim(orcid)+'</a></p>'
ENDIF 
printf,lout,'Number of papers: '+trim(author_data.far.n_papers_ref)+'<br>'
printf,lout,'No. of citations: '+trim(author_data.far.n_cit)+'<br>'
printf,lout,'<a href=http://en.wikipedia.org/wiki/H-index>h-index</a>: '+trim(author_data.far.h_index)+'<br>'
;
; Now go through each year and print out the entries for that year.
;
ostr=cit_write_cit_list(ads_data_far,author_data.far.h_index,count=nstr)
FOR i=0,nstr-1 DO printf,lout,ostr[i]
;
cit_write_footer_html,lout
free_lun,lout



END

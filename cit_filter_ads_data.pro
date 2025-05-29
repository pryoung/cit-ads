function cit_filter_ads_data, ads_data, thesis = thesis, count = count, $
  year = year, refereed = refereed, $
  min_year = min_year, max_year = max_year, $
  start_pubdate=start_pubdate, end_pubdate = end_pubdate
  compile_opt idl2

  ;+
  ; NAME:
  ;     CIT_FILTER_ADS_DATA
  ;
  ; PURPOSE:
  ;     Performs some standard filtering of the ADS data structure, based
  ;     on doctype, year and whether articles are refereed.
  ;
  ; CATEGORY:
  ;     ADS; filter.
  ;
  ; CALLING SEQUENCE:
  ;     Result = CIT_FILTER_ADS_DATA( Ads_Data )
  ;
  ; INPUTS:
  ;     Ads_Data:  An IDL structure containing ADS data in the format
  ;                returned by cit_get_ads_entry.pro.
  ;
  ; OPTIONAL INPUTS:
  ;     Year:   An integer specifying a year. Only papers published in this
  ;             year will be returned.
  ;     Min_Year:  An integer specifying a year. Only papers published from
  ;                this year onwards will be returned.
  ;     Max_Year:  An integer specifying a year. Only papers published from
  ;                this year and earlier will be returned.
  ;     Start_Pubdate: A string specifying a date in a standard SSW format
  ;                  that specifies the earliest publication date (pubdate) an
  ;                  article can have.
  ;     End_Pubdate: A string specifying a date in a standard SSW format
  ;                  that specifies the latest publication date (pubdate) an
  ;                  article can have.
  ;
  ; KEYWORD PARAMETERS:
  ;     REFEREED:  If set, then only refereed papers will be returned, as
  ;                identified by the refereed tag in ADS_DATA.
  ;     THESIS:  If set, then any doctypes including the word "thesis" are
  ;              kept.
  ;
  ; OUTPUTS:
  ;     A structure in the same format as ADS_DATA but with a reduced number
  ;     of entries based on the doctype tag. If the filtering
  ;     results in no entries then a value of -1 will be returned and COUNT
  ;     will be set to zero.
  ;
  ; OPTIONAL OUTPUTS:
  ;     Count:  The number of entries in the output structure.
  ;
  ; EXAMPLE:
  ;     IDL> new_data=cit_filter_ads_data(ads_data)
  ;     IDL> new_data=cit_filter_ads_data(ads_data,/refereed)
  ;     IDL> new_data=cit_filter_ads_data(ads_data,year=2022)
  ;
  ; MODIFICATION HISTORY:
  ;     Ver.1, 09-Nov-2023, Peter Young
  ;     Ver.2, 27-Nov-2023, Peter Young
  ;       Added min_year= and max_year= optional inputs.
  ;     Ver.3, 12-Dec-2023, Peter Young
  ;       Now filters out SHINE abstracts.
  ;     Ver.4, 01-Apr-2024, Peter Young
  ;       Now removes preface articles.
  ;     Ver.5, 03-Apr-2024, Peter Young
  ;       Fixed a bug introduced in v.4.
  ;     Ver.6, 02-May-2024, Peter Young
  ;       Added end_pubdate= optional input.
  ;     Ver.7, 07-Jan-2025, Peter Young
  ;       Now removes publisher's notes, thank you, and corrigenda articles.
  ;     Ver.8, 06-Mar-2025, Peter Young
  ;       Now removes articles with titles that begin with "correction".
  ;     Ver.9, 06-May-2025, Peter Young
  ;       Added start_pubdate= optional input.
  ;     Ver.10, 29-May-2025, Peter Young
  ;       Removed a rogue print statement.
  ;-

  count = 0

  ads_data_out = ads_data

  if n_elements(year) ne 0 and (n_elements(min_year) ne 0 or n_elements(max_year) ne 0) then begin
    message, /info, /cont, 'You must specify either YEAR= or MIN_YEAR= [MAX_YEAR=], but not both. Returning...'
    return, -1
  endif

  ;
  ; Filter on the year.
  ;
  if n_elements(year) ne 0 then begin
    k = where(fix(ads_data_out.year) eq year, nk)
    if nk eq 0 then begin
      count = 0
      return, -1
    endif else begin
      ads_data_out = ads_data_out[k]
    endelse
  endif

  if n_elements(min_year) ne 0 then begin
    k = where(fix(ads_data_out.year) ge min_year, nk)
    if nk eq 0 then begin
      count = 0
      return, -1
    endif else begin
      ads_data_out = ads_data_out[k]
    endelse
  endif

  if n_elements(max_year) ne 0 then begin
    k = where(fix(ads_data_out.year) le max_year, nk)
    if nk eq 0 then begin
      count = 0
      return, -1
    endif else begin
      ads_data_out = ads_data_out[k]
    endelse
  endif

  if n_elements(start_pubdate) ne 0 then begin
    jd_ref = anytim2jd(start_pubdate)
    jd_ref = jd_ref.int
    pubdate_jd = anytim2jd(ads_data_out.pubdate)
    pubdate_jd = pubdate_jd.int
    k = where(pubdate_jd ge jd_ref, nk)
    if nk eq 0 then begin
      count = 0
      return, -1
    endif else begin
      ads_data_out = ads_data_out[k]
    endelse
  endif

  if n_elements(end_pubdate) ne 0 then begin
    jd_ref = anytim2jd(end_pubdate)
    jd_ref = jd_ref.int
    pubdate_jd = anytim2jd(ads_data_out.pubdate)
    pubdate_jd = pubdate_jd.int
    k = where(pubdate_jd le jd_ref, nk)
    if nk eq 0 then begin
      count = 0
      return, -1
    endif else begin
      ads_data_out = ads_data_out[k]
    endelse
  endif

  ;
  ; Select only refereed articles.
  ;
  if keyword_set(refereed) then begin
    k = where(ads_data_out.refereed eq 1, nk)
    if nk ne 0 then begin
      ads_data_out = ads_data_out[k]
    endif else begin
      count = 0
      return, -1
    endelse
  endif

  ;
  ; SHINE conference abstracts get listed as "inproceedings" in ADS
  ; for some reason, so I remove them here.
  ;
  chck = strmid(ads_data_out.bibcode, 4, 9)
  k = where(chck ne 'shin.conf', nk)
  ads_data_out = ads_data_out[k]

  ;
  ; If /thesis has not been set, then remove doctypes containing "thesis".
  ;
  if not keyword_set(thesis) then begin
    chck = strpos(ads_data_out.doctype, 'thesis')
    k = where(chck lt 0, nk)
    ads_data_out = ads_data_out[k]
  endif

  ;
  ; Remove any preface articles, which are identified by having "preface"
  ; as the first word of the title.
  ;
  n = n_elements(ads_data_out)
  all_titles = strarr(n)
  for i = 0, n - 1 do begin
    if ads_data_out[i].title.count() gt 0 then all_titles[i] = ads_data_out[i].title[0]
  endfor
  chck = strpos(strlowcase(all_titles), 'preface')
  k = where(chck ne 0)
  ads_data_out = ads_data_out[k]

  ;
  ; Remove articles that begin with "thank you". These are usually from
  ; editors thanking their reviewers.
  ;
  n = n_elements(ads_data_out)
  all_titles = strarr(n)
  for i = 0, n - 1 do begin
    if ads_data_out[i].title.count() gt 0 then all_titles[i] = ads_data_out[i].title[0]
  endfor
  chck = strpos(strlowcase(all_titles), 'thank you')
  k = where(chck ne 0)
  ads_data_out = ads_data_out[k]

  ;
  ; Remove articles that begin with "publisher's note". These are similar to errata.
  ;
  n = n_elements(ads_data_out)
  all_titles = strarr(n)
  for i = 0, n - 1 do begin
    if ads_data_out[i].title.count() gt 0 then all_titles[i] = ads_data_out[i].title[0]
  endfor
  chck = strpos(strlowcase(all_titles), "publisher's note")
  k = where(chck ne 0)
  ads_data_out = ads_data_out[k]

  ;
  ; Remove articles that begin with "correction". These are similar to errata.
  ;
  n = n_elements(ads_data_out)
  all_titles = strarr(n)
  for i = 0, n - 1 do begin
    if ads_data_out[i].title.count() gt 0 then all_titles[i] = ads_data_out[i].title[0]
  endfor
  chck = strpos(strlowcase(all_titles), "correction")
  k = where(chck ne 0)
  ads_data_out = ads_data_out[k]

  
  ;
  ; Here I remove corrigenda, but only if they have zero citations. Note that the
  ; word corrigendum sometimes appears at the end of the title.
  ;
  n = n_elements(ads_data_out)
  all_titles = strarr(n)
  for i = 0, n - 1 do begin
    if ads_data_out[i].title.count() gt 0 then all_titles[i] = ads_data_out[i].title[0]
  endfor
  chck = strpos(strlowcase(all_titles), 'corrigendum')
  k = where((chck EQ -1) OR (chck EQ 0 AND ads_data_out.citation_count GT 0))
  ads_data_out = ads_data_out[k]

  
  ;
  ; The line below defines what types of article end up in the author's publication
  ; list.
  ; Note that 'erratum' is identified in doctype and so these are filtered out
  ; by the command below.
  ;
  k = where(ads_data_out.doctype eq 'article' or $
    ads_data_out.doctype eq 'inproceedings' or $
    ads_data_out.doctype eq 'inbook' or $
    ads_data_out.doctype eq 'eprint' or $
    ads_data_out.doctype eq 'book')

  if nk ne 0 then begin
    ads_data_out = ads_data_out[k]
  endif else begin
    return, -1
  endelse

  count = n_elements(ads_data_out)

  return, ads_data_out
end

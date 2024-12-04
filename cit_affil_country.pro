pro cit_affil_country, input, first_author = first_author, affil_file = affil_file
  compile_opt idl2

  ;+
  ; NAME:
  ;     CIT_AFFIL_COUNTRY
  ;
  ; PURPOSE:
  ;     This routine automatically uses the affiliation tag of the
  ;     cit_get_ads_entry structure to extract the country to which
  ;     the insitute belongs.
  ;
  ; CATEGORY:
  ;     ADS; affiliations.
  ;
  ; CALLING SEQUENCE:
  ;     CIT_AFFIL_COUNTRY, Input
  ;
  ; INPUTS:
  ;     Input:  An IDL structure in the format produced by
  ;             cit_get_ads_entry.
  ;
  ; OPTIONAL INPUTS:
  ;     Affil_File:  The name of a file containing the
  ;             affiliation-country connections. It must be a text
  ;             file with two columns. The first column contains the
  ;             country name with format 'a13'. The second column
  ;             contains the institute name with format 'a60'. If the
  ;             filename is not given, then the master file at:
  ;          http://files.pyoung.org/idl/ads/cit_affil_country.txt
  ;             is read. If the affiliation contains a "*" then this
  ;             is interpreted as a space, thus "*USA" will not be
  ;             triggered by "Busan".
  ;
  ; KEYWORD PARAMETERS:
  ;     First_Author: If set, then the affiliation is only checked for
  ;                   the paper's first author.
  ;
  ; OUTPUTS:
  ;     The input structure is returned, but with the COUNTRY tag
  ;     updated to contain the authors' country
  ;     affiliations. Note that the tag will be a list with the same
  ;     number of elements as the "author" tag of ADS_DATA.
  ;
  ; PROGRAMMING NOTES:
  ;     The routine checks the file at
  ;     http://files.pyoung.org/idl/ads/cit_affil_country.txt to match
  ;     institutes with countries.
  ;
  ;     The routine assigns a country by searching for a word or phrase
  ;     that matches the list in the cit_affil_country file. If an
  ;     author has multiple affiliations then only the first affiliation
  ;     is searched. Searching only for the country name can be
  ;     ambiguous (e.g., "New England" and "England") so often a town or
  ;     institute name might be used instead.
  ;
  ;     It's possible that an author's affiliation matches two different
  ;     countries. This can be due to a problem with the format of ADS
  ;     affiliation (multiple affiliations should be separated by ";"
  ;     but another symbol might be used), or due to the affiliation
  ;     matching. For example, "Canada Street, Boston, USA" could match
  ;     Canada and USA. A warning is printed in this case but the
  ;     country will be assigned to the first match.
  ;
  ;     If not match is found, then the routine prints out the
  ;     affiliation so that the author can use it to update the
  ;     cit_affil_country.txt file).
  ;
  ; MODIFICATION HISTORY:
  ;     Ver.1, 27-Jul-2017, Peter Young
  ;     Ver.2, 1-Nov-2017, Peter Young
  ;       added AFFIL_FILE input; removed link to file on my computer.
  ;     Ver.3, 6-Sep-2019, Peter Young
  ;       Sometimes the affiliation contains "&amp;" instead of "&",
  ;       and the semi-colon gets flagged as a separator. I've
  ;       fixed this now.
  ;     Ver.4, 13-Sep-2019, Peter Young
  ;       fixed bug when trying to read afill_file; introduced
  ;       possibility of specifying an affiliation with "*" to
  ;       represent a space.
  ;     Ver.5, 21-Jan-2020, Peter Young
  ;       now prints bibcode if no. of authors does not match no. of
  ;       affiliations.
  ;     Ver.6, 09-Jan-2023, Peter Young
  ;       if there are multiple affiliations, then cycle through them
  ;       until a match is found.
  ;     Ver.7, 19-Nov-2024, Peter Young
  ;       now passes affil_file= keyword through to cit_read_country.
  ;-

  if n_params() lt 1 then begin
    print, 'Use:  IDL> cit_affil_country, ads_data [, /first_author, affil_file= ]'
    print, '  - the country tag of ads_data will be updated'
    return
  endif

  n = n_elements(input)

  ;
  ; Get list of countries and the institutes' strings.
  ;
  affilstr = cit_read_country(count = nc, affil_file = affil_file)

  for i = 0, n - 1 do begin
    ;
    ; Reset country tag if it has previously been defined
    ;
    input[i].country = list()
    naff = input[i].aff.count()
    nauth = input[i].author.count()
    if nauth ne naff then print, '% CIT_AFFIL_COUNTRY: **WARNING: no. of authors and no. of affiliations are not the same! (' + input[i].bibcode + ')'
    if naff gt 0 then begin
      if keyword_set(first_author) then naff = 1
      country = strarr(naff)
      for j = 0, naff - 1 do begin
        aff = input[i].aff[j]
        aff = str_replace(aff, '&amp;', 'and')
        if trim(aff) eq '-' then begin
          country[j] = ''
        endif else begin
          bits = str_sep(aff, ';')
          n_aff = n_elements(bits)
          for ia = 0, n_aff - 1 do begin
            ;
            ; I add a space here which helps in identifying the country.
            ;
            aff = bits[ia] + ' '
            for k = 0, nc - 1 do begin
              chck = strpos(strlowcase(aff), strlowcase(affilstr[k].institute))
              if chck ge 0 and country[j] eq '' then country[j] = affilstr[k].country
              if chck ge 0 and country[j] ne '' then begin
                if country[j] ne affilstr[k].country then print, '% CIT_AFFIL_COUNTRY: **WARNING: multiple countries found for ' + aff, ' *** ', country[j], ', ', affilstr[k].country
              endif
            endfor
            if country[j] ne '' then break
          endfor
          if country[j] eq '' then print, '% CIT_AFFIL_COUNTRY: No entry found for ' + aff
        endelse
        input[i].country.add, country[j]
      endfor
    endif
  endfor
end
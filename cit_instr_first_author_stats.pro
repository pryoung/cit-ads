

FUNCTION cit_instr_first_author_stats, ads_data, count=count

;+
; NAME:
;     CIT_INSTR_FIRST_AUTHOR_STATS
;
; PURPOSE:
;     Returns the occurrence rate of first author names in the ADS data
;     structure.
;
; CATEGORY:
;     ADS; statistics.
;
; CALLING SEQUENCE:
;     Result = CIT_INSTR_FIRST_AUTHOR_STATS( Ads_Data )
;
; INPUTS:
;     Ads_Data:  An IDL structure in the format returned by
;                cit_get_ads_entry.pro.
;
; OUTPUTS:
;     An IDL structure with the tags
;      author_norm  String containing the author_norm form of the author's
;                   name.
;      count     Integer giving number of occurrences of
;                first_author_norm in the input structure.
;
; OPTIONAL OUTPUTS:
;     Count:  The number of unique names.
;
; EXAMPLE:
;     IDL> d=cit_instr_first_author_stats(ads_data)
;
; MODIFICATION HISTORY:
;     Ver.1, 04-Jan-2024, Peter Young
;-


;
; Only consider refereed papers.
;
k=where(ads_data.refereed EQ 1)
adata=ads_data[k]


;
; The tag first_author_norm gives the "author_norm" form of the first
; author's name. For example, "Young, P".
;
fan=adata.first_author_norm

uniq_fan=fan[uniq(fan,sort(fan))]
n=n_elements(uniq_fan)
count=intarr(n)
FOR i=0,n-1 DO BEGIN
  k=where(fan EQ uniq_fan[i],nk)
  count[i]=nk
ENDFOR


j=reverse(sort(count))
fan=uniq_fan[j]
count=count[j]

str={author_norm: fan, count: count}

count=n_elements(fan)

return,str

END

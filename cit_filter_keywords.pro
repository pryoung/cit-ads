

FUNCTION cit_filter_keywords, input, count=count

keywords=input
n_key=n_elements(keywords)

;
; Just in case there are any empty strings.
;
k=where(keywords NE '',nk)
keywords=keywords[k]

;
; The following checks if any of the keywords can be converted to numbers. If
; yes, then they are ignored.
;
swtch=bytarr(n_key)+1b
FOR i=0,n_key-1 DO BEGIN
  IF valid_num(trim(keywords[i])) THEN swtch[i]=0b
ENDFOR
k=where(swtch EQ 1)
keywords=keywords[k]
n_key=n_elements(keywords)



count=n_elements(keywords)

return,keywords


END

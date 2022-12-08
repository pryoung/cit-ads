
FUNCTION cit_clean_names, input


;+
; NAME:
;     CIT_CLEAN_NAMES
;
; PURPOSE:
;     This routine converts special character letters to regular
;     character letters. For example, "e-acute" will be converted to
;     "e". This is intended for use with authors' names.
;
; CATEGORY:
;     ADS; string conversion
;
; CALLING SEQUENCE:
;     Result = CIT_CLEAN_NAMES( Input )
;
; INPUTS:
;     Input:  A string. Can be an array.
;
; OUTPUTS:
;     A string with special character letters replaced with regular
;     letters. 
;
; EXAMPLE:
;     IDL> print,cit_clean_names('Böröl')
;     Borol
;
; MODIFICATION HISTORY:
;     Ver.1, 05-May-2021, Peter Young
;     Ver.2, 26-May-2021, Peter Young
;       Added two new entries.
;     Ver.3, 07-Sep-2021, Peter Young
;       Added one more entry.
;     Ver.4, 01-Oct-2021, Peter Young
;       Fixed typo (repalce).
;     Ver.5, 12-Apr-2022, Peter Young
;       Added new entry.
;-


chck=datatype(input)

IF chck NE 'STR' THEN BEGIN
   print,'% CIT_CLEAN_NAMES: the input is not a string. Returning...'
   return,input
ENDIF


a=input.replace('ö','o')
a=a.replace('í','i')
a=a.replace('á','a')
a=a.replace('ä','a')
a=a.replace('č','c')
a=a.replace('ć','c')
a=a.replace('ý','y')
a=a.replace('Š','S')
a=a.replace('š','s')
a=a.replace('õ','o')
a=a.replace('ó','o')
a=a.replace('é','e')
a=a.replace('è','e')
a=a.replace('è','e')
a=a.replace('É','E')
a=a.replace('ñ','n')
a=a.replace('ü','u')
a=a.replace('ú','u')

return,a

END

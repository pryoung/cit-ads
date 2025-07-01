
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
;     Ver.6, 09-Dec-2022, Peter Young
;       Added some new entries.
;     Ver.7, 22-Mar-2023, Peter Young
;       Added some new entries.
;     Ver.7, 16-Jan-2025, Peter Young
;       Added some new entries.
;     Ver.8, 21-Feb-2025, Peter Young
;       Added another entry.
;     Ver.9, 1-Jul-2025, Peter Young
;       Added another entry.
;-


chck=datatype(input)

IF chck NE 'STR' THEN BEGIN
   print,'% CIT_CLEAN_NAMES: the input is not a string. Returning...'
   return,input
ENDIF


a=input.replace('à','a')
a=a.replace('á','a')
a=a.replace('ä','a')
a=a.replace('ã','a')
a=a.replace('a̧','a')
a=a.replace('â','a')
a=a.replace('Â','A')
a=a.replace('Á','A')
a=a.replace('Å','A')
a=a.replace('č','c')
a=a.replace('ć','c')
a=a.replace('ç','c')
a=a.replace('Č','C')
a=a.replace('Ç','C')
a=a.replace('Ç','C')
a=a.replace('Ď','D')
a=a.replace('ď','d')
a=a.replace('ę','e')
a=a.replace('é','e')
a=a.replace('è','e')
a=a.replace('ê','e')
a=a.replace('è','e')
a=a.replace('ě','e')
a=a.replace('ě','e')
a=a.replace('ë','e')
a=a.replace('ė','e')
a=a.replace('ȩ','e')
a=a.replace('É','E')
a=a.replace('ǧ','g')
a=a.replace('í','i')
a=a.replace('ı','i')
a=a.replace('ï','i')
a=a.replace('İ','I')
a=a.replace('õ','o')
a=a.replace('ó','o')
a=a.replace('ò','o')
a=a.replace('ö','o')
a=a.replace('ő','o')
a=a.replace('ø','o')
a=a.replace('Ö','O')
a=a.replace('Ó','O')
a=a.replace('Ø','O')
a=a.replace('ô','o')
a=a.replace('ō','o')
a=a.replace('ł','l')
a=a.replace('ñ','n')
a=a.replace('ń','n')
a=a.replace('ň','n')
a=a.replace('ř','r')
a=a.replace('Š','S')
a=a.replace('Ş','S')
a=a.replace('Ś','S')
a=a.replace('š','s')
a=a.replace('ś','s')
a=a.replace('ş','s')
a=a.replace('ß','ss')
a=a.replace('ü','u')
a=a.replace('ú','u')
a=a.replace('ū','u')
a=a.replace('ŷ','y')
a=a.replace('ý','y')
a=a.replace('ž','z')
a=a.replace('ź','z')
a=a.replace('ż','z')
a=a.replace('Ž','Z')
a=a.replace('Ż','Z')
a=a.replace('æ','ae')

return,a

END

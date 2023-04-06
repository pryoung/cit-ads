
PRO cit_write_footer_html, lun


IF n_elements(foot_text) EQ 0 THEN foot_text='Created on '+systime()+'.'

printf,lun,'<p><hr>'
printf,lun,foot_text
printf,lun,'</p></td></tr></tbody></table></center></body></html>'



END

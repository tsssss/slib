;+
; Type: function.
; Purpose: parse xml file to get a list of xml tags.
; Parameters:
;   fn, in, string, req. Name of the xml file.
; Keywords: none.
; Return: strarr[n]. The list of xml tags. Tag can be processing instruction,
;   comment, opening tag, closing tag, empty element, content.
; Note: The element of the returned list can be:
;   (1) processing instruction. <? ... ?>. (2) comment. <!-- ... -->.
;   (3) opening tag. <...>. (4) closing tag. </...>. (5) empty element. <.../>.
;   (6) normal content.
; Dependence: none.
; History:
;   2014-09-23, Sheng Tian, create.
;-
function sread_xml_parse_xml, fn
    ; read xml file.
    nline = (file_lines(fn))[0]
    tline = ''      ; line in file.
    buf = ''       ; buffer to be parsed.
    xmltags = ''    ; save the tag list.
    openr, lun, fn, /get_lun
    ; parse each line.
    for i = 0, nline-1 do begin
        readf, lun, tline
        buf = buf+tline
        if buf eq '' then continue      ; emtpy line or buffer.
        idx0 = stregex(buf,'<')         ; find opening.
        idx1 = stregex(buf,'>')         ; find closing.
        if idx1 eq -1 then continue     ; no closing.
        if idx0 eq -1 or idx0 gt idx1 then begin
            print, 'Line '+string(i)+': no matching opening ...'
            xmltags = [xmltags,strmid(buf,0,idx1+1)]
            buf = strmid(buf,idx1+1)    ; dump whatever before closing.
        endif
        while stregex(buf,'>') ne -1 do begin
            idx0 = stregex(buf,'<')
            idx1 = stregex(buf,'>')
            if idx0 ne 0 then begin
                tmp = strmid(buf,0,idx0)
                if strtrim(tmp) ne '' then xmltags = [xmltags,tmp]
                buf = strmid(buf,idx0)  ; dump content.
            endif else begin
                xmltags = [xmltags,strmid(buf,idx0,idx1+1-idx0)]
                buf = strmid(buf,idx1+1); dump tag or empty element.
            endelse
        endwhile
    endfor
    free_lun, lun
    return, xmltags[1:*]
end

fn = '/Volumes/Works/works/ps_svg/1998_1001_ke_ai.svg'
fn = '/Volumes/Works/works/ps_svg/1998_1001_ke_ink.svg'
xmls = sread_xml_parse_xml(fn)
stop
end
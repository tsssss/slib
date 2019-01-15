;+
; Type: function.
; Purpose: parse xml tag into (1) tag name and its attribute name and value, 
;   for processing instruction and empty element. (2) tag name for opening
;   and closing tags. (3) content for comment and normal content.
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
function sread_xml_parse_tag, tag0, atts0, attribute = atts

    ; check comment.
    idx1 = stregex(tag0,'<!--') & idx2 = stregex(tag0,'-->')
    if idx1 ne -1 and idx2 ne -1 then $
        return, {name:strmid(tag0,idx1+4,idx2-idx1-4),type:'comment'}
    
    ; check closing tag.
    idx1 = stregex(tag0,'</') & idx2 = stregex(tag0,'>')
    if idx1 ne -1 and idx2 ne -1 then $
        return, {name:strmid(tag0,idx1+2,idx2-idx1-2),type:'closing tag'}
    
    ; check processing instruction and empty element.
    idx1 = stregex(tag0,'<?') & idx2 = stregex(tag0,'>')    ; '?>' cause error.
    if idx1 ne -1 and idx2 ne -1 then taginfo = $
        {name:strmid(tag0,idx1+2,idx2-idx1-3),type:'processing instruction'}

    idx1 = stregex(tag0,'<') & idx2 = stregex(tag0,'/>')
    if idx1 ne -1 and idx2 ne -1 then taginfo = $
        {name:strmid(tag0,idx1+1,idx2-idx1-1),type:'emtpy element'}
    
    ; parse the attributes.
    tag1 = strcompress(taginfo.name)
    idx1 = stregex(tag1,' ')
    taginfo.name = strmid(tag1,0,idx1)
    tag1 = strmid(tag1,idx1+1)
    if n_elements(atts0) ne 0 then begin
        atts = {name:'',value:''}
        natt = n_elements(atts0)
        for i = 0, natt-1 do begin
            idx1 = stregex(tag1,atts0[i]) & if idx1 eq -1 then continue
            tmp = strmid(tag1,0,idx1) & tag1 = strmid(tag1,idx1)
            idx2 = strpos(tag1,'=')
            name = strtrim(strmid(tag1,0,idx2),2)
            tag1 = strmid(tag1,idx2+1)
            idx2 = strsplit(tag1,'"', length = len)
            value = strmid(tag1,idx2[0],len[0]+1)
            tag1 = tmp+strmid(tag1,idx2[0]+len[0]+1)
            atts = [atts,{name:name,value:value}]
        endfor
        if n_elements(atts) gt 1 then atts = atts[1:*]
        return, taginfo
    endif else begin
        tmp = strsplit(tag1,'=') & natt = n_elements(tmp)-1
        atts = replicate({name:'',value:''},natt)
        for i = 0, natt-1 do begin
            idx2 = stregex(tag1,'=')
            name = strtrim(strmid(tag1,0,idx2),2)
            tag1 = strmid(tag1,idx2+1)
            idx2 = strsplit(tag1,'"', length = len)
            value = strmid(tag1,idx2[0],len[0])
            tag1 = strmid(tag1,idx2[0]+len[0]+1)
            atts[i].name = name & atts[i].value = value
        endfor
        return, taginfo
    endelse

    ; check opening tag, regular content and ill-formatted tag.
    idx1 = stregex(tag0,'<') & idx2 = stregex(tag0,'>')
    if idx1 eq -1 and idx2 eq -1 then return, {name:tag0,type:'content'}
    if idx1 eq -1 and idx2 ne -1 then $
        return, {name:strmid(tag0,0,idx1),type:'no opening'}
    if idx1 ne -1 and idx2 eq -1 then $
        return, {name:strmid(tag0,idx1+1),type:'no closing'}
    return, {tag:strmid(tag0,idx1+1,idx2-idx1-1),type:'opening tag'}
end

fn = '/Volumes/Works/works/ps_svg/1998_1001_ke_ai.svg'
;fn = '/Volumes/Works/works/ps_svg/1998_1001_ke_ink.svg'
xmls = sread_xml_parse_xml(fn)
tag = sread_xml_parse_tag(xmls[0])
end
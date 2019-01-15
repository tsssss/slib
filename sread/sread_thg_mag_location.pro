;+
; Read the list in ./support/GMAG-Station-Code-19700101.txt
; The columns are: site, glat, glon, name, mlat, mlon, midn, conjugate lat?, conjugate lon?
;-

function sread_thg_mag_location_parse_line, line
    ; parse each line.
    tinfos = strsplit(line, ' ', /extract)
    id = strlowcase(tinfos[0])
    glat = double(tinfos[1])
    glon = double(tinfos[2])
    tline = strjoin(tinfos[3:*], ' ')
    idx = stregex(tline, '[a-zA-Z)] [-+0-9]')
    name = strmid(tline, 0, idx+1)
    tinfos = strsplit(strmid(tline, idx+2), ' ', /extract)
    mlat = tinfos[0]
    mlon = tinfos[1]
    mlts = double(strsplit(tinfos[2],':', /extract))
    midn = mlts[0]+mlts[1]/60
    conjlat = tinfos[3]
    conjlon = tinfos[4]

    return, {id:id, glat:glat, glon:glon, name:name, mlat:mlat, mlon:mlon, $
        midn:midn, conjlat:conjlat, conjlon:conjlon}
end


function sread_thg_mag_location, site0
    
    fn = srootdir()+'/support/GMAG-Station-Code-19700101.txt'
    nsite = file_lines(fn)-1
    lines = strarr(nsite)
    head = ''
    openr, lun, fn, /get_lun
    readf, lun, head
    readf, lun, lines
    free_lun, lun
    
    infos = []
    for i=0, nsite-1 do $
        infos = [infos,sread_thg_mag_location_parse_line(lines[i])]
     
    ; filter for given site.
    if n_elements(site0) ne 0 then begin
        sites = infos.id
        sinfos = []
        foreach tsite, site0 do $
            sinfos = [sinfos, infos[where(sites eq tsite, cnt)]]
    endif
    
    return, infos
end

infos = sread_thg_mag_location()
stop
end

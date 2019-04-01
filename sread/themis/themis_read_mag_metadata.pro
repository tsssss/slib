function themis_read_mag_metadata_parse_line, line, errmsg=errmsg
    errmsg = ''
    retval = !null

    if n_elements(line) eq 0 then return, {id:'', glat:0., glon:0., name:'', mlat:0., mlon:0., $
        midn:0., conjlat:0., conjlon:0.}

    ; parse each line.
    tinfos = strsplit(line, '"', /extract)
    parts = strsplit(tinfos[0], ',', /extract)
    if n_elements(parts) ne 3 then begin
        errmsg = handle_error('Cannot parse the current line:'+line+' ...')
        return, retval
    endif

    id = strlowcase(parts[0])
    glat = float(parts[1])
    glon = float(parts[2])
    name = tinfos[1]
    parts = strsplit(tinfos[2], ',', /extract)
    if n_elements(parts) ne 5 then begin
        errmsg = handle_error('Cannot parse the current line:'+line+' ...')
        return, retval
    endif

    mlat = float(parts[0])
    mlon = float(parts[1])
    mlts = float(strsplit(parts[2],':.', /extract))
    midn = mlts[0]+mlts[1]/60
    conjlat = float(parts[3])
    conjlon = float(parts[4])

    return, {id:id, glat:glat, glon:glon, name:name, mlat:mlat, mlon:mlon, $
        midn:midn, conjlat:conjlat, conjlon:conjlon}
end

function themis_read_mag_metadata, file, errmsg=errmsg, sites=site0s

    errmsg = ''

    ; 'GMAG-Station-Code-19700101.txt' has errors: HON mlat is 220.5 deg??? should be 22.05.
    if n_elements(file) eq 0 then begin
        basename = 'THEMIS_GMAG_Station_List_Oct 2018.csv'
        file = join_path([sparentdir(srootdir()),'support',basename])
        ;        if file_test(file) eq 0 then begin
        ;            remote_file = 'http://themis.ssl.berkeley.edu/data/themis/thg/l2/mag/Station-Code-19700101.txt'
        ;            download_file, file, remote_file
        ;        endif
    endif

    if file_test(file) eq 0 then begin
        errmsg = handle_error('Cannot find meta data ...')
        return, !null
    endif

    lines = read_all_lines(file, skip_header=1)
    nline = n_elements(lines)
    nsite = n_elements(site0s)
    tinfo = themis_read_mag_metadata_parse_line()
    if nsite ne 0 then begin
        sites = strlowcase(site0s)
        site_infos = replicate(tinfo,nsite)
    endif else begin
        site_infos = replicate(tinfo,nline)
    endelse
    foreach line, lines, ii do begin
        tinfo = themis_read_mag_metadata_parse_line(line, errmsg=errmsg)
        if errmsg ne '' then continue
        if nsite ne 0 then begin
            index = where(sites eq tinfo.id, count)
            if count eq 0 then continue
        endif else index = ii
        site_infos[index] = tinfo
    endforeach

    ; Let MLon in [-180,180] deg.
    index = where(site_infos.mlon gt 180, count)
    for ii=0, count-1 do site_infos[index[ii]].mlon -= 360
    index = where(site_infos.mlon lt -180, count)
    for ii=0, count-1 do site_infos[index[ii]].mlon += 360

    return, site_infos
end
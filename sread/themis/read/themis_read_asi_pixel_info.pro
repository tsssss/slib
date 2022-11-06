;+
; Read the info of the site pixel.
; id=datatype. Can be 'ast' and 'asf'. By default is 'asf'.
; thumbnail=thumbnail. A boolean to set 'ast' in an alternative way.
; input_site_info=. Input to modify site_info.
;-

function themis_read_asi_pixel_info, time_range, site=site, id=datatype, thumbnail=thumbnail, errmsg=errmsg, input_site_info=site_info

    if n_elements(datatype) eq 0 then datatype = 'asf'
    if keyword_set(thumbnail) then datatype = 'ast'
    if n_elements(time_range) eq 0 then time_range = [0d,0]
    pixel_info = themis_read_asi_info(time_range, site=site, id=datatype, errmsg=errmsg, input_site_info=site_info)
    
    ; Get the position values at the center of each pixel.
    ; This unifies the different formats of asf and ast.
    if datatype eq 'asf' then begin
        foreach key, ['glon','glat','mlon','mlat'] do begin
            raw = pixel_info['asf_'+key]
            pixel_info['pixel_'+key] = (raw[1:-1,1:-1]+raw[0:-2,0:-2]+raw[1:-1,0:-2]+raw[0:-2,1:-1])*0.25
        endforeach
        foreach key, ['elev','azim'] do begin
            pixel_info['pixel_'+key] = pixel_info['asf_'+key]
        endforeach
    endif else begin
        binc = pixel_info.ast_binc
        binr = pixel_info.ast_binr
        binc = binc-min(binc)
        binr = binr-min(binr)
        nc = max(binc)+1
        nr = max(binr)+1
        image_size = [nr,nc]
        ; The mapping index to map each pixel to the 2D field of view.
        map_index = binr+binc*nr
        image_size = [nr,nc]
        foreach key, ['glon','glat','mlon','mlat'] do begin
            raw = pixel_info['ast_'+key]
            pos = fltarr(image_size)+!values.f_nan
            pos[map_index] = total(raw,1)*0.25
            pixel_info['pixel_'+key] = pos
        endforeach
        foreach key, ['elev','azim'] do begin
            raw = pixel_info['ast_'+key]
            pos = fltarr(image_size)+!values.f_nan
            pos[map_index] = raw[*]
            pixel_info['pixel_'+key] = pos
        endforeach
    endelse
    
    return, pixel_info

end

;+
; Read the info of the site center.
;-

function themis_read_asi_site_info, site, errmsg=errmsg, site_info=site_info

    info = themis_read_asi_info([0,0], site=site, id='asc', errmsg=errmsg, input_site_info=site_info)
    
    ; Conver midn from string to ut in sec.
    midn = info['asc_midn']
    if site eq 'pgeo' then midn = '08:55'   ; interpolated from fsim, whit and gako.
    hr = double(strmid(midn,0,2))
    mi = double(strmid(midn,3,2))
    midn_ut = (hr*60+mi)*60d
    info['midn_ut'] = midn_ut
    
    return, info
    
end

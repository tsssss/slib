;+
; Return the default site info for given sites as a base for further settings.
;-

function themis_read_mlonimg_default_site_info, sites, errmsg=errmsg

    nsite = n_elements(sites)
    if nsite eq 0 then begin
        errmsg = handle_error('No input site ...')
        return, !null
    endif

    site_info = {$
        name:'', $      ; a string in lower case for the site.
        min_elev:5d, $  ; the minimum elevation for edge.
        dmlon:0.2, $    ; the bin size for mlon bins.
        dmlat:0.1, $    ; the bin size for mlat bins.
        placeholder:0b}

    site_infos = replicate(site_info, nsite)
    foreach site, sites, ii do site_infos[ii].name = strlowcase(site)

;    ; fsim has trees, so we want a higher min_elev
;    index = where(sites eq 'fsim', count)
;    if count ne 0 then begin
;        site_infos[index].min_elev = 20
;    endif

    return, site_infos
end

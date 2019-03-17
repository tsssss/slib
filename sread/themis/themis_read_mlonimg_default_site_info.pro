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
        min_elev:7d, $  ; the minimum elevation for edge.
        dmlon:0.2, $    ; the bin size for mlon bins.
        dmlat:0.1, $    ; the bin size for mlat bins.
        placeholder:0b}

    site_infos = replicate(site_info, nsite)
    foreach site, sites, ii do site_infos[ii].name = strlowcase(site)

    return, site_infos
end

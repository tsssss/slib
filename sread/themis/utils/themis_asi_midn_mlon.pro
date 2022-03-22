;+
; Return midnight mlon in degree for given times.
;-
function themis_asi_midn_mlon, times

    data_file = join_path([srootdir(),'themis_asi_midn_mlon.sav'])
    if file_test(data_file) eq 0 then begin
        sites = themis_read_asi_sites()
        nsite = n_elements(sites)
        site_mlons = dblarr(nsite)
        site_midns = dblarr(nsite)
        foreach site, sites, site_id do begin
            site_info = themis_read_asi_site_info(site)
            site_mlons[site_id] = site_info.asc_mlon
            site_midns[site_id] = site_info.midn_ut
        endforeach
        index = sort(site_mlons)
        site_mlons = site_mlons[index]
        site_midns = site_midns[index]/3600 ; in hour.
        sites_midn_sorted = sites[index]
        
        ; Some sites have midn=0, which are incorrect.
        index = where(site_midns ne 0)
        site_mlons = site_mlons[index]
        site_midns = site_midns[index]
        sites_midn_sorted = sites_midn_sorted[index]
        stop
        save, site_mlons, site_midns, sites_midn_sorted, filename=data_file
    endif

    restore, filename=data_file

    secofday = constant('secofday')
    uts = (times/secofday mod 1)*24
    return, interpol(site_mlons, site_midns, uts, /nan)

end

times = time_double('2008-01-19/07:17:00')
midn_mlons = themis_asi_midn_mlon(times)
end

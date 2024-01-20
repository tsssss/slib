
function themis_asf_get_default_min_elevs, sites

    all_sites = themis_asi_get_sites()

    nsite = n_elements(sites)
    min_elevs = fltarr(nsite)+2.5

    ; This site has tall trees on edge.
    the_sites = ['fsmi']
    foreach site, the_sites do begin
        index = where(sites eq site, count)
        if count ne 0 then min_elevs[index] = 5
    endforeach

    return, min_elevs

end

function themis_read_asf_mlon_image_gen_merge_info, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, get_name=get_name

    the_var = 'thg_mlon_image_merge_weight'
    if keyword_set(get_name) then return, the_var
    
    mlon_image_info = mlon_image_info()
    image_size = mlon_image_info.image_size

    elev_dict = dictionary()
    foreach site, sites do begin
        pixel_info = themis_asi_read_pixel_info(site=site)
        elevs = pixel_info.pixel_elev
        index = where(elevs ge min_elev, complement=index2)
        elevs[index2] = 0
        elev_dict[site] = mlon_image_map_old2new(elevs, site=site)
    endforeach

    merge_weight = dictionary()
    if merge_method eq 'merge_elev' then begin
        elev_total = fltarr(image_size)
        foreach site, sites do begin
            elev_total += elev_dict[site]
        endforeach

        foreach site, sites do begin
            merge_weight[site] = elev_dict[site]/elev_total
        endforeach
    endif else if merge_method eq 'max_elev' then begin
        elev_max = fltarr(image_size)
        foreach site, sites do begin
            elev_max = elev_max > elev_dict[site]
        endforeach

        foreach site, sites do begin
            weight = fltarr(image_size)
            index = where(elev_dict[site] eq elev_max and elev_dict[site] ne 0, count)
            if count ne 0 then weight[index] = 1d
            merge_weight[site] = weight
        endforeach
    endif

    store_data, the_var, 0, merge_weight
    return, the_var

end

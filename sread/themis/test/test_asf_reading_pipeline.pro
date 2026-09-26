;+
; Test a new pipeline to work with asf data.
;-

function test_asf_reading_pipeline
    compile_opt idl2

;---Settings.
    tr = ['2013-05-01/07:00','2013-05-01/09:30']
    sites = ['fsim','fsmi','atha']
    nsite = n_elements(sites)

    ; Get the glat/glon, mlat/mlat range for each site.
    asi_sites = themis_asi_get_sites()
    nasi_site = n_elements(asi_sites)
    site_glats = fltarr(nasi_site)
    site_glons = fltarr(nasi_site)
    site_mlats = fltarr(nasi_site)
    site_mlons = fltarr(nasi_site)
    site_glat_ranges = fltarr(nasi_site,2)
    site_glon_ranges = fltarr(nasi_site,2)
    site_mlat_ranges = fltarr(nasi_site,2)
    site_mlon_ranges = fltarr(nasi_site,2)
    foreach site, asi_sites, site_id do begin
        asf_info = themis_read_asi_info_asf(tr, site=site)
        asc_info = themis_read_asi_info_asc(tr, site=site)

        pixel_glats = asf_info.asf_glat
        pixel_glons = asf_info.asf_glon
        glon_range = minmax(pixel_glons)
        glat_range = minmax(pixel_glats)

        pixel_mlats = asf_info.asf_mlat
        pixel_mlons = asf_info.asf_mlon
        ; Only consider pixels with elevation >= 0.
        pixel_elevs = asf_info.asf_elev
        index = where(pixel_elevs ge 0)
        pixel_mlats = pixel_mlats[index]
        pixel_mlons = pixel_mlons[index]

        mlat_range = minmax(pixel_mlats)
        mlon_range = minmax(pixel_mlons)
        site_glat_ranges[site_id,*] = glat_range
        site_glon_ranges[site_id,*] = glon_range
        site_mlat_ranges[site_id,*] = mlat_range
        site_mlon_ranges[site_id,*] = mlon_range
        site_mlats[site_id] = asc_info.asc_mlat
        site_mlons[site_id] = asc_info.asc_mlon
        site_glats[site_id] = asc_info.asc_glat
        site_glons[site_id] = asc_info.asc_glon

    endforeach

    del_glats = fltarr(nasi_site)
    del_glons = fltarr(nasi_site)
    del_mlats = fltarr(nasi_site)
    del_mlons = fltarr(nasi_site)
    foreach site, asi_sites, site_id do begin
        print, 'Site: ', site
        print, '  GLAT/GLON: ', site_glats[site_id], site_glons[site_id]
        print, '  MLAT/MLON: ', site_mlats[site_id], site_mlons[site_id]
        glat_range = site_glat_ranges[site_id,*]
        glon_range = site_glon_ranges[site_id,*]
        mlat_range = site_mlat_ranges[site_id,*]
        mlon_range = site_mlon_ranges[site_id,*]
        del_glat = abs(total(glat_range*[-1,1]))
        del_glon = abs(total(glon_range*[-1,1]))
        del_mlat = abs(total(mlat_range*[-1,1]))
        del_mlon = abs(total(mlon_range*[-1,1]))
        del_glats[site_id] = del_glat
        del_glons[site_id] = del_glon
        del_mlats[site_id] = del_mlat
        del_mlons[site_id] = del_mlon
        if site eq 'nrsq' then stop
        print, 'GLat range: '+strjoin(string(glat_range,format='(F6.1)'),'-')+' (del: '+string(del_glat,format='(F5.1)')+')'
        print, 'GLon range: '+strjoin(string(glon_range,format='(F6.1)'),'-')+' (del: '+string(del_glon,format='(F5.1)')+')'
        print, 'MLat range: '+strjoin(string(mlat_range,format='(F6.1)'),'-')+' (del: '+string(del_mlat,format='(F5.1)')+')'
        print, 'MLon range: '+strjoin(string(mlon_range,format='(F6.1)'),'-')+' (del: '+string(del_mlon,format='(F5.1)')+')'
    endforeach


    stop



    asf_vars = strarr(nsite)
    foreach site, sites, site_id do begin
    ;---Load raw data.
        asf_var = themis_read_asf(tr, site=site)
        asf_vars[site_id] = asf_var
        asf_info = themis_read_asi_info_asf(tr, site=site)

        pixel_glats = asf_info.asf_glat
        pixel_glons = asf_info.asf_glon
        pixel_elevs = asf_info.asf_elev
        glon_range = total(minmax(pixel_glons)*[-1,1])
        glat_range = total(minmax(pixel_glats)*[-1,1])
        stop

        settings = var_get_setting(asf_var)
        image_size = settings.image_size
        nx = image_size[0]
        ny = image_size[1]

        del_glats = pixel_glats[1:nx,*]-pixel_glats[0:nx-1,*]
        del_glats2 = pixel_glats[*,1:ny]-pixel_glats[*,0:ny-1]
        stop
        del_glons = fltarr(image_size)
        stop
    endforeach


  

    return, 1
end

compile_opt idl2
print, test_asf_reading_pipeline()
end
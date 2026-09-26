;+
; For all sites, obtain the pixels glat/glon locations.
; Plot the field of view on the glat/glon plane.
; 
; Relevant codes: themsi_plot_asi_site.pro.
;-

function test_themis_asf_geo_locations, test=test
    compile_opt idl2

    geo_var = 'thg_asf_geo_locations'
    if check_if_update(geo_var) then begin
        asi_sites = themis_asi_get_sites()
        nasi_site = n_elements(asi_sites)
        tr = ['2013-05-01/07:00','2013-05-01/09:30']
        min_elevs = [0d,5d]
        emission_height = 110.0
        min_elevs = [0d]

        center_lats = fltarr(nasi_site)
        center_lons = fltarr(nasi_site)
        dlats = fltarr(nasi_site)
        dlons = fltarr(nasi_site)

        foreach site, asi_sites, site_id do begin
            print, 'Site: ', strupcase(site)
            print, ''
            print, 'Emission height (km): ', emission_height
            asf_info = themis_read_asi_info(tr, site=site, emission_height=emission_height, id='asf')
            asc_info = themis_read_asi_info(tr, site=site, id='asc')
            pixel_info = themis_asi_read_pixel_info(tr, site=site, id='asf', emission_height=emission_height)

            pixel_glats = asf_info.asf_glat
            pixel_glons = asf_info.asf_glon
            pixel_glats = pixel_info.pixel_glat
            pixel_glons = pixel_info.pixel_glon
            pixel_elevs = asf_info.asf_elev

            center_glat = asc_info.asc_glat
            center_glon = asc_info.asc_glon
            center_lats[site_id] = center_glat
            center_lons[site_id] = center_glon

            foreach min_elev, min_elevs do begin
                good_pixel_index = where(pixel_elevs ge min_elev and finite(pixel_glats), count)
                glat_ranges = minmax(pixel_glats[good_pixel_index])
                glon_ranges = minmax(pixel_glons[good_pixel_index])
                dlats[site_id] = total(glat_ranges*[-1,1])
                dlons[site_id] = total(glon_ranges*[-1,1])

                print, ''
                print, 'Min elevation (deg): ', min_elev
                print, 'Center Glat/Glon (deg): ', center_glat, center_glon
                print, 'Mean Glat/Glon (deg):   ', mean(pixel_glats[good_pixel_index]), mean(pixel_glons[good_pixel_index])
                print, 'Delta Glat (deg): ', dlats[site_id]
                print, 'Delta Glon (deg): ', dlons[site_id]
            endforeach
        endforeach

        geo_info = dictionary($
            'asi_sites', asi_sites, $
            'center_lats', center_lats, $
            'center_lons', center_lons, $
            'dlats', dlats, $
            'dlons', dlons, $
            'emission_height', emission_height )
        geo_var = var_store(geo_var, geo_info)
    endif
    geo_info = var_get_data(geo_var)
    asi_sites = geo_info.asi_sites
    center_lats = geo_info.center_lats
    center_lons = geo_info.center_lons
    dlats = geo_info.dlats
    dlons = geo_info.dlons
    emission_height = geo_info.emission_height

    ; Generate a plot.
    deg = constant('deg')
    re = constant('re')
    h = emission_height
    expected_dlat = acos(re/(re+h))*deg

    plot_dir = srootdir()
    plot_base = 'tst_themis_asf_geo_locations.pdf'
    plot_file = join_path([plot_dir,plot_base])
    if keyword_set(test) then plot_file = 0

    fig_size = [6,6]
    sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz

    npan = 2
    margins = [6,4,2,1]
    poss = sgcalcpos(npan, margins=margins)
    fig_labels = letters(npan)+'. '+['Delta Glat','Delta Glon']
    sort_index = sort(dlats)
    xrange = minmax(make_bins(center_lats,5))
    xrange = [48,72]
    abs_ticklen = -0.3*ychsz*fig_size[1]

    tpos = poss[*,0]
    xticklen = abs_ticklen/(tpos[3]-tpos[1])/fig_size[1]
    yticklen = abs_ticklen/(tpos[2]-tpos[0])/fig_size[0]

    ; Latitude panel.
    tpos = poss[*,0]
    txs = center_lats[sort_index]
    tys = dlats[sort_index]
    plot, txs, tys, $
        xstyle=1, xrange=xrange, xtickformat='(A1)', $
        ystyle=1, yrange=[15,25], ytickv=[15,20,25], yticks=2, yminor=5, ytitle='Delta Glat (deg)', $
        noerase=1, position=tpos, psym=1, $
        xticklen=xticklen, yticklen=yticklen
    oplot, xrange, expected_dlat*2+[0,0], color=sgcolor('red')


    ; Longitude panel.
    tpos = poss[*,1]
    txs = center_lats[sort_index]
    tys = dlons[sort_index]

    plot, txs, tys, $
        xstyle=1, xrange=xrange, xtickformat='', xtitle='Center Glat (deg)', $
        ystyle=1, yrange=[25,65], ytickv=[30,45,60], yticks=2, yminor=5, ytitle='Delta Glon (deg)', $
        noerase=1, position=tpos, psym=1, $
        xticklen=xticklen, yticklen=yticklen
    txs = make_bins(xrange,0.1)
    tys = 2*expected_dlat/cos(txs*constant('rad'))
    oplot, txs, tys, color=sgcolor('red')

    for pid=0,npan-1 do begin
        tpos = poss[*,pid]
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1.0
        xyouts, tx,ty,normal=1, fig_labels[pid]
    endfor

    if keyword_set(test) then stop
    sgclose
    return, plot_file

end


compile_opt idl2
test = 0
print, test_themis_asf_geo_locations(test=test)
end
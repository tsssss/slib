;+
; Make a plot of the center and field of view of all all-sky imagers.
;
; fov=. Field of view in deg. By default is 10 deg, for about 100-110 km altitude.
; filename=. The filename for the figure. By default is to plot to window.
;-

pro themis_plot_asi_site, fov=fov, filename=plot_file

    deg = constant('deg')
    rad = constant('rad')
    re = constant('re')

    if n_elements(fov) eq 0 then begin
        h0 = 110d   ; km.
        fov = acos(re/(re+h0))*deg
    endif
    alti = (1/cos(fov*rad)-1)*re

    map_limit = [45,-165,75,-55]
    if n_elements(plot_file) eq 0 then plot_file = 0
    sgopen, plot_file, xsize=8, ysize=4.2, xchsz=xchsz, ychsz=ychsz

    tpos = sgcalcpos(1, margins=[1,1,1,1])
    map_set, mean(map_limit[[0,2]]), mean(map_limit[[1,3]]), $
        continents=1, stereo=1, isotropic=1, grid=1, label=1, $
        limit=map_limit, color=sgcolor('silver'), position=tpos
    tx = tpos[2]-xchsz*0.5
    ty = tpos[1]+ychsz*0.5
;    xyouts, tx,ty,normal=1, alignment=1, 'Circle for FOV = '+string(fov,format='(I0)')+' deg'
    xyouts, tx,ty,normal=1, alignment=1, 'Circle for nominal spatial coverage'


    sites = themis_read_asi_sites()
    sites = sort_uniq(sites)
    center_psym = 1
    center_color = sgcolor('red')
    circle_color = sgcolor('gray')
    label_size = 1
    foreach site, sites, site_id do begin
        site_info = themis_read_asi_site_info(site)
        center_glon = site_info.asc_glon
        center_glat = site_info.asc_glat
        plots, center_glon, center_glat, $
            psym=center_psym, color=center_color
        tmp = convert_coord(center_glon, center_glat, data=1, to_normal=1)
        tx = tmp[0]+xchsz*0
        ty = tmp[1]+ychsz*0.3
        if site eq 'yknf' then tx = tmp[0]-xchsz*1
        if site eq 'snap' then tx = tmp[0]+xchsz*1
        if site eq 'fsim' then tx = tmp[0]-xchsz*1
        xyouts, tx, ty, normal=1, alignment=0.5, strupcase(site), charsize=label_size

        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*(site_id+2)
        xyouts, tx,ty,normal=1, strupcase(site)
        tx = tpos[0]+xchsz*7
        xyouts, tx,ty,normal=1, string(center_glon,format='(F6.1)')
        tx = tpos[0]+xchsz*12
        xyouts, tx,ty,normal=1, string(center_glat,format='(F4.1)')
        if site_id eq 0 then begin
            tx = tpos[0]+xchsz*0.5
            ty = tpos[3]-ychsz*(site_id+1)
            xyouts, tx,ty,normal=1, 'Site'
            tx = tpos[0]+xchsz*5
            xyouts, tx,ty,normal=1, 'GLon & GLat (deg)'
        endif

        ; Calculate the circle of FOV.
        r_geo = cv_coord(from_sphere=[center_glon,center_glat,1], $
            degree=1, to_rect=1)

        azims = make_bins([0d,360],10)
        nrec = n_elements(azims)
        circle_glons = fltarr(nrec)
        circle_glats = fltarr(nrec)
        dis = tan(fov*rad)
        for ii=0,nrec-1 do begin
            hor_sph = [azims[ii],0,dis]
            hor_xyz = cv_coord(from_sph=hor_sph, degree=1, to_rect=1)
            geo_xyz = hor2geo(hor_xyz, center_glat, center_glon, degree=1)+r_geo
            geo_sph = cv_coord(from_rect=geo_xyz, degree=1, to_sphere=1)
            circle_glons[ii] = geo_sph[0]
            circle_glats[ii] = geo_sph[1]
        endfor
        plots, circle_glons, circle_glats, color=circle_color
    endforeach

    sgclose

end

plot_file = join_path([srootdir(),'themis_asi_site_map.pdf'])
themis_plot_asi_site, fov=5, filename=plot_file
end
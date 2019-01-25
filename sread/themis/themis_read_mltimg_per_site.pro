;+
; Read Themis ASI per site and convert it to mlt image.
;-
;

pro themis_read_mltimg_per_site, time, site=site, errmsg=errmsg, $
    min_elev=min_elev, height=height, min_lat=min_lat
    
    compile_opt idl2
    on_error, 0
    errmsg = ''
    
;---Constants.    
    rad = !dpi/180
    
    
;---Image size.
    asf_size = 256
    full_size = 3*asf_size
    half_size = full_size/2
    
    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    if size(time0,/type) eq 7 then time0 = time_double(time0)
    
    if n_elements(site) eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif
    pre0 = 'thg_'+site+'_'
    
    if n_elements(height) eq 0 then height = 110d   ; km.
    if n_elements(min_elev) eq 0 then min_elev = 5d ; deg.
    if n_elements(min_lat) eq 0 then min_lat = 55d  ; deg.
    
    
;---Read ASF raw image, after preprocessed.
    ; thg_site_asf and thg_site_asf_elev
    themis_read_asf, time, site=site, min_elev=-5, errmsg=errmsg
    if errmsg ne '' then return
    elev_var = pre0+'asf_elev'
    center_elevs = get_var_data(elev_var)
    ;weight = sin(reform(center_elevs[0,*,*])*rad)  ; Sheng: weight has little effect for single site.
    ;weight = fltarr(asf_size+[0,0])+1
    good_pixels = where(finite(center_elevs), complement=bad_pixels, ngood_pixel)

    
;---Convert to MLT image.
    ; Get mlon/mlat of pixel corners.
    themis_read_asc, time, site=site, vars=['mlon','mlat'], id='asf%v01', height=height
    mlon_var = pre0+'asf_mlon'
    mlat_var = pre0+'asf_mlat'
    corner_mlons = get_var_data(mlon_var)
    corner_mlats = get_var_data(mlat_var)
    
        
    get_data, pre0+'asf', times, asf_images
    ntime = n_elements(times)
    corner_rs = (90-corner_mlats)/(90-min_lat)
    zipimgs = list()
;    mltimgs = fltarr(ntime,full_size,full_size)
;    mltelevs = fltarr(ntime,full_size,full_size)
    for i=0, ntime-1 do begin
        lprmsg, 'Processing MLT image at '+time_string(times[i])+' ...'
        ; Get the position of each pixel corners in the overall picture (x/y).
        mltimg = fltarr(full_size+[0,0])
        mltelev = fltarr(full_size+[0,0])
        pxlcnt = fltarr(full_size+[0,0])
        mlts = mlon2mlt(corner_mlons, times[i])
        corner_ts = (mlts*15-90)*rad
        corner_xs = corner_rs*cos(corner_ts)
        corner_ys = corner_rs*sin(corner_ts)
        corner_xs = (corner_xs+1)*half_size+0.5
        corner_ys = (corner_ys+1)*half_size+0.5
        
        asfimg = reform(asf_images[i,*,*])
        for j=0, ngood_pixel-1 do begin
            index = array_indices([asf_size,asf_size], good_pixels[j], /dimensions)
            
            xcor = corner_xs[index[0]:index[0]+1,index[1]:index[1]+1]
            ycor = corner_ys[index[0]:index[0]+1,index[1]:index[1]+1]
            tmp = [xcor,ycor]
            index = where(~finite(tmp), count)
            if count ne 0 then continue
            
            xcor = round(xcor)
            ycor = round(ycor)
            ib = max(xcor, min=ia)
            jb = max(ycor, min=ja)
            ia = ia < (full_size-1) > 0
            ja = ja < (full_size-1) > 0
            ib = ib < (full_size-1) > ia
            jb = jb < (full_size-1) > ja
            mltimg[ia:ib,ja:jb] += asfimg[good_pixels[j]]
            mltelev[ia:ib,ja:jb] += center_elevs[good_pixels[j]]
            pxlcnt[ia:ib,ja:jb] += 1
        endfor
        
        index = where(pxlcnt ne 0, count)
        if count gt 0 then begin
            coef = 1d/pxlcnt[index]
            mltimg[index] *= coef
            mltelev[index] *= coef
        endif
        
        tmp = where(mltimg gt 0, npixel)
        zipimgs.add, themis_asi_zip_mltimg(mltimg, elev=mltelev)
    endfor
    store_data, pre0+'mltimg', times, zipimgs
end

time = time_double(['2014-08-28/10:00','2014-08-28/10:01'])
site = 'whit'
themis_read_mltimg_per_site, time, site=site

vars = 'thg_'+site+'_mltimg'
tplot_save, vars, filename=shomedir()+'/test_thg_mltimg_list.tplot'

end
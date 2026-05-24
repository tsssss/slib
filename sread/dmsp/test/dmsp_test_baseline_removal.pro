;+
; MFIT is the polynomial fit for baseline calculation.
; However, it is only available for CDAWeb, but not Madrigal and NOAA.
; Thus, I want to do a baseline calculation applicable to all.
;-


compile_opt idl2
time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
test = 1
prefix = 'dmsp'+probe+'_'

;---Load data from cdaweb.
    db_dmsp_xyz_var = dmsp_read_bfield(time_range, probe=probe)
    r_var = dmsp_read_orbit(time_range, probe=probe)
    mlat_vars = lets_read_mlat_vars(r_var)
    mlat_var = mlat_vars['mlat']

    mlat_lim = 45d
    db_vecs = var_get_data(db_dmsp_xyz_var, times=times, settings=settings)
    mlats = var_get_data(mlat_var, at=times)
    index = where_pro(mlats, ')(', [-1,1]*mlat_lim, count=count)
    if count eq 0 then stop
    db_vecs[index,*] = !values.f_nan
    db_base_var = var_store(prefix+'db_base', db_vecs, times, settings=settings)

    ; Smoothed background.
    db_smooth = var_get_data(db_dmsp_xyz_var, times=times)
    window = 60d
    dr = sdatarate(times)
    width = window/dr
    ndim = 3
    for ii=0,ndim-1 do begin
        db_smooth[*,ii] = smooth(db_smooth[*,ii],width,edge_truncate=1,nan=1)
    endfor
    db_smooth_var = var_store(prefix+'db_smooth', db_smooth, times, settings=settings)

    ; Polynomial background.
    db_poly = var_get_data(db_base_var, times=times)
    index = where(mlats ge -mlat_lim)
    nan_rs = time_to_range(index)
    nnan_r = n_elements(nan_rs[*,0])
    for ii=1,nnan_r-2 do begin
        the_order = 7 
        i0 = nan_rs[ii,0]
        i1 = nan_rs[ii,1]
        the_ut = findgen(i1-i0+1)
        the_db = db_poly[i0:i1,*]
        the_mlat = mlats[i0:i1]
        index = where(the_mlat lt mlat_lim and finite(the_db[*,0]), count)
        if count eq 0 then continue
;        poly_index = smkarthm(index[0],index[count-1],128,'n')
;        the_index = index[poly_index]
        the_index = index
        for jj=0,ndim-1 do begin
            coef_x = poly_fit(the_ut[the_index], the_db[the_index,jj], the_order)
            db_poly[i0:i1,jj] = poly(the_ut, coef_x)
        endfor
    endfor
    db_poly_north_var = var_store(prefix+'db_poly_north', db_poly, times, settings=settings)

    db_poly = var_get_data(db_base_var, times=times)
    index = where(mlats le mlat_lim)
    nan_rs = time_to_range(index)
    nnan_r = n_elements(nan_rs[*,0])
    for ii=1,nnan_r-2 do begin
        the_order = 7 
        i0 = nan_rs[ii,0]
        i1 = nan_rs[ii,1]
        the_ut = findgen(i1-i0+1)
        the_db = db_poly[i0:i1,*]
        the_mlat = mlats[i0:i1]
        index = where(the_mlat gt -mlat_lim and finite(the_db[*,0]), count)
        if count eq 0 then continue
;        poly_index = smkarthm(index[0],index[count-1],128,'n')
;        the_index = index[poly_index]
        the_index = index
        for jj=0,ndim-1 do begin
            coef_x = poly_fit(the_ut[the_index], the_db[the_index,jj], the_order)
            db_poly[i0:i1,jj] = poly(the_ut, coef_x)
        endfor
    endfor
    db_poly_south_var = var_store(prefix+'db_poly_south', db_poly, times, settings=settings)

    db_poly_north = var_get_data(db_poly_north_var)
    db_poly_south = var_get_data(db_poly_south_var)
    db_base = mean([[[db_poly_north]],[[db_poly_south]]],nan=1, dimension=3)
    db_poly_base_var = var_store(prefix+'db_poly_base', db_base, times, settings=settings)
    db_orig = var_get_data(db_dmsp_xyz_var)
    ddb_poly_var = var_store(prefix+'ddb_poly', db_orig-db_base, times, settings=settings)

    plot_file = 0
    if keyword_set(test) then plot_file = 0
    fig_size = [12,6]
    sgopen, plot_file, size=fig_size
    options, mlat_var, constant=mlat_lim*[-1,1]
    vars = [db_base_var,db_smooth_var,db_poly_north_var]
    options, vars, yrange=[-1,1]*200, constant=0
    vars = [db_dmsp_xyz_var,db_base_var,db_smooth_var,db_poly_north_var,db_poly_south_var,db_poly_base_var]
    options, vars, yrange=[-1,1]*600, constant=0
    tplot, [db_dmsp_xyz_var,db_base_var,db_smooth_var,db_poly_base_var, ddb_poly_var, mlat_var], trange=time_range
    stop


end
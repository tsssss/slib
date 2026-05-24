;+
; :Purpose: Calculate baseline of dB original and save to CDF.
; :Returns: str, file name.
; :Arguments:
;   input_time_range: in, required. Time range.
; :Keywords:
;   probe: in, required. 'fxx'.
;   filename: in, required. File name to save the data.
;   test: in, optional. Set to run test code.

function dmsp_load_ssm_baseline_gen_file, input_time_range, probe=probe, filename=file, test=test
    compile_opt idl2
    errmsg = ''
    retval = !null

    secofday = constant('secofday')
    date = time_double(input_time_range[0])
    date = date-(date mod secofday)
    time_range = date+[0,secofday]
    pad_time = 105*60d  ; sec.
    data_time_range = time_range+[-1,1]*pad_time
    prefix = 'dmsp'+probe+'_'

    b_orig_var = dmsp_read_bfield(data_time_range, probe=probe, errmsg=errmsg, keep_baseline=1)
    if errmsg ne '' then return, retval
    r_var = dmsp_read_orbit(data_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    mlat_vars = lets_read_mlat_vars(r_var)
    mlat_var = mlat_vars['mlat']

;---Settings for polyfit and smoothing.
    mlat_lim = 45d  ; deg.
    poly_order = 7
    b_base_var = prefix+'b_base'

    b_orig = var_get_data(b_orig_var, times=times, settings=settings)
    mlats = var_get_data(mlat_var, at=times)
    nan_index = where_pro(abs(mlats), '>', mlat_lim, count=count)
    if count ne 0 then begin
        ; Determine the sectors to work with.
        ; Remove the first and last. They should be in padding and probably incomplete.
        nan_sectors = time_to_range(nan_index)
        nnan_sector = n_elements(nan_sectors[*,0])
        i0 = nan_sectors[0,1]+1
        i1 = nan_sectors[nnan_sector-1,0]-1
        clean_time_range = times[[i0,i1]]
        b_orig = b_orig[i0:i1,*]
        mlats = mlats[i0:i1]
        times = times[i0:i1]
        ntime = n_elements(times)

        ; Update index of all nan sectors.
        nan_index = where_pro(abs(mlats), '>', mlat_lim, count=count)
        nan_sectors = time_to_range(nan_index)
        nan_indexs = sort_uniq([nan_sectors[*],0,ntime-1])
        b_orig[nan_index,*] = !values.f_nan

        ; Deal with each hemisphere.
        hems = [1,-1]
        ndim = 3
        foreach hem, hems do begin
            if hem eq 1 then begin
                relation = 'gt'
                limit = mlat_lim
                hem_var = prefix+'b_base_north'
            endif else begin
                relation = 'lt'
                limit =-mlat_lim
                hem_var = prefix+'b_base_south'
            endelse
            hem_indexs = where_pro(mlats, relation, limit)
            hem_rrs = time_to_range(hem_indexs)
            nhem_rr = n_elements(hem_rrs[*,0])

            b_base = fltarr(ntime,ndim)+!values.f_nan
            for ii=0,nhem_rr-1 do begin
                ; The records to be corrected.
                nan_rr = reform(hem_rrs[ii,*])
                j0 = nan_rr[0]
                j1 = nan_rr[1]
                ; Full records of this orbit.
                tmp = min(nan_indexs-nan_rr[0], index, absolute=1)
                sector_rr = nan_indexs[index+[-1,2]]
                i0 = sector_rr[0]
                i1 = sector_rr[1]
                nrec = i1-i0+1
                the_ut = findgen(nrec)
                the_db = b_orig[i0:i1,*]
                good_index = where(finite(snorm(the_db)))
                for jj=0,ndim-1 do begin
                    coef = poly_fit(the_ut[good_index], the_db[good_index,jj], poly_order)
                    b_base[i0:i1,jj] = poly(the_ut, coef)
                endfor
            endfor

            hem_var = var_store(hem_var, b_base, times, settings=settings)
        endforeach

    ;---Average the two hemispheres to get the baseline.
        b_north = var_get_data(prefix+'b_base_north', times=times)
        b_south = var_get_data(prefix+'b_base_south', times=times)
        ; Make a weighting by mlat to avoid discontinuity.
        ; weight is 1 above mlat_lim, 0 below -mlat_lim, and linear in between.
        ; -0.5 at -mlat_lim, 0.5 at mlat_lim.
        weight_north = mlats/mlat_lim*0.5
        weight_north <= 0.5
        weight_north >= -0.5
        weight_north = weight_north+0.5
        weight_south = 1-weight_north
        index = where(finite(snorm(b_north),nan=1))
        b_north[index,*] = 0
        index = where(finite(snorm(b_south),nan=1))
        b_south[index,*] = 0
        b_base = b_north
        for ii=0,ndim-1 do begin
            b_base[*,ii] = b_north[*,ii]*weight_north+b_south[*,ii]*weight_south
        endfor

    ;---Trim to the original time range.
        index = where_pro(times, '[]', time_range)
        times = times[index]
        b_base = b_base[index,*]
        b_base_var = var_store(b_base_var, b_base, times, settings=settings)
        
        if keyword_set(test) then begin
            b_base_vars = [b_base_var+['','_north','_south']]
            vars = [b_orig_var,b_base_vars]
            options, vars, yrange=[-1,1]*500, constant=0
            plot_file = 0
            fig_size = [16,6]
            sgopen, plot_file, size=fig_size
            options, mlat_var, constant=[-1,1]*mlat_lim
            tplot, [b_orig_var,b_base_vars,mlat_var], trange=data_time_range
            timebar, time_range, linestyle=0, color=sgcolor('blue')
            timebar, clean_time_range, linestyle=0, color=sgcolor('purple')
            stop
        endif
    endif else begin
        ; No data, just save nan.
        times = time_range
        ntime = n_elements(times)
        b_base = fltarr(ntime,ndim)+!values.f_nan
        b_base_var = var_store(b_base_var, b_base, times, settings=settings)
    endelse

;---Save to file.
    b_base = var_get_data(b_base_var, times=times)
    settings = dictionary($
        'coord', 'dmsp_xyz', $
        'coord_notes', 'x: forward along sc trajectory, y: right and perp, z: down and perp', $
        'mlat_lim', mlat_lim, $
        'poly_order', poly_order )
    cdf_save_setting, settings, filename=file

    time_var = 'time'
    settings = dictionary($
        'VAR_TYPE', 'support_data', $
        'UNITS', 'sec', $
        'TIME_VAR_TYPE', 'unix' )
    cdf_save_var, time_var, value=times, filename=file, settings=settings

    var = prefix+'db_base'
    settings = dictionary($
        'NOTES', 'dB baseline', $
        'DEPEND_0', time_var, $
        'VAR_TYPE', 'data', $
        'UNITS', 'nT' )
    cdf_save_var, var, value=b_base, filename=file, settings=settings

    times = var_get_time(b_base_var)
    db_orig = var_get_data(b_orig_var, at=times)
    var = prefix+'db_orig'
    settings = dictionary($
        'NOTES', 'dB original', $
        'DEPEND_0', time_var, $
        'VAR_TYPE', 'data', $
        'UNITS', 'nT' )
    cdf_save_var, var, value=db_orig, filename=file, settings=settings

    return, file
end

compile_opt idl2
tr = ['2013-05-01']
probe = 'f18'
file = join_path([homedir(),'tmp','test_dmsp_ssm_baseline_v01.cdf'])
file = dmsp_load_ssm_baseline_gen_file(tr, probe=probe, filename=file)
print, file
end
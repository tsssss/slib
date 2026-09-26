;+
; Read themis info per site.
;
; site. Input site name in string.
; id=. By default is 'asc'.
; input_site_info=. Input to modify site_info.
;-

function themis_read_asi_info_ast, input_time_range, site=site, $
    errmsg=errmsg, input_site_info=site_info, version=version

    time_range = time_double(input_time_range)
    files = themis_load_asi(time_range, id='l2%asc', site=site, $
        errmsg=errmsg, version=version)
    if errmsg ne '' then return, !null
    cdfid = cdf_open(files[0])

    prefix = 'thg_'+site+'_'
    if n_elements(site_info) eq 0 then site_info = dictionary('site',site)

    ; Pixel, ast.
    vars = ['glon','glat','mlon','mlat','elev','azim','binc','binr']
    in_vars = 'thg_ast_'+site+'_'+vars
    out_vars = 'ast_'+vars
    time_var = 'thg_asf_'+site+'_time'
    times = cdf_read_var(time_var, filename=cdfid)
    index = where(times lt time_range[0], count)
    if count eq 0 then begin
        time_index = 0  ; time_range[0] before all times.
    endif else begin
        time_index = index[count-1] ; last time before time_range[0]
    endelse

    foreach var, in_vars, var_id do begin
        if cdf_has_var(var, filename=cdfid) then begin
            ; There are multiple records. Need to filter down to one.
            val = cdf_read_var(var, filename=cdfid)
            val = reform(val[time_index,*,*,*])
            site_info[out_vars[var_id]] = val
        endif else begin
            site_info[out_vars[var_id]] = !null
        endelse
    endforeach

    ; Wrap up.
    cdf_close, cdfid
    return, site_info

end


function themis_read_asi_info_asf, input_time_range, site=site, $
    errmsg=errmsg, input_site_info=site_info, version=version, emission_height=emission_height

    errmsg = ''
    retval = !null

    time_range = time_double(input_time_range)
    files = themis_load_asi(time_range, id='l2%asc', site=site, $
        errmsg=errmsg, version=version)
    if errmsg ne '' then return, !null
    cdfid = cdf_open(files[0])

    prefix = 'thg_asf_'+site+'_'
    if n_elements(site_info) eq 0 then site_info = dictionary('site',site)

    ; Pixel, asf.
    vars = ['glon','glat','mlon','mlat','elev','azim']

    in_vars = prefix+vars
    out_vars = 'asf_'+vars
    alti_var = prefix+'alti'
    altis = cdf_read_var(alti_var, filename=cdfid)*1e-3  ; in km.
    nalti = n_elements(altis)
    valid_emission_range = [70d,200] ; in km, allow a bit extrapolation.
    if n_elements(emission_height) eq 0 then emission_height = 110d
;    tmp = min(altis-emission_height, alti_index, abs=1)
    
    time_var = prefix+'time'
    times = cdf_read_var(time_var, filename=cdfid)
    ntime = n_elements(times)
    the_time = mean(time_range)
    ; To avoid extrapolation.
    the_time <= max(times)
    the_time >= min(times)

    foreach var, in_vars, var_id do begin
        if cdf_has_var(var, filename=cdfid) then begin
            ; There are multiple records. Need to filter down to one.
            orig_val = cdf_read_var(var, filename=cdfid)
            dims = size(orig_val, dimensions=1)
            ndim = n_elements(dims)
            if dims[0] eq ntime then begin
                ; Probably the best is to use time_index = 0.
                val = reform(sinterpol(orig_val, times, the_time))
            endif else val = orig_val

            dims = size(val, dimensions=1)
            ndim = n_elements(dims)
            if ndim eq 3 then begin
                ; pick out the dimension corresponding to the emission height.
                alti_index = where(dims eq nalti, count, complement=other_index)
                if count ne 1 then begin
                    errmsg = 'Something is wrong with the altitude dimension ...'
                    return, retval
                endif

                ; move it to the first dimension.
                permute_index = [alti_index,other_index]
                val = transpose(val, permute_index)

                ; interpolate to the emission height.
                if product(valid_emission_range-emission_height) gt 0 then begin
                    errmsg = 'Emission height is out of range ...'
                    return, retval
                endif
                val = reform(sinterpol(val, altis, emission_height))
            endif
            site_info[out_vars[var_id]] = val
        endif else begin
            site_info[out_vars[var_id]] = !null
        endelse
    endforeach

    ; Wrap up.
    cdf_close, cdfid
    return, site_info

end


function themis_read_asi_info_asc, input_time_range, site=site, $
    errmsg=errmsg, input_site_info=site_info, version=version

    time_range = [0d,0]
    files = themis_load_asi(time_range, id='l2%asc', site=site, $
        errmsg=errmsg, version=version)
    if errmsg ne '' then return, !null
    cdfid = cdf_open(files[0])

    prefix = 'thg_'+site+'_'
    if n_elements(site_info) eq 0 then site_info = dictionary('site',site)

    ; The center position.
    vars = ['glon','glat','mlon','mlat','midn']
    in_vars = 'thg_asc_'+site+'_'+vars
    out_vars = 'asc_'+vars

    foreach var, in_vars, var_id do begin
        if cdf_has_var(var, filename=cdfid) then begin
            site_info[out_vars[var_id]] = cdf_read_var(var, filename=cdfid)
        endif else begin
            site_info[out_vars[var_id]] = !null
        endelse
    endforeach

    ; Wrap up.
    cdf_close, cdfid
    return, site_info

end


function themis_read_asi_info, input_time_range, site=site, id=datatype, $
    errmsg=errmsg, input_site_info=site_info, version=version, emission_height=emission_height

    if n_elements(datatype) eq 0 then datatype = 'asc'
    if datatype eq 'asf' then $
        return, themis_read_asi_info_asf(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version, emission_height=emission_height)

    if datatype eq 'ast' then $
        return, themis_read_asi_info_ast(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version)

    if datatype eq 'asc' then $
        return, themis_read_asi_info_asc(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version)

end

compile_opt idl2

site = 'gbay'
time_range = ['2013-01-01','2013-01-02']
emission_heights = [50d,110]
foreach emission_height, emission_heights do begin
    site_info = themis_read_asi_info_asf(time_range, site=site, emission_height=emission_height, errmsg=errmsg)
    if errmsg eq '' then print, 'Success ...' else print, errmsg
stop
endforeach


site = 'atha'
time_range = ['2013-01-01','2013-01-02']
site_info = themis_read_asi_info_asf(time_range, site=site)
stop
site_info = themis_read_asi_info(time_range, site=site, id='ast')
end

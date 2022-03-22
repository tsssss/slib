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
    errmsg=errmsg, input_site_info=site_info, version=version

    time_range = time_double(input_time_range)
    files = themis_load_asi(time_range, id='l2%asc', site=site, $
        errmsg=errmsg, version=version)
    if errmsg ne '' then return, !null
    cdfid = cdf_open(files[0])

    prefix = 'thg_'+site+'_'
    if n_elements(site_info) eq 0 then site_info = dictionary('site',site)

    ; Pixel, asf.
    vars = ['glon','glat','mlon','mlat','elev','azim']

    in_vars = 'thg_asf_'+site+'_'+vars
    out_vars = 'asf_'+vars
    alti_var = 'thg_asf_'+site+'_alti'
    time_var = 'thg_asf_'+site+'_time'
    times = cdf_read_var(time_var, filename=cdfid)
    index = where(times lt time_range[0], count)
    if count eq 0 then begin
        time_index = 0  ; time_range[0] before all times.
    endif else begin
        time_index = index[count-1] ; last time before time_range[0]
    endelse

    h0 = 110d
    foreach var, in_vars, var_id do begin
        if cdf_has_var(var, filename=cdfid) then begin
            ; There are multiple records. Need to filter down to one.
            val = cdf_read_var(var, filename=cdfid)
            val = reform(val[time_index,*,*,*])
            val_setting = cdf_read_setting(var, filename=cdfid)
            if val_setting.haskey('depend_3') then begin
                ; glat, glon in v01 cal file depends one alti.
                alti = cdf_read_var(alti_var, filename=cdfid)*1e-3  ; in km.
                tmp = min(alti-h0, alti_index, abs=1)
                val = reform(val[alti_index,*,*])
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
    errmsg=errmsg, input_site_info=site_info, version=version

    if n_elements(datatype) eq 0 then datatype = 'asc'
    if datatype eq 'asf' then $
        return, themis_read_asi_info_asf(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version)

    if datatype eq 'ast' then $
        return, themis_read_asi_info_ast(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version)

    if datatype eq 'asc' then $
        return, themis_read_asi_info_asc(input_time_range, site=site, $
        errmsg=errmsg, input_site_info=site_info, version=version)

end


site = 'atha'
time_range = ['2013-01-01','2013-01-01/01']
site_info = themis_read_asi_info(time_range, site=site, id='ast')
end

;+
; Read LANL SOPA/ESP/orbit data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; datatype. A string set which set of variable to read. Use
;   print_datatype to see supported types.
; probe. A string set the probe to read data for.
; level. A string of dummy variable.
; variable. An array of variables to read. Users can omit this keyword
;   unless want to fine tune the behaviour.
; files. A string or an array of N full file names. Set this keyword
;   will set files directly.
; version. A string sets the version of data. Default behaviour is to read
;   the highest version. Set this keyword to read specific version.
;-

pro lanl_read_data, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, $
    time_var_name=time_var_name, time_var_type=time_var_type, generic_time=generic_time

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','lanl'])
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'sopa', $
        base_pattern: '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt', $
        local_paths: ptr_new([local_root,'%Y','%m']), $
        ptr_in_vars: ptr_new(['AVE_FLUX_SOPA_E','AVE_FLUX_I']), $
        ptr_out_vars: ptr_new(['e_flux','p_flux']), $
        time_var_name: 'DateTime', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'sopa_energy', $
        base_pattern: '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt', $
        local_paths: ptr_new([local_root,'%Y','%m']), $
        ptr_in_vars: ptr_new(['SopaEEnergy','SopaPEnergy']), $
        ptr_out_vars: ptr_new(['e_energy','p_energy']), $
        time_var_name: '', $
        time_var_type: '', $
        generic_time: 1, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'orbit', $
        base_pattern: '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt', $
        local_paths: ptr_new([local_root,'%Y','%m']), $
        ptr_in_vars: ptr_new(['SC_GEO']), $
        ptr_out_vars: ptr_new(['r_geo']), $
        time_var_name: 'DateTime', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'orbit2', $
        base_pattern: '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt', $
        local_paths: ptr_new([local_root,'%Y','%m']), $
        ptr_in_vars: ptr_new(['SC_MLAT','SC_MLON','SC_MLT','SC_LAT','SC_LON']), $
        ptr_out_vars: ptr_new(['mlat','mlon','mlt','glat','glon']), $
        time_var_name: 'DateTime', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'esp', $
        base_pattern: '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt', $
        local_paths: ptr_new([local_root,'%Y','%m']), $
        ptr_in_vars: ptr_new(['AVE_FLUC_ESP_E']), $
        ptr_out_vars: ptr_new(['e_flux']), $
        time_var_name: 'DateTime', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    ids = type_dispatch.id
    index = where(ids eq datatype, count)
    if count eq 0 then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    myinfo = type_dispatch[index[0]]
    if n_elements(time_var_name) ne 0 then myinfo.time_var_name = time_var_name
    if n_elements(time_var_type) ne 0 then myinfo.time_var_type = time_var_type

;---Find files, read variables, and store them in memory.
    files = prepare_file(files=files, errmsg=errmsg, $
        file_times=file_times, time=time, $
        stay_local=1, skip_index=1, _extra=myinfo)
    if errmsg ne '' then begin
        errmsg = handle_error('Error in finding files ...')
        return
    endif

;---Convert to CDF.
    foreach file, files, ii do begin
        lanl_convert_txt_to_cdf, file, errmsg=errmsg
        if errmsg ne '' then begin
            errmsg = handle_error('Error in converting to CDF ...')
            return
        endif
        pos = strpos(file, '.', /reverse_search)
        files[ii] = strmid(file,0,pos)+'.cdf'
    endforeach

;---Read data and store them in memory.
    read_and_store_var, files, time_info=time, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif


end


time = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
probe = '1991-080'
datatype = 'sopa'
lanl_read_data, time, probe=probe, id=datatype
end

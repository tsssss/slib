;+
; Read var from files to memory.
; Read given variable and the associated time, depend_1, settings.
;-

function parse_setting, flat_dict

    
    nested_dict = dictionary()

    foreach composite_key, flat_dict.keys() do begin
        value = flat_dict[composite_key]
        keys = strsplit(composite_key,'@',extract=1)
        nkey = n_elements(keys)

        current_level = nested_dict        
        for ii=0,nkey-2 do begin
            key = keys[ii]
            if not current_level.haskey(key) then begin
                current_level[key] = dictionary()
            endif
            current_level = current_level[key]
        endfor
        current_level[keys[nkey-1]] = value
    endforeach
   
   return, nested_dict

end


function read_var_internal, var, time_var, files, time_cache

    rec_list = (time_cache[time_var])['rec_list']
    file_flags = (time_cache[time_var])['file_flags']
    index = where(file_flags eq 1, count)
    if count ne 0 then begin
        times = (time_cache[time_var])['times']
        data = []
        foreach file, files[index], fid do begin
            range = rec_list[fid]
            data = [data,cdf_read_var(var, filename=file, range=range)]
        endforeach
;        data = *(read_data(files[index], var, rec_info=rec_list))
;        data = cdf_read_var(var, filename=files[index], rec_info=rec_list)
    endif else begin
        ; Do nothing??
        data = !null
    endelse
    
    return, data
end

function read_nested_setting, settings, files, time_cache, var_cache

    all_vars = var_cache.keys()
    foreach key, settings.keys() do begin
        val = settings[key]
        val_type = size(val,type=1)
        if val_type eq 7 and n_elements(val) eq 1 then begin
            index = where(all_vars eq val[0], count)
            if count eq 0 then continue
        
            index = strpos(strlowcase(key),'depend_')
            if index[0] ne -1 then continue     ; do not read dep_vars.
        
            ; This is a variable. Need to read it.
            var = val[0]
            vatt = (var_cache[var])['vatt']
            if vatt.haskey('depend_0') then begin
                time_var = vatt['depend_0']
                settings[key] = read_var_internal(var, time_var, files, time_cache)
            endif else begin
                settings[key] = cdf_read_var(var, filename=files[0])
            endelse
        endif else if val_type eq 11 then begin
            settings[key] = read_nested_setting(val, files, time_cache, var_cache)
        endif
    endforeach
    
    return, settings

end

function var_read, vars, files=files, time_range=input_time_range, var_info=out_vars

    retval = !null

;    time_range = time_double(input_time_range)
;    nfile = nelements(files)
;    if nfile eq 0 then begin
;        !error_state.msg = 'No file is available ...'
;        return, retval
;    endif

    ; Check files.
    lprmsg, 'Reading variables from files ...'
    foreach file, files do begin
        if file_test(file) ne 0 then continue
        !error_state.msg = 'File does not exist: '+file+' ...'
        return, retval
        lprmsg, '    '+file
    endforeach


    ; Collect variable info.
    cdf_skeleton = cdf_read_skeleton(files[0])
    var_info = cdf_skeleton['var']
    all_vars = var_info.keys()
    if n_elements(vars) eq 0 then begin
        vars = list()
        foreach var, all_vars do begin
            vatt = (var_info[var])['setting']
            if ~vatt.haskey('var_type') then begin
                if ~vatt.haskey('depend_0') then continue
            endif else begin
                if vatt['var_type'] ne 'data' then continue
            endelse
            vars.add, var
        endforeach
        vars = vars.toarray()
    endif
    nvar = n_elements(vars)
    if nvar eq 0 then begin
        !error_state.msg = 'No var_list ...'
        return, retval
    endif
    if n_elements(out_vars) ne nvar then out_vars = vars

    var_cache = hash()
    foreach var, all_vars do begin
        vatt = (var_info[var])['setting']

        dep_vars = hash()
        foreach key, vatt.keys() do begin
            low_key = strlowcase(key)
            if strmid(low_key,0,6) eq 'depend' then begin
                dep_vars[low_key] = vatt[key]
            endif
        endforeach

        var_cache[var] = hash($
            'name', var, $
            'vatt', vatt, $
            'dep_vars', dep_vars )        
    endforeach


;---Collect info for time_var.
    time_cache = hash()

    foreach var, vars do begin
        dep_vars = (var_cache[var])['dep_vars']

        if not dep_vars.haskey('depend_0') then continue
        time_var = dep_vars['depend_0']
        if time_cache.haskey(time_var) then continue

        time_att = (var_info[time_var])['setting']
        if time_att.haskey('time_var_type') then begin
            time_var_type = time_att['time_var_type']
        endif else begin
            time_var_type = strlowcase((var_info[time_var])['cdftype'])
            time_var_type = strmid(time_var_type, strpos(time_var_type,'cdf_')+4)
            if time_var_type eq 'double' then time_var_type = 'unix'
        endelse
        time_info = dictionary($
            'name', time_var, $
            'type', time_var_type )

        rec_list = list()
        current_times = []
        flags = list()
        foreach file, files, ii do begin
            the_times = cdf_read_var(time_var, filename=file)
            unix_times = convert_time(the_times, from=time_var_type, to='unix')
            if n_elements(time_range) eq 0 then begin
                rec_list.add, !null         ; read all
                flags.add, 1
                current_times = [current_times, unix_times]
            endif else begin
                index = where_pro(unix_times, '[]', time_range, count=count)
                if count eq 0 then begin
                    flags.add, 0           ; skip the file.
                endif else begin
                    rec_list.add, minmax(index)
                    flags.add, 1
                    current_times = [current_times, unix_times[index]]
                endelse
            endelse
        endforeach
        time_info['rec_list'] = rec_list
        time_info['times'] = current_times
        time_info['file_flags'] = flags.toarray()     ; 0: skip this file.

        time_cache[time_var] = time_info
    endforeach


;---Read data.
    foreach var, vars, vid do begin
        out_var = out_vars[vid]
        vatt = (var_cache[var])['vatt']
        dep_vars = (var_cache[var])['dep_vars']

        settings = parse_setting(vatt)
        settings = read_nested_setting(settings, files, time_cache, var_cache)

        if not dep_vars.haskey('depend_0') then begin
            data = read_data(files, var)
            var = var_store(out_var, data, settings=settings)
        endif else begin
            time_var = dep_vars['depend_0']
            data = read_var_internal(var, time_var, files, time_cache)
            times = (time_cache[time_var])['times']
            if not dep_vars.haskey('depend_1') then begin
                var = var_store(out_var, data, times, settings=settings)
            endif else begin
                dep_var = dep_vars['depend_1']
                dep_vatt = (var_cache[dep_var])['vatt']
                if dep_vatt.haskey('depend_0') then begin
                    vals = read_var_internal(dep_var, time_var, files, time_cache)
                endif else begin
                    vals = cdf_read_var(dep_var, filename=files[0])
                endelse
                var = var_store(out_var, data, times, vals, settings=settings)
            endelse
        endelse
    endforeach

    return, out_vars
end


files = '/Volumes/data/sdata/micro_injection/cwt_kev_electron/mms_4/2017/67kev/mms_4_cwt_kev_electron_67kev_2017_0519_v01.cdf'
;files = ['/Volumes/rbsp/efw_flag/boom_flag_v02/rbspa/2013/rbspa_boom_flag_2013_0101_v02.cdf','/Volumes/rbsp/efw_flag/boom_flag_v02/rbspa/2013/rbspa_boom_flag_2013_0102_v02.cdf']
vars = var_read(files=files)
end
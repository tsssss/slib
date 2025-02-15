;+
; A generic wrapper for the variable handling process.
; time_range.
; probe=mission_probe
; func=.
; update=.
; get_name=.
; suffix=.
; errmsg=.
; save_to=data_file.
; time_var=time_var.
;-

function lets_read_this, time_range, probe=mission_probe, sites=sites, $
    func=func_name, $
    update=update, get_name=get_name, suffix=suffix, errmsg=errmsg, $
    save_to=data_file, time_var=time_var, $
    _extra=ex


    routine = func_name
    if n_elements(mission_probe) ne 0 then begin
        ; Need prefix, probe, routine_name, short_name
        if size(mission_probe,type=1) eq 7 then begin
            probe_info = resolve_probe(mission_probe)
        endif else begin
            probe_info = mission_probe
        endelse
        probe = probe_info['probe']
        
        var_info = call_function(routine, time_range, probe=probe, $
            get_name=1, errmsg=errmsg, $
            _extra=ex)
    endif else if n_elements(sites) ne 0 then begin
        var_info = call_function(routine, time_range, sites=sites, $
            get_name=1, errmsg=errmsg, $
            _extra=ex)
    endif else begin
        var_info = call_function(routine, time_range, $
            get_name=1, errmsg=errmsg, $
            _extra=ex)
    endelse
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = add_suffix(var_info,suffix)

    
    
    ; Check if update in memory.
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Check if loading from file.
    if keyword_set(update) then tmp = delete_var_from_file(var_info, file=data_file, errmsg=errmsg)
    is_success = read_var_from_file(var_info, file=data_file, errmsg=errmsg)
    if is_success then return, var_info

    ; Read var from routine.
    if n_elements(mission_probe) ne 0 then begin
        var_info = call_function(routine, time_range, probe=probe, $
            get_name=0, errmsg=errmsg, $
            _extra=ex)
        is_success = save_setting_to_memory(var_info, dictionary('mission_probe',mission_probe,'mission',mission,'probe',probe))
    endif else if n_elements(sites) ne 0 then begin
        var_info = call_function(routine, time_range, sites=sites, $
            get_name=0, errmsg=errmsg, $
            _extra=ex)
        is_success = save_setting_to_memory(var_info, dictionary('sites',sites))
    endif else begin
        var_info = call_function(routine, time_range, $
            get_name=0,  errmsg=errmsg, $
            _extra=ex)
    endelse
    is_success = save_setting_to_memory(var_info, dictionary('requested_time_range',time_double(time_range)))
    if n_elements(time_var) ne 0 then is_success = interp_var_to_time(var_info, time_var=time_var)
    
    ; Save to file.
    if n_elements(data_file) ne 0 then begin
        is_success = save_var_to_file(var_info, file=data_file, time_var=time_var)
    endif
    
    return, var_info

end
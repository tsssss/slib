;+
; This is on top of lets_read_this.
;
; phys_quant. 'efield','bfield',etc.
; input_time_range. str or double for unix time.
; source=. ['mission','probe'].
; update=. Set to force update the data. Otherwise return if data exist in memory.
; get_name=. Return the var_info.
; suffix=. Set to add suffix to var_info.
; save_to=. Set to save data to the cdf file.
; time_var=. Set to interpolate data to that time.
; errmsg=.
;-

function lets_read, phys_quant, input_time_range, source=source_info, $
    update=update, get_name=get_name, suffix=suffix, errmsg=errmsg, $
    save_to=data_file, time_var=time_var, coord=coord, $
    _extra=ex

    retval = !null

    if n_elements(source_info) eq 0 then return, retval
    time_range = time_double(input_time_range)

    ; Get var_info.
    mission = source_info[0]
    routine = mission+'_read_'+phys_quant
    nsource = n_elements(source_info)
    if nsource eq 1 then begin
        var_info = call_function(routine, time_range, get_name=1, coord=coord, extra=ex)
    endif else begin
        probe = source_info[1]
        mission_probe = mission+probe
        var_info = call_function(routine, time_range, probe=probe, get_name=1, coord=coord, extra=ex)
        is_success = save_setting_to_memory(var_info, dictionary('mission_probe',mission_probe,'mission',mission,'probe',probe))
    endelse
    if n_elements(suffix) eq 0 then suffix = ''
    if suffix ne '' then var_info = add_suffix(var_info,suffix)
    if keyword_set(get_name) then return, var_info

    ; Force to add necessary settings.

    ; Check if update in memory.
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Check if loading from file.
    if keyword_set(update) then tmp = delete_var_from_file(var_info, file=data_file, errmsg=errmsg)
    is_success = read_var_from_file(var_info, file=data_file, errmsg=errmsg)
    if is_success then return, var_info

    ; Read var from routine.
    if nsource eq 1 then begin
        var_info = call_function(routine, time_range, coord=coord, _extra=ex, var_info=var_info)
    endif else begin
        var_info = call_function(routine, time_range, probe=probe,coord=coord, _extra=ex, var_info=var_info)
        is_success = save_setting_to_memory(var_info, dictionary('mission_probe',mission_probe,'mission',mission,'probe',probe))
    endelse
    is_success = save_setting_to_memory(var_info, dictionary('requested_time_range',time_range))
    if n_elements(time_var) ne 0 then is_success = interp_var_to_time(var_info, time_var=time_var)
    
    ; Save to file.
    if n_elements(data_file) ne 0 then begin
        is_success = save_var_to_file(var_info, file=data_file, time_var=time_var)
    endif
    
    return, var_info

end
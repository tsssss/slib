;+
; Wrapper to handle memory management.
; 
; reader functions have to accept the following keywords:
;   1. get_name=. Maybe delegate naming here?
;   2. time_range. optional.
;-

function read, mission, phys_var, time_range, $
    get_name=get_name, update=update, ids=ids, $
    _extra=ex


    settings = dictionary(ex)
    my_ex = ex
    func = mission+'_read_'+phys_var
    if n_elements(ids) ne 0 then func = strjoin([func,ids])
    !error_state.msg = ''
    
    ; Obtain var_info.
    var_info = call_function(func, time_range, _extra=my_ex, get_name=1)
    if keyword_set(get_name) then return, var_info

    ; Check if update in memory.
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Check if loading from file.
    if keyword_set(update) then tmp = delete_var_from_file(var_info, file=data_file, errmsg=errmsg)
    is_success = read_var_from_file(var_info, file=data_file, errmsg=errmsg)
    if is_success then return, var_info

    ; Load from routine.
    var_info = call_function(func, time_range, _extra=my_ex)
    ; Add settings.
    is_success = save_setting_to_memory(var_info, dictionary('requested_time_range',time_range))
    mission = (strsplit(func,'_'))[0]
    settings = dictionary(ex)
    probe = settings.haskey('probe') ? settings.probe : !null
    is_success = save_setting_to_memory(var_info, dictionary('mission',mission,'probe',probe))

end


; Test.
time_range = ['2016-01-03','2016-01-04']
probe = 'a'
var = read('rbsp','efield', time_range, probe=probe)
end
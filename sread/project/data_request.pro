;+
; Create a data request.
;-

function data_request, event, mission=mission, phys_quant=phys_quant, $
    time_range=input_time_range, probe=probe, settings=settings

    routine = mission+'_read_'+phys_quant
    if n_elements(input_time_range) eq 0 then input_time_range = event.time_range
    time_range = time_double(input_time_range)
    time_range_str = time_string(time_range)

    if n_elements(settings) eq 0 then settings = dictionary()
    if n_elements(probe) ne 0 then settings['probe'] = probe

    id_info = dictionary($
        'mission', mission, $
        'phys_quant', phys_quant, $
        'time_range', time_range )
    setting_keys = settings.keys()
    if n_elements(setting_keys) gt 0 then begin
        setting_keys = sort_uniq(setting_keys.toarray())
        foreach key, setting_keys do begin
            id_info[key] = settings[key]
        endforeach
    endif


    
    event.data_requests.add, request
    
    var_info = call_function(routine, time_range, _extra=settings)


end
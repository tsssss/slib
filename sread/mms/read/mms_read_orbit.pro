;+
; Read MMS orbit. Save as 'mms_r_<coord>'. Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. '1','2','3','4'.
; ids=. ['sdata','cdaweb'].
;-

function mms_read_orbit, input_time_range, probe=probe, ids=ids, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex

    if n_elements(ids) eq 0 then ids = ['sdata']

    prefix = 'mms'+probe+'_'
    if n_elements(suffix) eq 0 then suffix = '_'+strjoin(ids, '_')
    if n_elements(coord) eq 0 then coord = 'gsm'
    var_info = prefix+'r_'+coord+suffix
    if keyword_set(get_name) then return, var_info

    time_range = time_double(input_time_range)
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    my_name = get_filename()
    routine = get_file_stem(my_name)
    foreach id, ids do routine += '_'+id
    return, call_function(routine, time_range, probe=probe, coord=coord, $
        errmsg=errmsg, resolution=resolution, var_info=var_info, _extra=_extra)
    
end

time_range = ['2015-01-03','2017-01-04']
foreach probe, mms_probes() do begin
    ids = 'sdata'
    var = mms_read_orbit(time_range, probe=probe, ids=ids)
endforeach

end

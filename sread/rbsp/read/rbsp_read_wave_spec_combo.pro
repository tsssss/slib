;+
; Read E and B wave spectrogram.
;-

function rbsp_read_wave_spec_combo, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, update=update


    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    settings = ['e','b']

    vinfo = dictionary()
    foreach key, settings do begin
        vinfo[key] = prefix+key+'_spec'
    endforeach
    if keyword_set(get_name) then return, vinfo
    time_range = time_double(input_time_range)
    foreach key, settings do begin
        if keyword_set(update) then del_data, vinfo[key]
        if ~check_if_update(vinfo[key], time_range) then continue
        var = rbsp_read_wave_spec(time_range, probe=probe, errmsg=errmsg, id=key)
        if errmsg ne '' then return, retval
        tmp = rename_var(var, output=vinfo[key])
    endforeach

    return, vinfo

end


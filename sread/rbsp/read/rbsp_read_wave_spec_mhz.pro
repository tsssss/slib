;+
; Read E and B wave spectrogram.
;
; Return rbspx_[e,b]_spec_khz.
;-

function rbsp_read_wave_spec_mhz, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=id, update=update, suffix=suffix

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(id) eq 0 then id = 'e'

    if n_elements(suffix) eq 0 then suffix = '_mhz'
    out_var = prefix+id+'_spec'+suffix
    if keyword_set(get_name) then return, out_var
    time_range = time_double(input_time_range)
    if keyword_set(update) then del_data, out_var
    if ~check_if_update(out_var, time_range) then return, out_var

    files = rbsp_load_emfisis(time_range, probe=probe, $
        id='l2%hfr%spectra-merged', errmsg=errmsg)
    if errmsg ne '' then return, retval
    

    var_list = list()
    in_var = 'HFR_Spectra'
    var_list.add, dictionary($
        'in_vars', in_var, $
        'out_vars', out_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    freq_var = 'HFR_frequencies'
    freqs = cdf_read_var(freq_var, filename=files[0])
    data = get_var_data(out_var, times=times)
    unit = '(mV/m)!U2!N/Hz'
    data *= 1e6     ; convert unit from (V/m)^2/Hz to (mV/m)^2/Hz
    store_data, out_var, times, data, freqs
    
    zrange = [1e-10,1e-5]
    yrange = [1e4,5e5]
    add_setting, out_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'spec', $
        'unit', unit, $
        'ytitle', 'Freq (Hz)', $
        'yrange', yrange, $
        'ylog', 1, $
        'zlog', 1, $
        'zrange', zrange, $
        'short_name', strupcase(id) )
    return, out_var

end

time_range = ['2015-03-17','2015-03-18']
foreach probe, ['a','b'] do $
    foreach id, ['e','b'] do var = rbsp_read_wave_spec_khz(time_range, probe=probe, id=id)
    var = rbsp_read_wave_spec_mhz(time_range, probe=probe, updat=1)
end
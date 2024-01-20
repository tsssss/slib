;+
; Read E and B wave spectrogram.
;
; Return rbspx_[e,b]_spec_khz.
;-

function rbsp_read_wave_spec_khz, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=id, update=update, suffix=suffix

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(id) eq 0 then id = 'b'

    if n_elements(suffix) eq 0 then suffix = '_khz'
    out_var = prefix+id+'_spec'+suffix
    if keyword_set(get_name) then return, out_var
    time_range = time_double(input_time_range)
    if keyword_set(update) then del_data, out_var
    if ~check_if_update(out_var, time_range) then return, out_var

    files = rbsp_load_emfisis(time_range, probe=probe, $
        id='l2%wfr%spectral-matrix-diagonal-merged', errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_vars = strupcase(id)+['u','v','w']
    if id eq 'e' then in_vars = strupcase(id)+['u','v']
    in_vars = in_vars+in_vars
    out_vars = prefix+in_vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    freq_var = 'WFR_frequencies'
    freqs = cdf_read_var(freq_var, filename=files[0])
    nfreq = n_elements(freqs)
    times = get_var_time(out_vars[0])
    ntime = n_elements(times)
    data = fltarr(ntime,nfreq)
    foreach var, out_vars do begin
        data += get_var_data(var)
    endforeach

        
    ; Fix E spec.
    if id eq 'e' then begin
        f_prob = 2e3
        tmp = min(freqs-f_prob, abs=1, index)
        data[*,index] = ($
            data[*,index-1]*(freqs[index+1]-freqs[index])+$
            data[*,index+1]*(freqs[index]-freqs[index-1]))/(freqs[index+1]-freqs[index-1])
        data *= 1e6 ; convert (V/m)^2/Hz to (mV/m)^2/Hz
    endif
    
    unit = (id eq 'b')? 'nT!U2!N/Hz': '(mV/m)!U2!N/Hz'
    zrange = (id eq 'b')? [1e-8,1e-3]: [1e-6,1e-1]
    store_data, out_var, times, data, freqs
    add_setting, out_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'spec', $
        'unit', unit, $
        'ytitle', 'Freq (Hz)', $
        'yrange', [1e1,1e4], $
        'ylog', 1, $
        'zlog', 1, $
        'zrange', zrange, $
        'short_name', strupcase(id) )
    return, out_var

end

time_range = ['2015-03-17','2015-03-18']
foreach probe, ['a','b'] do $
    foreach id, ['e','b'] do var = rbsp_read_wave_spec_khz(time_range, probe=probe, id=id, updat=1)
end
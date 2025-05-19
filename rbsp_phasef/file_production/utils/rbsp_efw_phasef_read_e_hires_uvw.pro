;+
; Read rbspx_efw_esvy, rbspx_efw_esvy_no_offset.
; Adopted from rbsp_efw_make_l2_esvy_uvw.
; Here we use the intermediate data product e_uvw directly.
; e_uvw uses a better DC offset removal algorithm.
; Therefore the v02 e_uvw has alightly larger amplitude than v01.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_phasef_read_e_hires_uvw, date, probe=probe, errmsg=errmsg, log_file=log_file

    errmsg = ''

;---Check input.
    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    data_type = 'e_hires_uvw'
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    secofday = 86400d
    time_range = date+[0,secofday]
    timespan, date, secofday, /second
    ; This reads rbspx_efw_esvy.
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', coord='uvw'
    ; Thie reads rbspx_uvw, which is rbspx_efw_esvy_no_offset.
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe

;---Check data availability.
    e_uvw_var = prefix+'e_uvw'
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    if ~spd_check_tvar(e_uvw_var) then begin
        errmsg = e_uvw_var+' is not available. Exit processing ...'
        lprmsg, errmsg, log_file
        return
    endif
    get_data, e_uvw_var, times, e_uvw

    ; Remove NaNs. (ignore spin-axis data)
    index = where(finite(times) and finite(e_uvw[*,0]) and finite(e_uvw[*,1]), count)
    if count eq 0 then begin
        errmsg = 'No valid data. Abort ...'
        lprmsg, errmsg, log_file
        return
    endif
    e_var = prefix+'efw_esvy_no_offset'
    store_data, e_var, times, e_uvw

    ; Interpolate e_uvw_raw to e_uvw.
    e_raw_var = prefix+'efw_esvy'
    get_data, e_raw_var, tmp, e_raw
    e_raw = sinterpol(e_raw, tmp, times)
    store_data, e_raw_var, times, e_raw

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
date = '2019-10-13'
date = '2013-06-07'

phasef_read_e_hires_uvw, date, probe=probe
rbsp_efw_phasef_read_e_hires_uvw, date, probe=probe
end

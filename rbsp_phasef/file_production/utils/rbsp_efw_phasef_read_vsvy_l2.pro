;+
; Read vsvy and vsvy_avg.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_phasef_read_vsvy_l2, date, probe=probe, errmsg=errmsg, log_file=log_file


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


    data_type = 'vsvy_hires'
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
    rbsp_efw_phasef_read_vsvy, time_range, probe=probe

    vsvy_var = prefix+'efw_vsvy'
    get_data, vsvy_var, times, vsvy
    ntime = n_elements(times)
    ndim = 3
    vsvy_avg = fltarr(ntime,ndim)
    for ii=0,ndim-1 do begin
        index = ii*2+[0,1]
        vsvy_avg[*,ii] = 0.5*(total(vsvy[*,index],2))
    endfor
    vsvy_avg_var = prefix+'efw_vsvy_vavg'
    store_data, vsvy_avg_var, times, vsvy_avg

end

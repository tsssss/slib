;+
; Read position vars, r_gse, v_gse, mlt, mlat, lshell.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_phasef_read_pos_var, date, probe=probe, errmsg=errmsg, log_file=log_file


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

    data_type = 'pos_var'
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
	rbsp_read_spice_var, time_range, probe=probe
	
	; spice saves R in Re, we want km.
	re = 6378d
	var = prefix+'r_gse'
	get_data, var, times, data
	data *= re
	store_data, var, times, data
	
	get_data, 'mlt', times, mlt
	index = where(mlt gt 12, count)
	if count ne 0 then begin
	    mlt[index] -= 24
	    store_data, 'mlt', times, mlt
	endif

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2019-10-13'
rbsp_efw_phasef_read_pos_var, date, probe=probe
end

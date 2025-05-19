;+
; Read rbspx_efw_qual, which is an older version of flags_all.
; Here we update efw_qual to the 20-element flag.
; Adopted from rbsp_efw_make_l2_esvy_uvw.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_phasef_read_efw_qual, date, probe=probe, errmsg=errmsg, log_file=log_file

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

    data_type = 'efw_qual'
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
    boom_pair = rbsp_efw_phasef_get_boom_pair(date, probe=probe)
    rbsp_efw_phasef_read_flag_20, time_range, probe=probe, boom_pair=boom_pair
    flag_var = rename_var(prefix+'flag_20', output=prefix+'efw_qual')
    ; Look-up table for quality flags
    ;  0: global_flag
    ;  1: eclipse
    ;  2: maneuver
    ;  3: efw_sweep
    ;  4: efw_deploy
    ;  5: v1_saturation
    ;  6: v2_saturation
    ;  7: v3_saturation
    ;  8: v4_saturation
    ;  9: v5_saturation
    ; 10: v6_saturation
    ; 11: Espb_magnitude
    ; 12: Eparallel_magnitude
    ; 13: magnetic_wake
    ; 14: autobias
    ; 15: charging
    ; 16: charging_extreme
    ; 17: density
    ; 18: boom_flag
    ; 19: undefined


end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'
rbsp_efw_phasef_read_efw_qual, date, probe=probe
end

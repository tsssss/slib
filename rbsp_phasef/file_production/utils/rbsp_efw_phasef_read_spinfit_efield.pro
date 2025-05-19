;+
; Read spinfit E field in MGSE for all boom pairs.
;-

pro rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe

;    if n_elements(local_root) eq 0 then local_root = join_path([homedir(),'data','rbsp'])

    rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe, local_root=local_root
    rbsp_efw_phasef_read_e_spinfit_diagonal, time_range, probe=probe, local_root=local_root

end


;secofday = constant('secofday')
;
;foreach probe, ['a'] do begin
;    time_range = rbsp_efw_phasef_get_valid_range('e_spinfit',probe=probe)
;    days = make_bins(time_range+[0,-1]*secofday,secofday)
;    foreach day, days do begin
;        rbsp_efw_phasef_read_spinfit_efield, day+[0,secofday], probe=probe
;    endforeach
;endforeach
;
;
;stop


time_range = time_double(['2012-09-01','2014-06-01'])
probes = ['a','b']

;time_range = time_double(['2018-07-22/21:00','2018-07-23/00:00'])
;probes = ['a','b']

foreach probe, probes do rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
end

;+
; This program is used to run all codes for data production.
;-


;---Settings.
    test = 1
    secofday = constant('secofday')
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    if keyword_set(test) then begin
        probes = ['a']
        test_time_range = time_double(['2015-05-28','2015-05-29'])
    endif else begin
        probes = ['a','b']
    endelse

;---L3.
    version = 'v05'
    routine = 'rbsp_efw_phasef_gen_l3_'+version
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe
        time_range = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
        if keyword_set(test) then time_range = test_time_range
        days = make_bins(time_range+[0,-1]*secofday, secofday)
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l3_'+version,str_year])
            base = prefix+'efw-l3_'+time_string(day,tformat='YYYYMMDD')+'_'+version+'.cdf'
            file = join_path([path,base])
            if keyword_set(test) then begin
                file = join_path([homedir(),'rbsp_efw_phasef_test_data_production',base])
                if file_test(file) eq 1 then file_delete, file
            endif else begin
                if file_test(file) eq 1 then continue
            endelse
            print, file
            call_procedure, routine, day, probe=probe, filename=file
        endforeach
    endforeach


end



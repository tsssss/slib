;+
; Return basic sc info.
; 
; key.
; probe=.
;-

function rbsp_info, key, probe=the_probe

    probe = (n_elements(the_probe) ne 0)? strmid(the_probe,0,1,/reverse): 'a'
    
    spice_data_range = !null
    case probe of
        'a': spice_data_range = time_double(['2012-09-05','2019-10-15'])
        'b': spice_data_range = time_double(['2012-09-05','2019-07-17'])
    endcase
    
    ; https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspa/l3/emfisis/
    emfisis_l3_data_range = !null
    case probe of
        'a': emfisis_l3_data_range = time_double(['2012-09-08','2019-10-15'])
        'b': emfisis_l3_data_range = time_double(['2012-09-08','2019-07-17'])
    endcase
    
    ; https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspa/l3/efw/
    efw_l3_data_range = !null
    case probe of
        'a': efw_l3_data_range = time_double(['2012-09-18','2017-09-29'])
        'b': efw_l3_data_range = time_double(['2012-09-18','2019-07-17'])
    endcase
    
    ; https://cdaweb.gsfc.nasa.gov/pub/data/rbsp/rbspa/l2/efw/vsvy-highres/
    ; CDFs are from 2012-09-05 but really good data from 2012-09-08.
    efw_l2_data_range = !null
    case probe of
        'a': efw_l2_data_range = time_double(['2012-09-08','2019-10-14'])
        'b': efw_l2_data_range = time_double(['2012-09-08','2019-07-17'])
    endcase
    
    efw_phasef_data_range = !null
    case probe of
        'a': efw_phasef_data_range = time_double(['2012-09-08','2019-10-16'])
        'b': efw_phasef_data_range = time_double(['2012-09-08','2019-07-18'])
    endcase

    
    info = dictionary($
        'spice_data_range', spice_data_range, $
        'emfisis_l3_data_range', emfisis_l3_data_range, $
        'efw_l3_data_range', efw_l3_data_range, $
        'efw_l2_data_range', efw_l2_data_range, $ 
        'efw_phasef', efw_phasef_data_range, $       
        'spin_period', 10.95d, $
        'spin_rate', 10.95d, $
        'boom_length', [100d,100,12], $
        'v_uvw_data_rate', 0.03125d)

    if n_elements(key) eq 0 then return, info
    if info.haskey(key) then return, info[key] else return, info

end

print, rbsp_info('spin_period')
end
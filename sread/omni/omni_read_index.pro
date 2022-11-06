;+
; Read OMNI geomagnetic indices, e.g., AE, Dst.
; resolution can be '1min', '5min'.
;-
;
pro omni_read_index, time, resolution=resolution, errmsg=errmsg

    if n_elements(resolution) eq 0 then resolution = '1min'

    omni_read, time, id='ae_dst', resolution=resolution, errmsg=errmsg
    if errmsg ne '' then return

    case resolution of
        '1min': dt = 60d
        '5min': dt = 300d
    endcase
    
    foreach var, ['ae','dst'] do begin
        get_data, var, times, data
        store_data, var, times, float(data)
    endforeach
    
    fillval = !values.f_nan
    get_data, 'ae', times, ae
    index = where(abs(ae) ge 1e5, count)
    if count ne 0 then begin
        ae[index] = fillval
        store_data, 'ae', times, ae
    endif
    

    foreach var, ['ae','dst'] do begin
        case var of
            'ae': short_name = 'AE'
            'dst': short_name = 'Dst'
        endcase
        add_setting, var, /smart, {$
            display_type: 'scalar', $
            unit: 'nT', $
            short_name: short_name}
        uniform_time, var, dt
    endforeach

end

time = time_double(['2014-08-25','2014-09-05'])
time = time_double(['2018-08-25','2018-09-05'])
omni_read_index, time
end
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
        case var of
            'ae': shortname = 'AE'
            'dst': shortname = 'Dst'
        endcase
        add_setting, var, /smart, {$
            display_type: 'scalar', $
            unit: 'nT', $
            short_name: short_name}
        uniform_time, var, dt
    endforeach

end

time = time_double(['2014-08-25','2014-09-05'])
omni_read_index, time
end
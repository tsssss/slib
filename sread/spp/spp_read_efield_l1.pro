;+
; Read DC electric field.
;-
;

pro spp_read_efield_l1, time 

    vars = ['time_unix','wf_pkt_data','wf_pkt_data_v','wav_tap']
    xyz = ['x','y','z']
    
    rad = !dpi/180d
    deg = 180d/!dpi
    
    nprobe = 5
    ivars = 'dfb_wf'+string(findgen(nprobe)+6,format='(I02)')
    ovars = 'spp_v'+string(findgen(nprobe)+1,format='(I0)')
    for j=0, nprobe-1 do begin
        spp_read_fields, time, ivars[j], level='l1', errmsg=errmsg, variable=vars
        
        ; convert to 1d data.
        all_wf_time_list = list()
        all_wf_decompressed_v_list = list()
        
        get_data, 'wf_pkt_data', data = d
        get_data, 'wf_pkt_data_v', data = d_v
        get_data, 'wav_tap', data = d_tap
        
        
        ideal_delay = !null
        delay_loc = 0d
        ;print, 'Sample Rate      ', 'Ideal Cumulative delay (s) - V or E DC only'
        for index = 0, 15, 1 do begin
            if index eq 0 then delay_loc += (4d / 18750d)
            if index gt 0 then delay_loc += (3d / (18750d/ 2d^(index)) + 1d / (18750d/ 2d^(index - 1d)) )
            ideal_delay = [ideal_delay, delay_loc]
            ;print, 18750d/ 2d^(index), delay_loc
        endfor
        
        
        for i=0, n_elements(d.x)-1 do begin
            wf_i0 = reform(d.y[i,*])
            wf_i = wf_i0[where(wf_i0 GT -2147483647l)]
            wf_i0_v = reform(d_v.y[i,*])
            wf_i_v = wf_i0_v[where(wf_i0 gt -2147483647l)]
            ;if keyword_set(compressed) then wf_i = decompress(uint(wf_i))
            all_wf_decompressed_v_list.add, wf_i_v
            
            ideal_delay_i = ideal_delay[d_tap.y[i]]
            delay_i = ideal_delay_i + 0.5/(18750d / (2d^d_tap.y[i]))
            wf_time = d_tap.x[i] + $
                (dindgen(n_elements(wf_i))) / $
                (18750d / (2d^d_tap.y[i])) - delay_i
            all_wf_time_list.add, wf_time
        endfor
        
        all_wf_time = (spp_fld_square_list(all_wf_time_list)).toarray()
        all_wf_decompressed_v = (spp_fld_square_list(all_wf_decompressed_v_list)).toarray()
        
        all_wf_time = reform(transpose(all_wf_time), n_elements(all_wf_time))
        all_wf_decompressed_v = reform(transpose(all_wf_decompressed_v), n_elements(all_wf_time))
        
        tvar = ovars[j]
        store_data, tvar, all_wf_time, all_wf_decompressed_v
    endfor
    
    get_data, 'spp_v1', uts, v1
    get_data, 'spp_v2', tuts, v2 & v2 = interpol(v2, tuts, uts)
    get_data, 'spp_v3', tuts, v3 & v3 = interpol(v3, tuts, uts)
    get_data, 'spp_v4', tuts, v4 & v4 = interpol(v4, tuts, uts)
    get_data, 'spp_v5', tuts, v5 & v5 = interpol(v5, tuts, uts)
    
    e12 = (v1-v2)
    e34 = (v3-v4)
    ez = (v1+v2+v3+v4)*0.25-v5
    
    cost = cos(45*rad)
    sint = sin(45*rad)
    ex = e12*cost-e34*sint
    ey = e12*sint+e34*cost
    
    var = 'spp_e_xyz'
    store_data, var, uts, [[ex],[ey],[ez]]
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'V', $
        short_name: 'E', $
        coord: 'XYZ', $
        coord_labels: xyz, $
        colors: [6,4,2]}

end
;+
; Check hires v_gsm and that from interpolation.
;-


pro check_hires_quaternion, date, probe=probe, component_index=component_index
    prefix = 'rbsp'+probe+'_'


;---Get time range.
    ;time_range = time_double(['2013-07-19/14:39','2013-07-19/15:32'])
    ;time_range = time_double(['2013-07-19/08:00','2013-07-19/16:00'])
    time_range = date+[0,3600*12]


;---Common times.
    hires_time_step = 1d/16
    hires_times = make_bins(time_range, hires_time_step)


;---Test resolutions: from spice.
    time_steps = hires_time_step*[1.,4,16]
    q_colors = sgcolor(['red','green','blue','purple'])
    defsysv,'!rbsp_spice', exists=flag
    if flag eq 0 then rbsp_load_spice_kernel
    scid = strupcase(prefix+'science')
    cspice_str2et, time_string(time_range[0], tformat='YYYY-MM-DDThh:mm:ss.ffffff'), epoch0
    foreach time_step, time_steps do begin
        times = make_bins(time_range, time_step)
        epochs = epoch0+times-time_range[0]
        cspice_pxform, scid, 'GSM', epochs, m_uvw2gsm
        m_uvw2gsm = transpose(m_uvw2gsm)
        q_uvw2gsm = mtoq(m_uvw2gsm)

        suffix = '_'+string(1d/time_step,format='(I0)')+'Hz'
        store_data, prefix+'m_uvw2gsm'+suffix, times, m_uvw2gsm
        store_data, prefix+'q_uvw2gsm'+suffix, times, q_uvw2gsm, limits={$
            ytitle:'(#)', $
            colors:q_colors}
        u_gsm = m_uvw2gsm[*,*,1]
        store_data, prefix+'ux_gsm'+suffix, times, u_gsm[*,2], limits={$
            ytitle: '(#)', $
            colors: constant('rgb') }
    endforeach


;---Interpolate and compare to the highest resolution.
    test_suffix = '_'+string(1d/hires_time_step,format='(I0)')+'Hz'
    ux_gsm = get_var_data(prefix+'ux_gsm'+test_suffix)
    q0_uvw2gsm = get_var_data(prefix+'q_uvw2gsm'+test_suffix)
    
    suffixs = '_'+string(1d/time_steps,format='(I0)')+'Hz'
    foreach suffix, suffixs do begin
        q_uvw2gsm = get_var_data(prefix+'q_uvw2gsm'+suffix, times=times)
        q_uvw2gsm = qslerp(q_uvw2gsm, times, hires_times)
        m_uvw2gsm = qtom(q_uvw2gsm)
        u_gsm= m_uvw2gsm[*,*,1]
        store_data, prefix+'ux_gsm'+suffix+'_interp', hires_times, u_gsm[*,2], limits={$
            ytitle: '(#)', $
            colors: constant('rgb') }

        dux_gsm = u_gsm[*,2]-ux_gsm
        store_data, prefix+'dux_gsm'+suffix, hires_times, dux_gsm, limits={$
            constant: 0, $
            ytitle: '(#)', $
            colors: constant('rgb') }
        
        dq_uvw2gsm = q_uvw2gsm-q0_uvw2gsm
        store_data, prefix+'dq_uvw2gsm'+suffix, hires_times, dq_uvw2gsm, limits={$
            ytitle:'(#)', $
            colors:q_colors}
    endforeach

    tplot, prefix+['dux_gsm'+suffixs,'ux_gsm_16Hz','ux_gsm_1Hz'], trange=time_range
    ;tplot, prefix+['dq_uvw2gsm'+suffixs,'q_uvw2gsm_16Hz'], trange=time_range
    stop

end


;---Input.
date = time_double('2013-08-19')
probe = 'a'
ndim = 3
for ii=0,ndim-1 do check_hires_quaternion, date, probe=probe, component_index=ii
end

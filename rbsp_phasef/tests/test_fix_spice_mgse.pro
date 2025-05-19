;+
; Test to fix spin tone of UVW2GSE.
;-

probe = 'b'
time_range = time_double(['2013-05-02','2013-05-03'])
time_range = time_double(['2013-05-16','2013-05-17'])
;time_range = time_double(['2013-05-21','2013-05-22'])
;time_range = time_double(['2013-01-13','2013-01-14'])

;probe = 'a'
;time_range = time_double(['2012-10-02','2012-10-03'])
;time_range = time_double(['2013-06-02','2013-06-03'])

rbsp_read_quaternion, time_range, probe=probe

test = 1

    prefix = 'rbsp'+probe+'_'

;---Read matrix.
    rbsp_read_quaternion, time_range, probe=probe
    q_uvw2gse = get_var_data(prefix+'q_uvw2gse', times=times)
    ntime = n_elements(times)

    m_uvw2gse = qtom(q_uvw2gse)
    ndim = 3
    uvw = constant('uvw')
    xyz = constant('xyz')
    for ii=0,ndim-1 do begin
        vec_gse = reform(m_uvw2gse[*,*,ii])
        vec_var = prefix+uvw[ii]+'_gse'
        store_data, vec_var, times, vec_gse
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(uvw[ii]), $
            'unit', '#', $
            'coord', 'GSE', $
            'coord_labels', xyz )
        for jj=0,ndim-1 do begin
            store_data, prefix+uvw[ii]+xyz[jj]+'_gse', times, vec_gse[*,jj]
        endfor
    endfor

;---Convert to DSC.
    rad = constant('rad')
    rbsp_read_spice, time_range, probe=probe, id='spin_phase'
    spin_phase = get_var_data(prefix+'spin_phase')*rad
    cost = cos(spin_phase)
    sint = sin(spin_phase)
    u_gse = get_var_data(prefix+'u_gse')
    v_gse = get_var_data(prefix+'v_gse')
    w_gse = get_var_data(prefix+'w_gse')
    vec_dsc = fltarr(ntime,ndim)

    
    vec_var = prefix+'x_dsc'
    for ii=0,ndim-1 do vec_dsc[*,ii] = u_gse[*,ii]*cost-v_gse[*,ii]*sint
    store_data, vec_var, times, vec_dsc
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'X', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    for ii=0,ndim-1 do store_data, prefix+'x'+xyz[ii]+'_gse', times, vec_dsc[*,ii]
    
    
    vec_var = prefix+'y_dsc'
    for ii=0,ndim-1 do vec_dsc[*,ii] = u_gse[*,ii]*sint+v_gse[*,ii]*cost
    store_data, vec_var, times, vec_dsc
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'Y', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    for ii=0,ndim-1 do store_data, prefix+'y'+xyz[ii]+'_gse', times, vec_dsc[*,ii]

    vec_var = prefix+'z_dsc'
    vec_dsc = w_gse
    store_data, vec_var, times, vec_dsc
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'Z', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    for ii=0,ndim-1 do store_data, prefix+'z'+xyz[ii]+'_gse', times, vec_dsc[*,ii]


;---Correct in DSC.
    ; 1. Fix w_gse: a) smooth; b) unit vector.
    ; 2. Rotate uvw according to the corrected w_gse.
    vars = prefix+['x'+xyz,'z'+xyz]+'_gse'
;    smooth_window = 1800
;    time_step = total(times[0:1]*[-1,1])
;    two_colors = sgcolor(['blue','red'])
;    smooth_width = smooth_window/time_step
;    foreach var, vars do begin
;        vec = get_var_data(var)
;        vec_fix = smooth(vec,smooth_width,/nan,/edge_mirror)
;        store_data, var+'_fix', times, vec_fix
;        store_data, var, times, [[vec],[vec_fix]], limits={colors:two_colors, label:['orig','fixed']}
;    endforeach

    ; Smooth introduces extra deviation if the original signal is weird.
    ; Try to interpolate.
    interp_window = 600.    ; sec.
    interp_times = make_bins(time_range, interp_window)
    common_time_step = total(times[0:1]*[-1,1])
    interp_index = (interp_times-time_range[0])/common_time_step
    interp_times = interp_times[0:-2]+0.5*interp_window
    ninterp_time = n_elements(interp_times)
    two_colors = sgcolor(['red','blue'])
    foreach var, vars do begin
        vec = get_var_data(var)
        ;vec_fix = interpol(vec[interp_index],times[interp_index],times)
        vec_interp = dblarr(ninterp_time)
        for ii=0,ninterp_time-1 do vec_interp[ii] = median(vec[interp_index[ii]:interp_index[ii+1]])
        vec_fix = interpol(vec_interp, interp_times, times)
        store_data, var+'_fix', times, vec_fix
        store_data, var, times, [[vec],[vec_fix]], limits={colors:two_colors, label:['orig','fixed']}
    endforeach


    vec = fltarr(ntime,ndim)
    
    for ii=0,ndim-1 do vec[*,ii] = get_var_data(prefix+'x'+xyz[ii]+'_gse_fix')
    vec = sunitvec(vec)
    vec_var = prefix+'x_dsc_fix'
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'X', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    for ii=0,ndim-1 do vec[*,ii] = get_var_data(prefix+'z'+xyz[ii]+'_gse_fix')
    vec = sunitvec(vec)
    vec_var = prefix+'z_dsc_fix'
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'Z', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    
    x_dsc = get_var_data(prefix+'x_dsc_fix')
    z_dsc = get_var_data(prefix+'z_dsc_fix')
    y_dsc = vec_cross(z_dsc, x_dsc)
    vec = sunitvec(y_dsc)
    vec_var = prefix+'y_dsc_fix'
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'Y', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )
    x_dsc = vec_cross(y_dsc, z_dsc)
    vec = sunitvec(x_dsc)
    vec_var = prefix+'x_dsc_fix'
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'X', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )


;---Change back to UVW.
    vec_var = prefix+'u_fix'
    for ii=0,ndim-1 do vec[*,ii] = x_dsc[*,ii]*cost+y_dsc[*,ii]*sint
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'U', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )
    
    vec_var = prefix+'v_fix'
    for ii=0,ndim-1 do vec[*,ii] =-x_dsc[*,ii]*sint+y_dsc[*,ii]*cost
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'V', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )
    
    vec_var = prefix+'w_fix'
    vec = z_dsc
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'W', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )

    
;---Get m and q.
    m_uvw2gse = dblarr(ntime,ndim,ndim)
    for ii=0,ndim-1 do m_uvw2gse[*,*,ii] = get_var_data(prefix+uvw[ii]+'_fix')
    q_uvw2gse = mtoq(m_uvw2gse)
    store_data, prefix+'q_uvw2gse', times, q_uvw2gse
    
    
    two_colors = sgcolor(['blue','red'])
    if keyword_set(test) then begin
        for ii=0,ndim-1 do begin
            vec_gse = reform(m_uvw2gse[*,*,ii])
            for jj=0,ndim-1 do begin
                the_var = prefix+uvw[ii]+xyz[jj]+'_gse'
                vec_old = get_var_data(the_var)
                store_data, the_var, times, [[vec_old],[vec_gse[*,jj]]], $
                    limits={colors:two_colors, labels:['orig','fixed']}
            endfor
        endfor
    endif


    vars = prefix+['x'+xyz,'y'+xyz,'w'+xyz]+'_gse'
    smooth_window = 1800
    time_step = total(times[0:1]*[-1,1])
    two_colors = sgcolor(['blue','red'])
    smooth_width = smooth_window/time_step
    foreach var, vars do begin
        vec = get_var_data(var)
        vec_fix = smooth(vec,smooth_width,/nan,/edge_mirror)
        store_data, var+'_fix', times, vec_fix
        store_data, var, times, [[vec],[vec_fix]], limits={colors:two_colors, labels:['orig','fixed']}
    endforeach
    
    ; Ensure it's uniform.
    foreach component, ['x','y','w'] do begin
        vec = fltarr(ntime,ndim)
        for ii=0,ndim-1 do vec[*,ii] = get_var_data(prefix+component+xyz[ii]+'_gse_fix')
        vec = sunitvec(vec)
        vec_var = prefix+component+'_gse_fix'
        store_data, vec_var, times, vec
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(component), $
            'unit', '#', $
            'coord', 'DSC', $
            'coord_labels', xyz )
    endforeach
    stop

;---Change back to UVW.
    x_gse = get_var_data(prefix+'x_gse_fix')
    y_gse = get_var_data(prefix+'y_gse_fix')
    
    vec_var = prefix+'u_fix'
    for ii=0,ndim-1 do vec[*,ii] = x_gse[*,ii]*cost+y_gse[*,ii]*sint
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'U', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )
        
    vec_var = prefix+'v_fix'
    for ii=0,ndim-1 do vec[*,ii] =-x_gse[*,ii]*sint+y_gse[*,ii]*cost
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'V', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )
    
    vec_var = prefix+'w_fix'
    vec = get_var_data(prefix+'w_gse_fix')
    store_data, vec_var, times, vec
    add_setting, vec_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'W', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )


end

;+
; Check the rotation angle from UVW to MGSE.
; 
; There is no direct rotation matrix in SPICE from UVW to MGSE.
; The way to go is UVW2GSM then GSM2MGSE.
; W and x_mgse align with very good accuracy.
;-

;---Input.
    date = time_double('2013-06-19')
    probe = 'b'

;---Other settings.
    secofday = constant('secofday')
    xyz = constant('xyz')
    full_time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    spin_period = 11d
    common_time_step = 1d/16
    smooth_width = spin_period/common_time_step

;---Find the perigee.
    rbsp_read_orbit, full_time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gsm', times=times))
    perigee_lshell = 1.15
    perigee_times = times[where(dis le perigee_lshell)]
    orbit_time_step = total(times[0:1]*[-1,1])
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    time_range = reform(perigee_time_ranges[1,*])
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)

;---Load SPICE.
    defsysv,'!rbsp_spice', exists=flag
    if flag eq 0 then rbsp_load_spice_kernel
    coord = 'gsm'
    cap_coord = strupcase(coord)

    ; Prepare epochs used for q_uvw2coord.
    scid = strupcase(prefix+'science')
    cspice_str2et, time_string(common_times[0], tformat='YYYY-MM-DDThh:mm:ss.ffffff'), epoch0
    epochs = epoch0+common_times-common_times[0]
    cspice_pxform, scid, cap_coord, epochs, muvw
    muvw = transpose(muvw)
    quvw = mtoq(muvw)
    
    uvw = constant('uvw')
    for ii=0,2 do begin
        component = uvw[ii]
        the_var = prefix+component+'_'+coord
        store_data, the_var, common_times, muvw[*,*,ii]
        add_setting, the_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', '#', $
            'short_name', strupcase(component), $
            'coord', strupcase(coord), $
            'coord_labels', xyz )
    endfor
    
;    ww = get_var_data(prefix+'w_'+coord)
;    ww_gse = cotran(ww, common_times, coord+'2gse')
;    pp = atan(double(ww_gse[*,1]),ww_gse[*,0])
;    cosp = cos(pp)
;    sint = ww_gse[*,0]/cosp
;    sinp = ww_gse[*,1]/sint
;    cost = double(ww_gse[*,2])
;    mgse = dblarr(ncommon_time,3,3)
;    mgse[*,0,0] = cosp*sint
;    mgse[*,0,1] = -sinp
;    mgse[*,0,2] = -cosp*cost
;    mgse[*,1,0] = sinp*cost
;    mgse[*,1,1] = cosp
;    mgse[*,1,2] = -sinp*cost
;    mgse[*,2,0] = cost
;    mgse[*,2,1] = 0
;    mgse[*,2,2] = sint
;    
;    muvw2mgse = dblarr(ncommon_time,3,3)
;    for ii=0,ncommon_time-1 do muvw2mgse[ii,*,*] = reform(mgse[ii,*,*]) # reform(muvw[ii,*,*])
;    quvw2mgse = mtoq(muvw2mgse)
    
    ; Load some data in UVW.
    data_time_range = time_range
    timespan, data_time_range[0], total(data_time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=data_time_range
;    rbsp_uvw2gsm, prefix+'e_uvw', prefix+'e_gsm', probe=probe
;    e_gsm = get_var_data(prefix+'e_gsm', times=times)
;    e_mgse = cotran(e_gsm, times, 'gsm2mgse', probe=probe)
;    store_data, prefix+'e_mgse', times, e_mgse
;    add_setting, prefix+'e_mgse', /smart, dictionary($
;        'display_type', 'vector', $
;        'unit', 'mV/m', $
;        'short_name', 'E', $
;        'coord', 'MGSE', $
;        'coord_labels', xyz )
;    e_uvw = get_var_data(prefix+'e_uvw')
;    
;
;    st = (e_mgse[*,1]*e_uvw[*,0]-e_mgse[*,0]*e_uvw[*,1])/(e_uvw[*,0]^2+e_uvw[*,1]^2)
    
    
    stop

end

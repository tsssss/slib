;+
; Try to remove spin tone and calculate the rotation matrix.
;-

function get_bg, data, smooth_width

    dims = size(data,/dimensions)
    if n_elements(dims) eq 1 then ndim = 1 else ndim = dims[1]

;    bg = data
;    min_val = 10.
;    for ii=0, ndim-1 do begin
;        yshift = min_val-min(model[*,ii])
;        coef = (data[*,ii]+yshift)/(model[*,ii]+yshift)
;        coef = smooth(coef, smooth_width, /edge_zero)
;        bg[*,ii] = (data[*,ii]+yshift)*coef-yshift
;    endfor

    bg = data
    for ii=0, ndim-1 do begin
        bg[*,ii] = smooth(data[*,ii], smooth_width, /nan)
    endfor

    return, bg

end


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
    time_range = reform(perigee_time_ranges[0,*])

;---Load data.
    data_time_range = time_range+spin_period*[-1,1]*1
    rbsp_read_quaternion, data_time_range, probe=probe
    rbsp_read_sc_vel, data_time_range, probe=probe
    rbsp_read_orbit, data_time_range, probe=probe
    common_times = make_bins(data_time_range, common_time_step)
    ncommon_time = n_elements(common_times)
    timespan, data_time_range[0], total(data_time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=data_time_range
    e_uvw = get_var_data(prefix+'efw_esvy', at=common_times)
    store_data, prefix+'e_uvw', common_times, e_uvw
    add_setting, prefix+'e_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    e_uvw = get_var_data(prefix+'e_uvw')
    ew = e_uvw[*,2]
    store_data, prefix+'ew', common_times, ew

    ; B field.
    rbsp_read_emfisis, data_time_range, probe=probe, id='l2%magnetometer'
    b_uvw = get_var_data(prefix+'b_uvw', at=common_times)
    store_data, prefix+'b_uvw', common_times, b_uvw
    add_setting, prefix+'b_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    b_uvw = get_var_data(prefix+'b_uvw')
;    ; From Solene paper.
;    rotation_angles = (probe eq 'a')? [0.05,0.02,-1.2]: [-0.035,0.08,0.8]
;    rotation_angles *= constant('rad')
;    rotation_angles = rotation_angles ## (dblarr(ncommon_time)+1)
;    b_uvw += vec_cross(b_uvw, rotation_angles)
;    store_data, prefix+'b_uvw', common_times, b_uvw

    bw = b_uvw[*,2]
    store_data, prefix+'bw', common_times, bw

    ; Separate bg and fg.
    ew_bg = get_bg(ew, smooth_width)
    store_data, prefix+'ew_bg', common_times, ew_bg, limits={$
        ytitle:'(mV/m)', labels:'Ew BG'}
    ew_fg = ew-ew_bg
    sdespike, ew_fg, width=0.1*smooth_width
    store_data, prefix+'ew_fg', common_times, ew_fg, limits={$
        ytitle:'(mV/m)', labels:'Ew spin tone'}

    bw_bg = get_bg(bw, smooth_width)
    store_data, prefix+'bw_bg', common_times, bw_bg, limits={$
        ytitle:'(nT)', labels:'Bw BG'}
    bw_fg = bw-bw_bg
    store_data, prefix+'bw_fg', common_times, bw_fg, limits={$
        ytitle:'(nT)', labels:'Bw spin tone'}


    store_data, prefix+'eb_angle', $
        common_times, smooth(sang(e_uvw,b_uvw,/deg), smooth_width, /nan), limits={$
        ytitle:'(deg)', labels:'E(3D)&B angle', constant:90}

    tplot_options, 'labflag', -1
    tplot_options, 'ynozero', 1

    plot_file = join_path([homedir(),prefix+'spin_tone_along_spin_axis_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_v01.pdf'])
    sgopen, plot_file, xsize=10, ysize=8
    vars = prefix+['ew_bg','ew_fg','bw_bg','bw_fg','eb_angle']
    nvar = n_elements(vars)
    margins = [10,4,12,3]
    poss = sgcalcpos(nvar, margins=margins, xchsz=xchsz, ychsz=ychsz)
    tplot, vars, trange=time_range, position=poss

    msg = 'RBSP-'+strupcase(probe)+' perigee when |R|<'+sgnum2str(perigee_lshell)+' Re'
    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty,/normal, msg

    fig_labels = letters(nvar)+'.'
    for ii=0,nvar-1 do begin
        tpos = poss[*,ii]
        tx = xchsz*2
        ty = tpos[3]-ychsz*0.8
        xyouts, tx,ty,/normal, fig_labels[ii]
    endfor

    times = mean(time_range)+findgen(3)*spin_period
    timebar, times, color=sgcolor('red')

    sgclose

    stop

end

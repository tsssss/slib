;+
; Load FEEPS pitch angle data. This is to replicate mms_load_pitch_angle in the framework of slib.
; In complete...
;-

function mms_read_feeps_pa_cdaweb, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, suffix=suffix

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = ''
    suffix = ''
    
    ; Collect active sensors.
    instr_str = 'feeps'
    mode_str = 'srvy'
    level_str = 'l2'
    species_str = 'electron'
    species_str2 = 'ele'
    nall_sensor = 12
    sensor_ids = findgen(nall_sensor)+1
    sensor_types = ['top','bottom']
    unit_type = 'intensity'
    prefix = 'mms'+probe+'_'
    prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'
    out_var = prefix2+'pa'+suffix
    if keyword_set(get_name) then return, out_var

    stop
    
    time_range = time_double(input_time_range)
    active_sensors = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)

    ; Load file.
    id = strjoin([level_str,mode_str,species_str],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval


    ; Load pitch angle.
    var_list = list()
    in_vars = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_pitch_angle'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', in_vars, $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000' )
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg


    stop
    ; from mms_ld_feeps_pad_ele, which is simplified from mms_load_pitch_angle.
    rad = constant('rad')
    deg = constant('deg')

    ; Get unit vectors for all sensors.
    top_sensor_r_fcs = transpose([$
        [ 0.347,-0.837, 0.423], $
        [ 0.347,-0.837,-0.423], $
        [ 0.837,-0.347, 0.423], $
        [ 0.837,-0.347,-0.423], $
        [-0.087, 0.000, 0.996], $
        [ 0.104, 0.180, 0.978], $
        [ 0.654,-0.377, 0.656], $
        [ 0.654,-0.377,-0.656], $
        [ 0.837, 0.347, 0.423], $
        [ 0.837, 0.347,-0.423], $
        [ 0.347, 0.837, 0.423], $
        [ 0.347, 0.837,-0.423] ])
    
    ; a rotation around y-axis by 180 deg.
    sint = 0d
    cost = -1d
    m_bottom_to_top = transpose([$
        [cost, 0, sint], $
        [0,1,0], $
        [-sint, 0, cost]])
    bottom_sensor_r_fcs = rotate_vector(top_sensor_r_fcs, m_bottom_to_top)
    
    flux_r_fcs = -[top_sensor_r_fcs[active_sensors['top']-1,*],bottom_sensor_r_fcs[active_sensors['bottom']-1,*]]
    r_coords = ct_mms_fcs2mms_bcs(flux_r_fcs)  ; in [nsensor,ndim]

    coord = 'gse'
    b_var = mms_read_bfield(time_range, probe=probe, coord=coord)
    r_var = mms_read_orbit(time_range, probe=probe, coord=coord)
    q_fac = lets_define_fac(b_var=b_var, r_var=r_var, time_var=flux_var, update=1)
    m_xxx2fac = qtom(get_var_data(q_fac))

    ndim = 3
    r_fac = fltarr(ntime,nsensor,ndim)
    tmp_r_var = prefix+'tmp_r_'+coord
    for sid=0,nsensor-1 do begin
        the_r_coord = (fltarr(ntime)+1) # reform(r_coords[sid,*])
        tmp = rotate_vector(the_r_coord, m_xxx2fac)
        index = where(finite(snorm(tmp)),count)
        if count ne ntime then tmp = sinterpol(tmp[index,*],times[index],times, interp_range=time_range)
        r_fac[*,sid,*] = tmp
    endfor

    ; fac: [b,w,o], maps to [z,x,y]
    fac_phis = atan(r_fac[*,*,2],r_fac[*,*,1])*deg  ; in [ntime,nsensor]
    fac_thetas = acos(r_fac[*,*,0])*deg     ; colat, in [0,180].
    index = where(fac_phis lt 0, count)
    if count ne 0 then fac_phis[index] += 360  


    return, rename_var(in_vars, output=out_var)

end


time_range = ['2015-09-01','2015-09-02']
probe = '4'
pa_var = mms_read_feeps_pa_cdaweb(time_range, probe=probe)
end
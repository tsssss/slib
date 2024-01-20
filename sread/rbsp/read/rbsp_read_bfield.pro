;+
; Read RBSP DC B field. Default is to read '4sec' data.
; Save as rbspx_b_gsm.
; 
; input_time_range.
; probe=. 'a', 'b'.
; id=. 'hires','1sec','4sec'.
; resolution=. 'hires', '1sec', '4sec'. To be deprecated.
; coord=. 'gsm','ges','gei','sm'
;-

function rbsp_read_bfield, input_time_range, probe=probe, id=id, update=update, $
    resolution=datatype0, errmsg=errmsg, coord=coord, get_name=get_name, suffix=suffix, $
    remove_spin_tone=spin_tone, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    ; Prepare var name.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(suffix) eq 0 then suffix = ''
    vec_coord_var = prefix+'b_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    
    if n_elements(datatype0) eq 0 then datatype0 = '4sec'
    datatype = strlowcase(datatype0)
    case datatype of
        'hires': time_step = 1d/64
        '1sec': time_step = 1d
        '4sec': time_step = 4d
    endcase

    ; Load files.
    files = rbsp_load_emfisis(time_range, probe=probe, $
        id='l3%magnetometer', $
        resolution=datatype, coord=default_coord, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    vec_default_var = prefix+'b_'+default_coord+suffix
    var_list.add, dictionary($
        'in_vars', ['Mag'], $
        'out_vars', [vec_default_var], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


;---Calibrate the data.
    ; Remove invalid values.
    get_data, vec_default_var, times, vec_default
    index = where(abs(vec_default) ge 65536, count)
    if count ne 0 then begin
        vec_default[index,*] = !values.f_nan
        store_data, vec_default_var, times, vec_default
    endif
    
    

    ; Fix time tags.
    uniform_time, vec_default_var, time_step
    dtime = time_step*0.5
    get_data, vec_default_var, times, vec_default
    store_data, vec_default_var, times+dtime, vec_default
    
    ; Remove spikes.
    spin_period = 11d
    width = spin_period/time_step*0.2
    ndim = 3
    vec_bg = vec_default
    for ii=0,ndim-1 do begin
        vec_bg[*,ii] = smooth(vec_default[*,ii], width, nan=1, edge_zero=1)
    endfor
    
    dbmag = snorm(vec_default)-snorm(vec_bg)
    index = where(abs(deriv(dbmag)) ge 10, count)
    if count ne 0 then begin
        vec_default[index,*] = !values.f_nan
        store_data, vec_default_var, times, vec_default
    endif
    
    ; Remove spin tone.
    if keyword_set(spin_tone) then begin
        width = spin_tone/time_step
        vec_bg = vec_default
        
        for ii=0,ndim-1 do begin
            vec_bg[*,ii] = smooth(vec_default[*,ii], width*0.1, nan=1, edge_zero=1)
        endfor
        
        vec_center = vec_bg
        for ii=0,ndim-1 do begin
            offset1 = smooth(vec_bg[*,ii], width, nan=1, edge_zero=1)
            offset2 = smooth(offset1, width, nan=1, edge_zero=1)
            vec_center[*,ii] = offset2
        endfor
        rot_axis = sunitvec(vec_cross(vec_bg, vec_center))
        rot_angle = sang(vec_bg, vec_center)
        cos_angle = cos(rot_angle)
        sin_angle = sin(rot_angle)
        ; from https://en.wikipedia.org/wiki/Rotation_matrix.
        ntime = n_elements(times)
        m_rot = dblarr(ntime,ndim,ndim)
        for ii=0,ndim-1 do m_rot[*,ii,ii] = rot_axis[*,ii]^2*(1-cos_angle)+cos_angle
        m_rot[*,1,0] = rot_axis[*,1]*rot_axis[*,0]*(1-cos_angle)+rot_axis[*,2]*sin_angle
        m_rot[*,0,1] = rot_axis[*,0]*rot_axis[*,1]*(1-cos_angle)-rot_axis[*,2]*sin_angle
        m_rot[*,2,0] = rot_axis[*,2]*rot_axis[*,0]*(1-cos_angle)-rot_axis[*,1]*sin_angle
        m_rot[*,0,2] = rot_axis[*,0]*rot_axis[*,2]*(1-cos_angle)+rot_axis[*,1]*sin_angle
        m_rot[*,2,1] = rot_axis[*,2]*rot_axis[*,2]*(1-cos_angle)+rot_axis[*,0]*sin_angle
        m_rot[*,1,2] = rot_axis[*,1]*rot_axis[*,2]*(1-cos_angle)-rot_axis[*,0]*sin_angle
        ;m_rot_inv = transpose(m_rot, [0,2,1])
        
;        lim = {colors:constant('rgb'), labels:constant('xyz')}
;        store_data, prefix+'bg', times, vec_bg, limits=lim
;        store_data, prefix+'center', times, vec_center, limits=lim
;        store_data, prefix+'wobble', times, vec_bg-vec_center, limits=lim
;        store_data, prefix+'test1', times, rotate_vector(vec_bg, m_rot)-vec_center, limits=lim
;        store_data, prefix+'test2', times, rotate_vector(vec_bg, m_rot_inv)-vec_center, limits=lim
;        
;        vec_test = rotate_vector(vec_bg, m_rot)
;        bmag_coef = snorm(vec_center)/snorm(vec_bg)
;        for ii=0,ndim-1 do vec_test[*,ii] *= bmag_coef
;        store_data, prefix+'test', times, vec_test-vec_center, limits=lim

        vec_default = rotate_vector(vec_default, m_rot)
        bmag_coef = snorm(vec_center)/snorm(vec_bg)
        for ii=0,ndim-1 do vec_default[*,ii] *= bmag_coef
        
        store_data, vec_default_var, times, vec_default
    endif
    

    ; Convert to the wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran(vec_default, times, default_coord+'2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, {$
        requested_time_range: time_range, $
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end

;time_range = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40'])   ; a shorter time range for test purpose.
time_range = time_double(['2013-06-07/04:40','2013-06-07/05:10'])         ; a longer time range for test purpose.
time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
;time_range = time_double(['2015-09-15','2015-09-16'])         ; a day with data gap.
time_range = ['2015-03-17','2015-03-18']
var = rbsp_read_bfield(time_range, probe='b', resolution='hires')
end
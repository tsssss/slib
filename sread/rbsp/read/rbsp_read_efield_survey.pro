;+
; Read RBSP EFW E field in mGSE in survey resolution (32 S/s).
; Load L2 E UVW and convert to mGSE.
; Do not use L2 E despun b/c cotran does a slightly more accurate job to convert UVW to mGSE.
;-

function rbsp_read_efield_survey, input_time_range, probe=probe, $
    get_name=get_name, update=update, suffix=suffix, $
    keep_e56=keep_e56, b0_var=b0_var, coord=coord, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'rbsp_mgse'
    if n_elements(suffix) eq 0 then suffix = '_survey'
    vec_default_var = prefix+'e_'+default_coord+suffix
    if n_elements(coord) eq 0 then coord = default_coord
    vec_coord_var = prefix+'e_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    

;    time_range = time_double(input_time_range)
;    files = rbsp_load_efw(time_range, probe=probe, $
;        id='l2%uvw', errmsg=errmsg)
;    if errmsg ne '' then return, retval
;
;    var_list = list()
;
;    orig_coord = 'uvw'
;    vec_orig_var = prefix+'e_'+orig_coord
;    var_list.add, dictionary($
;        'in_vars', ['e_hires_uvw'], $
;        'out_vars', [vec_orig_var], $
;        'time_var_name', 'epoch', $
;        'time_var_type', 'epoch16')
;    
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;    if errmsg ne '' then return, retval

    orig_coord = 'rbsp_uvw'
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
    vec_orig_var = rename_var(prefix+'e_uvw',output=prefix+'e_'+orig_coord)

    get_data, vec_orig_var, times, vec_uvw
    index = where(abs(vec_uvw) ge 1e30, count)
    if count ne 0 then begin
        vec_uvw[index] = !values.f_nan
        store_data, vec_orig_var, times, vec_uvw
    endif
    add_setting, vec_orig_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: orig_coord, $
        coord_labels: ['u','v','w'], $
        colors: constant('rgb') }
        
    vec_default = cotran_pro(vec_uvw, times, coord_msg=[orig_coord,default_coord], probe=probe, _extra=ex)
    ; remove background E field.
    rbsp_read_e_model, time_range, probe=probe
    emod_var = prefix+'emod_mgse'
    emod_mgse = get_var_data(emod_var, at=times)
    vec_default -= emod_mgse
    ; treat e56.
    e_spinaxis = vec_default[*,0]
    if ~keyword_set(keep_e56) then vec_default[*,0] = 0
    if n_elements(b0_var) then begin
        b_vec = get_var_data(b0_var, at=times, limits=lim)
        b_coord = lim.coord
        if b_coord ne defaul_coord then begin
            b_vec = cotran_pro(b_vec, times, b_coord+'2'+defaul_coord, probe=probe)
        endif
        vec_default[*,0] = total(vec_default[*,1:2]*b_vec[*,1:2],2)/b_vec[*,0]
    endif
    store_data, vec_default_var, times, vec_default
    add_setting, vec_coord_var, smart=1, id='efield', dictionary($
        'requested_time_range', time_range, $
        'coord', default_coord, $
        'e_spin_axis', e_spinaxis )

    ; convert to wanted coord.
    if coord ne default_coord then begin
        e_coord = cotran_pro(vec_default, times, coord_msg=[default_coord,coord], probe=probe)
        store_data, vec_coord_var, times, e_coord
        add_setting, vec_coord_var, id='efield', dictionary('coord', coord)
    endif

    return, vec_coord_var

end

time_range = time_double(['2015-03-07/06:00','2015-03-07/06:46'])
time_range = time_double(['2015-03-07/05:30','2015-03-07/07:30'])
probe = 'a'

prefix = 'rbsp'+probe+'_'

;---Load E field.
    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    rbsp_efw_read_boom_flag, time_range, probe=probe
    ; V2 and V4 are good.
    get_data, prefix+'efw_vsvy', times, vsvy
    vsc = get_var_data(prefix+'vsc_median', at=times)
    ; Remove spin tone.
    spin_period = 11d   ; the rough number works fine, no need to get the accurate number
    dt = median(times[1:-1]-times[0:-2])
    width = spin_period/dt
    vsc = smooth(vsc, width, nan=1, edge_zero=1)
    
    e12 = 2*(vsc-vsvy[*,1])*10
    ;e12 = (vsvy[*,0]-vsvy[*,1])*10
    e34 = 2*(vsc-vsvy[*,3])*10
    ntime = n_elements(times)
    ndim = 3
    vec_default = fltarr(ntime,ndim)
    vec_default[*,0] = e12
    vec_default[*,1] = e34
    
    ; Remove DC offset, from /Users/shengtian/My Drive/codes/idl/spacephys/topics/rbsp_phasef/intermediate_data_production/rbsp_efw_phasef_read_e_uvw_gen_file.pro
    
    for ii=0,1 do begin
        offset1 = smooth(vec_default[*,ii], width, /nan, /edge_zero)
        offset2 = smooth(offset1, width, /nan, /edge_zero)
        vec_default[*,ii] -= offset2
    endfor
    store_data, prefix+'e_uvw_sheng', times, vec_default
    add_setting, prefix+'e_uvw_sheng', smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'unit', 'mV/m', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    
    default_coord = 'uvw'
    coord = 'mgse'
    msg = default_coord+'2'+coord
    vec_coord = cotran(vec_default, times, msg, probe=probe, _extra=ex)
    
    vec_coord_var = prefix+'e_'+coord
    store_data, vec_coord_var, times, vec_coord
    add_setting, vec_coord_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }
    
    e_mgse_var1 = vec_coord_var
    
    ; Try spinfit.
    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    e_mgse_var = prefix+'e_spinfit_mgse_v24'
    e_mgse_var = e_mgse_var1
    

;---Load B field.
    b_gsm_var = rbsp_read_bfield(time_range, probe=probe, coord='gsm', resolution='hires')
    r_gsm_var = rbsp_read_orbit(time_range, probe=probe, coord='gsm')
    vinfo = geopack_trace_to_ionosphere(r_gsm_var, models=external_model, $
        igrf=0, south=1, north=0, refine=refine, suffix='_'+internal_model)

    time_step = 1d/16
    common_times = make_bins(time_range,time_step,inner=1)
    
    foreach var, [b_gsm_var,r_gsm_var,e_mgse_var] do interp_time, var, common_times
    get_data, b_gsm_var, times, b_gsm
    external_model = 't89'
    internal_model = 'dipole'
    vinfo = geopack_read_bfield(r_gsm_var, models=external_model, igrf=0, suffix='_'+internal_model, t89_par=2, coord='gsm')
    r_gsm_var = prefix+'r_gsm'
    bmod_var = prefix+'bmod_gsm_'+external_model+'_'+internal_model
    bmod_gsm = get_var_data(bmod_var, at=times)
    b1_gsm = b_gsm-bmod_gsm
    width = 20d*60/time_step
    for ii=0,ndim-1 do begin
        b1_gsm[*,ii] -= smooth(b1_gsm[*,ii], width, edge_mirror=1, nan=1)
    endfor
    b0_gsm = b_gsm-b1_gsm
    
    b1_gsm_var = prefix+'b1_gsm'
    b0_gsm_var = prefix+'b0_gsm'
    store_data, b1_gsm_var, times, b1_gsm
    store_data, b0_gsm_var, times, b0_gsm
    add_setting, b0_gsm_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', strupcase(external_model)+' B', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz'), $
        'model', external_model, $
        'internal_model', internal_model )
    add_setting, b1_gsm_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'dB', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz'), $
        'model', external_model, $
        'internal_model', internal_model )
        
        
        
;---Edot0
    e_mgse = get_var_data(e_mgse_var)
    get_data, b0_gsm_var, times, b0_gsm
    b0_mgse = cotran(b0_gsm, times, 'gsm2mgse', probe=probe)
    edot0_mgse = e_mgse
    edot0_mgse[*,0] = -(e_mgse[*,1]*b0_mgse[*,1]+e_mgse[*,2]*b0_mgse[*,2])/b0_mgse[*,0]
    edot0_mgse_var = prefix+'edot0_mgse'
    store_data, edot0_mgse_var, times, edot0_mgse
    add_setting, edot0_mgse_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'Edot0', $
        'unit', 'mV/m', $
        'coord', 'mGSE', $
        'coord_labels', constant('xyz') )

;---FAC.
    fac_labels = ['||',tex2str('perp')+','+['west','out']]
    define_fac, b0_gsm_var, r_gsm_var, time_var=b0_gsm_var
    get_data, edot0_mgse_var, times, edot0_mgse
    edot0_gsm = cotran(edot0_mgse, times, 'mgse2gsm', probe=probe)
    edot0_gsm_var = prefix+'edot0_gsm'
    store_data, edot0_gsm_var, times, edot0_gsm
    add_setting, edot0_gsm_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'unit', 'mV/m', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz') )
    fac_vars = prefix+['b1_fac','edot0_fac']
    foreach var, [b1_gsm_var,edot0_gsm_var], var_id do begin
        to_fac, var, to=fac_vars[var_id]
        add_setting, fac_vars[var_id], smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', get_setting(var,'short_name'), $
            'unit', get_setting(var,'unit'), $
            'coord', 'FAC', $
            'coord_labels', fac_labels)
    endforeach
    

;---Pflux.
    e1_fac_var = prefix+'edot0_fac'
    b1_fac_var = prefix+'b1_fac'
    pf_fac_var = prefix+'pfdot0_fac'
    filter = [0.25d,1800]    ; sec.
    scale_info = {s0:min(filter), s1:max(filter), dj:1d/8, ns:0d}
    stplot_calc_pflux_mor, e1_fac_var, b1_fac_var, pf_fac_var, scaleinfo=scale_info
    
;    ; Try do it directly.
;    cpoynt = 1d/(400d*!dpi) ; from mV/m x nT -> mW/m^2.
;    get_data, e1_fac_var, times, e1_fac
;    get_data, b1_fac_var, times, b1_fac
;    pf_fac = vec_cross(e1_fac,b1_fac)*cpoynt
;    store_data, pf_fac_var, times, pf_fac
    
    ; Map.
    get_data, pf_fac_var, times, pf_fac, limits=lim
    bf_var = prefix+'bf_gsm_'+external_model+'_'+internal_model
    bf_gsm = get_var_data(bf_var, at=times)
    b0_gsm = get_var_data(b0_gsm_var)
    cmap = snorm(bf_gsm)/snorm(b0_gsm)
    for ii=0,ndim-1 do pf_fac[*,ii] *= cmap
    pf_fac_map_var = prefix+'pfdot0_fac_map'
    store_data, pf_fac_map_var, times, pf_fac, limits=lim
stop







time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
probe = 'b'
var = rbsp_read_efield_survey(time_range, probe=probe)
end
;+
; Read E field.
;-

function themis_read_efield_survey, input_time_range, probe=probe, $
    get_name=get_name, coord=coord, keep_e56=keep_e56, _extra=ex

    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    coord = 'themis_dsl'
    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then return, vec_coord_var

    ; Get E in SPG then convert to DSL.
    default_coord = 'themis_spg'
    vec_default_var = prefix+'e_'+default_coord
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    
    files = themis_load_efi(time_range, probe=probe, errmsg=errmsg, id='l1%eff')
    if errmsg ne '' then return, retval
    
    var_list = list()
    in_var = prefix+'eff'
    var_list.add, dictionary($
        'in_vars', in_var, $
        'out_vars', in_var, $
        'time_var_name', in_var+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    ; Convert to physical unit.
    get_data, in_var, times, e_spg
    e_spg = float(e_spg)
    thm_init
    thm_get_efi_cal_pars, times, 'eff', probe, cal_pars=cp
    boom_lengths = cp.boom_length*cp.boom_shorting_factor
    gain = -1e3*cp.edc_gain
    time_step = sdatarate(times)
    spin_period = 3d
    width = spin_period/time_step
    for ii=0,1 do begin
        e_comp = e_spg[*,ii]*gain[ii]/boom_lengths[ii]
        e_spg[*,ii] = e_comp-efield_calc_dc_offset(e_comp, width)
    endfor
    if ~keyword_set(keep_e56) then e_spg[*,2] = 0
    store_data, vec_default_var, times, e_spg
    add_setting, vec_default_var, smart=1, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', strupcase(default_coord), $
        'coord_labels', constant('xyz') )

    msg = default_coord+'2'+coord
    e_coord = cotran_pro(e_spg, times, msg, probe=probe)
    store_data, vec_coord_var, times, e_coord
    add_setting, vec_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    
;    e_gse = cotran_pro(e_dsl, times, 'themis_dsl2gse', probe=probe)
;    store_data, prefix+'e_gse', times, e_gse
;    add_setting, prefix+'e_gse', smart=1, dictionary($
;        'display_type', 'vector', $
;        'unit', 'mV/m', $
;        'short_name', 'E', $
;        'coord', 'GSE', $
;        'coord_labels', constant('xyz') )
;    
;
;    thm_load_efi, probe=probe, trange=time_range, datatype='eff', level='l1', onthefly_edc_offset=1, coord='dsl'
;    var = prefix+'eff'
;    get_data, var, times2, eff
;    eff[*,2] = 0
;    store_data, var, times2, eff
;    add_setting, var, smart=1, dictionary($
;        'display_type', 'vector', $
;        'unit', 'mV/m', $
;        'short_name', 'E', $
;        'coord', 'DSL', $
;        'coord_labels', constant('xyz') )
;     
;    tplot, prefix+['eff','e_dsl','e_gse']
    

    return, vec_coord_var

end

time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probe = 'd'

prefix = 'th'+probe+'_'
evar = themis_read_efield_survey(time_range, probe=probe)
bvar = themis_read_bfield(time_range, probe=probe, id='fgl', coord='gsm')

e_dsl = get_var_data(evar, times=times, limits=lim)
edot0_dsl = e_dsl
b_gsm = get_var_data(bvar, at=times, limits=blim)
b0_gsm = b_gsm
time_step = sdatarate(times)
for ii=0,2 do b0_gsm[*,ii] = smooth(b_gsm[*,ii], 60/time_step, nan=1, edge_zero=1)
b0var = prefix+'b0_gsm'
store_data, b0var, times, b0_gsm, limits=blim
for ii=0,2 do b0_gsm[*,ii] = smooth(b_gsm[*,ii], 60/time_step, nan=1, edge_zero=1)
b1var = prefix+'b1_gsm'
store_data, b1var, times, b_gsm-b0_gsm, limits=blim

b0_dsl = cotran_pro(b0_gsm, times, 'gsm2themis_dsl', probe=probe)
edot0_dsl[*,2] = -(e_dsl[*,0]*b0_dsl[*,0]+e_dsl[*,1]*b0_dsl[*,1])/b0_dsl[*,2]
store_data, prefix+'edot0_themis_dsl', times, edot0_dsl, limits=lim
angle = asin(b0_dsl[*,2]/snorm(b0_dsl))*constant('deg')
store_data, prefix+'edot0_b_angle', times, angle, limits={constant:[10,15,20]}

edot0_gsm = cotran_pro(edot0_dsl, times, 'themis_dsl2gse', probe=probe)
store_data, prefix+'edot0_gsm', times, edot0_gsm
add_setting, prefix+'edot0_gsm', smart=1, dictionary($
    'display_type', 'vector', $
    'unit', 'mV/m', $
    'short_name', 'E', $
    'coord', strupcase('GSM'), $
    'coord_labels', constant('xyz') )

rvar = themis_read_orbit(time_range, probe=probe, coord='gsm')
define_fac, rvar, b0var, time_var=rvar

uvar = themis_read_ion_vel(time_range, probe=probe)


vars = prefix+['edot0','b1','u']
foreach var, vars do begin
    to_fac, var+'_gsm', to=var+'_fac'
endforeach

stplot_calc_pflux_mor, prefix+'edot0_fac', prefix+'b1_fac', prefix+'pfdot0_fac'
add_setting, prefix+'pfdot0_fac', smart=1, dictionary($
    'display_type', 'vector', $
    'unit', 'mW/m!U2!N', $
    'short_name', 'S', $
    'coord', 'FAC', $
    'coord_labels', ['b','w','o'] )

sgopen, 0, size=[8,6]
tplot, prefix+['edot0_fac','b1_fac','pfdot0_fac','u_fac','b_gsm','edot0_b_angle']
end
;+
; Read Arase E field. Save as 'arase_edot0_gsm'.
; 
; coord=.
; no_edotb=.
; resolution=.
;-

function arase_read_efield, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, $
    no_edotb=no_edotb, $
    resolution=resolution, _extra=ex

    prefix = 'arase_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'edot0_'+coord
    if keyword_set(no_edotb) then var = prefix+'e_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = arase_load_pwe(time_range, errmsg=errmsg, id='efd%l2%E_spin')
    if errmsg ne '' then return, retval


    var_list = list()
    coord_orig = 'dsi'
    orig_vars = prefix+'e'+['u','v']+'_'+coord_orig
    var_list.add, dictionary($
        'in_vars', ['Eu','Ev']+'_'+coord_orig, $
        'out_vars', [orig_vars], $
        'time_var_type', 'tt2000')


    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    get_data, orig_vars[0], times, eu
    get_data, orig_vars[0], times, ev
    euv = (eu+ev)*0.5
    ntime = n_elements(times)
    ndim = 3
    e_dsi = fltarr(ntime,ndim)
    e_dsi[*,0:1] = (eu+ev)*0.5
    e_dsi[*,2] = 0
    e_orig_var = prefix+'edot0_'+coord_orig
    store_data, e_orig_var, times, e_dsi
    
    if keyword_set(no_edotb) then begin
        e_orig_var = rename_var(prefix+'edot0_'+coord_orig, output=prefix+'e_'+coord_orig)
    endif else begin
        ; Calculate EdotB.
        get_data, e_orig_var, times, e_dsi
        b_orig_var = arase_read_bfield(time_range, resolution='8sec', coord=coord_orig)
        b_dsi = get_var_data(b_orig_var, at=times)
        e_dsi[*,2] = -(e_dsi[*,0]*b_dsi[*,0]+e_dsi[*,1]*b_dsi[*,1])/b_dsi[*,2]
        store_data, e_orig_var, times, e_dsi
    endelse
    
    if coord ne coord_orig then begin
        j2000_var = 'arase_e_j2000'
        erg_cotrans, e_orig_var, j2000_var, in_coord=coord_orig, out_coord='j2000'
        spd_cotrans, j2000_var, var, in_coord='j2000', out_coord=coord
    endif
    
    short_name = 'Edot0'
    if keyword_set(no_edotb) then short_name = 'E'
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', short_name, $
        'unit', 'mV/m', $
        'coord', strupcase(coord[0]), $
        'coord_labels', constant('xyz') )
        
    
    return, var


end

; To replicate Imajo+2022 GRL on potential drop.

time_range = ['2017-05-20','2017-05-21']
;e_var = arase_read_efield(time_range, no_edotb=1, coord='dsi')
e_var = arase_read_efield(time_range, coord='gsm')
b_var = arase_read_bfield(time_range, coord='gsm')
r_var = arase_read_orbit(time_range, coord='gsm')
bmod_var = geopack_info(

define_fac, b_var, r_var
foreach var, [e_var,b_var] do to_fac, var

var = 'arase_edot0_fac'
options, var, 'yrange', [-1,1]*15
get_data, var, times, vec
vec[*,1] *= -1
store_data, var, times, vec
add_setting, var, smart=1, dictionary($
    'display_type', 'vector', $
    'short_name', 'Edot0', $
    'unit', 'mV/m', $
    'coord', 'FAC', $
    'coord_labels', ['b','e','o'] )
tplot, 'arase_'+['edot0','b']+'_fac', trange=['2017-05-20/13:30','2017-05-20/13:50']
end
;+
; Read Polar B field that is exported from SDT.
;-

function polar_read_bfield_sdt, input_time_range, probe=probe, errmsg=errmsg, $
    coord=coord, get_name=get_name, update=update, suffix=suffix, _extra=ex

    prefix = 'po_'
    errmsg = ''
    retval = ''

    ; Prepare var name.
    default_coord = 'polar_spc'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(suffix) eq 0 then suffix = ''
    vec_coord_var = prefix+'b_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    ; Load files.
    files = polar_ld_ebv(time_range, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    vec_default_var = prefix+'b_'+default_coord+suffix
    var_list.add, dictionary($
        'in_vars', 'b_spc', $
        'out_vars', vec_default_var, $
        'time_var_name', 'ut_b', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    add_setting, vec_default_var, smart=1, {$
        mission_probe: 'polar', $
        requested_time_range: time_range, $
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(default_coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }
    
    
;---Clean up.
    get_data, vec_default_var, times, vec_default
    index = uniq(times, sort(times))
    times = times[index]
    vec_default = vec_default[index,*]
    store_data, vec_default_var, times, vec_default

;---Coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran_pro(vec_default, times, coord_msg=[default_coord,coord])
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, {$
        mission_probe: 'polar', $
        requested_time_range: time_range, $
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end

prefix = 'po_'

time_range = ['1998-09-25','1998-09-26']
b0_var = polar_read_bfield_sdt(time_range)
b_var = polar_read_bfield_sdt(time_range, coord='gsm')
bmod_var = polar_read_bmod_sdt(time_range, coord='gsm')
bmod0_var = polar_read_bmod_sdt(time_range)

;polar_read_orbit, time_range
;r_var = prefix+'r_gsm'
;options, r_var, requested_time_range=time_range, mission_probe='polar'
;bmod_var = lets_read_geopack_bfield(orbit_var=r_var, internal_model='igrf', external_model='t96', coord='gsm')
;tplot, [b_var,bmod_var], trange=time_range

b_gsm = get_var_data(b_var, times=times, limits=lim)
bmod_gsm = get_var_data(bmod_var, at=times)
db_gsm = b_gsm-bmod_gsm
db_var = prefix+'db_gsm'
store_data, db_var, times, db_gsm, limits=lim

db_mag_var = prefix+'db_mag'
db_mag = snorm(b_gsm)-snorm(bmod_gsm)
store_data, db_mag_var, times, db_mag

end
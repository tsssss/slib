;+
; Read Polar E field that is exported from SDT.
;-

function polar_read_efield_sdt, input_time_range, probe=probe, errmsg=errmsg, $
    coord=coord, get_name=get_name, update=update, suffix=suffix, _extra=ex

    prefix = 'po_'
    errmsg = ''
    retval = ''


;---Preparation
    default_coord = 'polar_spc'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(suffix) eq 0 then suffix = ''
    vec_coord_var = prefix+'e_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    ; Load files.
    files = polar_ld_ebv(time_range, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    vec_default_var = prefix+'e_'+default_coord+suffix
    var_list.add, dictionary($
        'in_vars', 'e_spc', $
        'out_vars', vec_default_var, $
        'time_var_name', 'ut_e', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    
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
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end

prefix = 'po_'

time_range = ['1999-09-25','1999-09-26']
e0_var = polar_read_efield_sdt(time_range)
e_var = polar_read_efield_sdt(time_range, coord='gsm')


end
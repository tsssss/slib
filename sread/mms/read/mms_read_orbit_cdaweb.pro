;+
; Read MMS orbit. Save as 'mms_r_<coord>'. Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. '1','2','3','4'.
;-

function mms_read_orbit_cdaweb, input_time_range, probe=probe, $
    var_info=var_info, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, suffix=suffix, _extra=ex


    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''
    
    ; Prepare var name.
    supported_coords = ['gse','gse2000','sm','gsm','eci','geo','sun_de421_eci','moon_de421_eci']
    if n_elements(coord) eq 0 then coord = 'gsm'
    index = where_pro(supported_coords, '==', coord, count=count)
    if count eq 0 then begin
        default_coord = 'gsm'
    endif else begin
        default_coord = supported_coords[index]
    endelse
    
    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    if n_elements(var_info) eq 0 then vec_coord_var = prefix+'r_'+coord else vec_coord_var = var_info
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    vec_default_var = prefix+'r_'+default_coord

    time_range = time_double(input_time_range)
    files = mms_ld_mec(time_range, probe=probe, errmsg=errmsg, id='l2%survey')
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    file_coord = default_coord
    in_vars = prefix+'mec_r_'+file_coord
    out_vars = vec_default_var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    ; Convert to Re.
    get_data, vec_default_var, times, vec_default
    vec_default = vec_default[*,0:2]*(1d/constant('re'))
    ; Remove invalid data.
    index = where(snorm(vec_default) ge 1e4, count)
    if count ne 0 then vec_default[index,*] = !values.f_nan
    store_data, vec_default_var, times, vec_default[*,0:2]

    ; Convert to wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran_pro(vec_default, times, coord_msg=[default_coord,coord], probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, {$
        requested_time_range: time_range, $
        probe: probe, $
        mission: 'mms', $
        mission_probe: 'mms'+probe, $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strlowcase(coord), $
        coord_labels: constant('xyz')}

    return, vec_coord_var

end



time_range = ['2015-09-01','2015-09-02']
probe = '1'
prefix = 'mms'+probe+'_'

r_eci_var = mms_read_orbit_cdaweb(time_range, probe=probe, coord='eci')
r_gse_var = mms_read_orbit_cdaweb(time_range, probe=probe, coord='gse')
r_eci = get_var_data(r_eci_var, times=times)
r_gse = cotran_pro(r_eci, times, coord_msg=['mms_eci','gse'], probe=probe)
settings = get_var_setting(r_gse_var)
var2 = prefix+'r_gse_cotran'
var2 = var_store(var2, r_gse, times, settings=settings)
tplot, [r_gse_var,var2]

end
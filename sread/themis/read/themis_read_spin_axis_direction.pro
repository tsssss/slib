;+
; Read Themis spin axis direction.
;-

function themis_read_spin_axis_direction, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, coord=coord, _extra=ex

    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif

;---Var name.
    if n_elements(coord) eq 0 then coord = 'gsm'
    prefix = 'th'+probe+'_'
    vec_coord_var = prefix+'spin_axis_'+coord
    if keyword_set(get_name) then return, vec_coord_var

;---Prepare files.
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    files = themis_load_ssc(time_range, probe=probe, id='l1%state')

    
;---Read data.
    var_list = list()
    in_vars = prefix+'spin'+['ras','dec']
    out_vars = in_vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+'state_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Post-processing.
    ; Get spin axis direction in GEI.
    default_coord = 'gei'
    ras = get_var_data(prefix+'spinras', times=times)
    dec = get_var_data(prefix+'spindec')
    rad = constant('rad')
    ; these names are from dsl2gse in spedas, what do they mean??
    spla = (90-dec)*rad
    splo = ras*rad
    ntime = n_elements(times)
    ndim = 3
    sa_gei = fltarr(ntime,ndim)
    sa_gei[*,0] = sin(spla)*cos(splo)
    sa_gei[*,1] = sin(spla)*cos(splo)
    sa_gei[*,2] = cos(spla)

    ; Convert to wanted coord
    if coord ne default_coord then begin
        vec_coord = cotran_pro(sa_gei, times, 'gei2'+coord, probe=probe, _extra=ex)
    endif else vec_coord = sa_gei
    store_data, vec_coord_var, times, vec_coord

    add_setting, vec_coord_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'W', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz'), $
        'unit', '#' )
    return, vec_coord_var

end
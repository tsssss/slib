;+
; Read MMS DC B field.
; Save data as 'mmsx_b_coord'.
;-

function mms_read_bfield, input_time_range, id=datatype, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, _extra=ex

    errmsg = ''
    retval = ''

    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'


    ; Prepare var name.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    vec_coord_var = prefix+'b_'+coord
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    vec_default_var = prefix+'b_'+default_coord

    ; Load files.
    files = mms_load_fgm(time_range, probe=probe, id='l2%survey', errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = [prefix+'fgm_b_'+default_coord+'_srvy_l2']
    out_vars = [vec_default_var]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    add_setting, out_vars[0], id='bfield', dictionary($
        'requested_time_range', time_range, $
        'coord', default_coord )

;---Calibrate the data.
    ; Convert to wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_gsm, limits=lim
        vec_coord = cotran_pro(vec_gsm, times, 'gsm2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, id='bfield', dictionary($
        'requested_time_range', time_range, $
        'coord', coord )


    return, vec_coord_var

end

time_range = ['2015-03-17','2015-03-19']
probe = '1'
b_var = mms_read_bfield(time_range, probe=probe)
end
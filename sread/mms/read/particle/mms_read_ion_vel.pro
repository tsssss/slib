
function mms_read_ion_vel, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, suffix=suffix, _extra=ex


    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    ; Prepare var name.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(suffix) eq 0 then suffix = ''
    vec_coord_var = prefix+'u_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    files = mms_ld_fpi(time_range, probe=probe, errmsg=errmsg, id='l2%fast%dis-moms')
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    orig_coord = 'gse'
    prefix2 = prefix+'dis_'
    in_vars = prefix2+'bulkv_'+orig_coord+'_fast'
    vec_orig_var = prefix+'u_'+orig_coord
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', vec_orig_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''


    if coord ne orig_coord then begin
        vec = get_var_data(vec_orig_var, times=times)
        vec = cotran_pro(vec, times, coord_msg=[orig_coord,coord], probe=probe)
        store_data, vec_coord_var, times, vec
    endif

    add_setting, vec_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'U!S!Uion!N!R', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )

    return, vec_coord_var
    
stop

end

tr = ['2015-09-01/18:00','2015-09-02']
probe = '1'
var = mms_read_ion_vel(tr, probe=probe)
end
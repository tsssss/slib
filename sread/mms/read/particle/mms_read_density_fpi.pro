;+
; Read density.
; input_time_range,
; probe=.
; id=. 'fpi'. Default is 'fpi'
;-

function mms_read_density_fpi, input_time_range, probe=probe, id=id, errmsg=errmsg, $
    species=species, $
    suffix=suffix, get_name=get_name, update=update

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species) eq 0 then species = 'e'
    index = where(species eq mms_get_fpi_species(), count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    if n_elements(suffix) eq 0 then suffix = '_fpi'
    var_info = prefix+species+'_density'+suffix
    if keyword_set(get_name) then return, var_info

    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info
    type_str = (species eq 'e')? 'des':'dis'
    mode_str = 'fast'
    id = 'l2%'+mode_str+'%'+type_str+'-moms'
    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_vars = prefix+type_str+'_numberdensity_'+mode_str
    time_var = 'Epoch'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', var_info, $
        'time_var_name', time_var, $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    get_data, var_info, times, data
    index = where(abs(data) ge 1e30, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
        store_data, var_info, times, data
    endif
    
    add_setting, var_info, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', species+' N' )

    return, var_info

end

tr = ['2015-09-01','2015-09-02']
probe = '4'
prefix = 'mms'+probe+'_'
var1 = mms_read_density_fpi(tr, probe=probe, species='e')
var2 = mms_read_density_fpi(tr, probe=probe, species='p')
var = stplot_merge([var1,var2], output=prefix+'density_fpi')
end
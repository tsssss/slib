;+
; Read density from sc potential.
;
; The factors is adopted from thm_scpot_density.
;-

function themis_read_density_efi, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=datatype, suffix=suffix

    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Prepare var name.
    if n_elements(suffix) eq 0 then suffix = '_efi'
    var = prefix+'density'+suffix
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    timespan, time_range[0], total(time_range*[-1,1]), seconds=1
    thm_scpot_density, probe=probe      ; TODO
    get_data, prefix+'pxxm_density', times, data
    store_data, var, times, data
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', 'EFI N' )
    return, var

end


time_range = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
time_range = time_double(['2015-03-17','2015-03-18'])
probe = 'd'
var1 = themis_read_density_efi(time_range, probe=probe)
var2 = themis_read_density_esa(time_range, probe=probe)
vars = [var1,var2]
tplot, vars
end
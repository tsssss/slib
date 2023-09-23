;+
; Read density from sc potential.
;
; The factors is adopted from thm_scpot_density.
;-

function themis_read_density_efi, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=datatype

    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Prepare var name.
    var = prefix+'density_efi'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    timespan, time_range[0], total(time_range*[-1,1]), seconds=1
    thm_scpot_density, probe=probe      ; TODO
    get_data, prefix+'pxxm_density', times, data
    store_data, var, times, data
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', 'EFI N' )
    return, var

end


time_range = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
var1 = themis_read_density_efi(time_range, probe=probe)
var2 = themis_read_density_esa(time_range, probe=probe)
vars = [var1,var2]
tplot, vars
end
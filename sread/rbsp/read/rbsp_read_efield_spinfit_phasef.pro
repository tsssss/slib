;+
; Read spinfit E field.
;-

function rbsp_read_efield_spinfit_phasef, input_time_range, probe=probe, get_name=get_name, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'mgse'
    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then return, vec_coord_var
    
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    
    ; Auto choose the best pair (shifting pair may cause discontinuity but it's ok for survey plots).
    pairs = ['12','34','13','14','23','24']
    npair = n_elements(pairs)
    all_vars = prefix+'e_spinfit_mgse_v'+pairs
    times = get_var_time(all_vars[0])
    ntime = n_elements(times)

    rbsp_efw_read_boom_flag, time_range, probe=probe
    flag_var = prefix+'boom_flag'
    boom_flags = get_var_data(flag_var, at=times) eq 1
    total_flags = total(boom_flags,2)

    ; use v12 by default.
    the_var = prefix+'e_spinfit_mgse_v12'
    e_combo = get_var_data(the_var)
    e_setting = dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'mGSE', $
        'requested_time_range', time_range )


    ; no boom is good.
    index_bad = where(total_flags lt 2, count_bad, complement=index_good)
    if count_bad ne 0 then begin
        e_combo[index_bad,*] = !values.f_nan
    endif
    ; At least 2 booms work.
    nboom = 4
    if count_bad ne ntime then begin
        wanted_pair = fltarr(ntime,2)
        accum_flags = boom_flags
        for boom_id=1,nboom-1 do accum_flags[*,boom_id] += accum_flags[*,boom_id-1]
        for time_id=0,ntime-1 do begin
            wanted_pair[time_id,0] = (where(accum_flags[time_id,*] eq 1))[0]
            wanted_pair[time_id,1] = (where(accum_flags[time_id,*] eq 2))[0]
        endfor
        wanted_pair += 1    ; converte from 0-indexed to 1-indexed
        wanted_pair = string(wanted_pair[*,0],format='(I0)')+string(wanted_pair[*,1],format='(I0)')

        foreach pair, pairs do begin
            time_index = where(pair eq wanted_pair, count)
            if count eq 0 then continue
            the_var = prefix+'e_spinfit_mgse_v'+pair
            e_combo[time_index,*] = (get_var_data(the_var))[time_index,*]
        endforeach
    endif

    store_data, vec_coord_var, times, e_combo
    add_setting, vec_coord_var, smart=1, e_setting
    return, vec_coord_var

end

time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
probe = 'b'
;time_range = time_double(['2015-02-23','2015-02-24'])         ; a longer time range for test purpose.
;probe = 'a'
var = rbsp_read_efield_spinfit_phasef(time_range, probe=probe)
end
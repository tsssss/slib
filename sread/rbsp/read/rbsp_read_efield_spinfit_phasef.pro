;+
; Read spinfit E field.
; 
; input_time_range
; probe=.
; id=. wanted pair. Otherwise determine the best pair as a function of time automatically.
; get_name=.
; update=.
; keep_e56=.
; edot0_e56=.
; coord=.
; suffix=.
;-

function rbsp_read_efield_spinfit_phasef, input_time_range, probe=probe, $
    id=wanted_pair, get_name=get_name, update=update, suffix=suffix, $
    keep_e56=keep_e56, edot0_e56=edot0_e56, coord=coord, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'mgse'
    if n_elements(coord) eq 0 then coord = default_coord 
    if keyword_set(edot0_e56) then vec_coord_var = prefix+'edot0_'+coord
    if n_elements(suffix) eq 0 then suffix = '_spinfit_phasef'
    vec_coord_var = prefix+'e_'+coord+suffix
    if keyword_set(edot0_e56) then vec_coord_var = prefix+'edot0_'+coord+suffix
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    ; Get E in mGSE.
    vec_default_var = prefix+'e_'+default_coord+suffix
    if keyword_set(edot0_e56) then vec_default_var = prefix+'edot0_'+default_coord

    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    ; Get vec_default, times, and e_setting.
    if n_elements(wanted_pair) ne 0 then begin
        the_var = prefix+'e_spinfit_mgse_v'+wanted_pair
        vec_default = get_var_data(the_var, times=times)
        e_setting = dictionary($
            'display_type', 'vector', $
            'unit', 'mV/m', $
            'short_name', 'E', $
            'coord', default_coord, $
            'requested_time_range', time_range )
    endif else begin
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
        vec_default = get_var_data(the_var)
        e_setting = dictionary($
            'display_type', 'vector', $
            'unit', 'mV/m', $
            'short_name', 'E', $
            'coord', 'mgse', $
            'requested_time_range', time_range )


        ; no boom is good.
        index_bad = where(total_flags lt 2, count_bad, complement=index_good)
        if count_bad ne 0 then begin
            vec_default[index_bad,*] = !values.f_nan
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
            wanted_pair += 1    ; convert from 0-indexed to 1-indexed
            wanted_pair = string(wanted_pair[*,0],format='(I0)')+string(wanted_pair[*,1],format='(I0)')
            foreach pair, pairs do begin
                time_index = where(pair eq wanted_pair, count)
                if count eq 0 then continue
                the_var = prefix+'e_spinfit_mgse_v'+pair
                vec_default[time_index,*] = (get_var_data(the_var))[time_index,*]
            endforeach
        endif
    endelse

    ; treat e56.
    e_spinaxis = vec_default[*,2]
    if ~keyword_set(keep_e56) then vec_default[*,0] = 0
    if keyword_set(edot0_e56) then begin
        b_var = rbsp_read_bfield(time_range, probe=probe, coord=default_coord, errmsg=errmsg)
        if errmsg ne '' then return, retval
        interp_time, b_var, times
        b_vec = get_var_data(b_var)
        vec_default[*,2] = total(vec_default[*,0:1]*b_vec[*,0:1],2)/b_vec[*,2]
    endif
    store_data, vec_default_var, times, vec_default
    add_setting, vec_default_var, smart=1, e_setting
    add_setting, vec_default_var, dictionary('e_spin_axis', e_spinaxis)

    ; convert to wanted coord.
    if coord ne default_coord then begin
        msg = default_coord+'2'+coord
        e_coord = cotran(vec_default, times, msg, probe=probe)
        store_data, vec_coord_var, times, e_coord
        add_setting, vec_coord_var, id='efield', dictionary('coord', coord)
    endif
    
    return, vec_coord_var

end

time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
time_range = time_double(['2015-04-16/07:00','2015-04-16/09:00'])
probe = 'a'
;time_range = time_double(['2015-02-23','2015-02-24'])         ; a longer time range for test purpose.
;probe = 'a'
var1 = rbsp_read_efield_spinfit_phasef(time_range, probe='a', coord='gsm', edot0_e56=1, id='24', update=1)
var2 = rbsp_read_efield_spinfit_phasef(time_range, probe='b', coord='gsm', edot0_e56=1, id='12', update=1)
end
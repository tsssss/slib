;+
; Load MMS pa spec for high energy particles.
; 
; id=['pad3d','cdaweb']
; species=['e','i']
; energy_range=.
;-

function mms_read_pa_spec_kev_ele, input_time_range, probe=probe, $
    energy_range=energy_range, $
    var_info=var_info, $
    errmsg=errmsg, get_name=get_name, update=update, suffix=suffix

    errmsg = ''
    retval = ''

    pad_var = mms_read_pad_ele_kev(input_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retrval
    
    prefix = 'mms'+probe+'_'
    if n_elements(var_info) eq 0 then var_info = prefix+'pa_spec_kev_ele'
    pa_var = pad_get_pa_spec(pad_var=pad_var, energy_range=energy_range, var_info=var_info)
    return, pa_var

end

function mms_read_pa_spec_kev_ion, input_time_range, probe=probe, $
    energy_range=energy_range, $
    var_info=var_info, $
    errmsg=errmsg, get_name=get_name, update=update, suffix=suffix

    errmsg = ''
    retval = ''

    pad_var = mms_read_pad_ion_kev(input_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retrval

    prefix = 'mms'+probe+'_'
    if n_elements(var_info) eq 0 then var_info = prefix+'pa_spec_kev_ion'
    pa_var = pad_get_pa_spec(pad_var=pad_var, energy_range=energy_range, var_info=var_info)
    return, pa_var

end

function mms_read_pa_spec_kev_cdaweb, input_time_range, probe=probe, $
    energy_range=energy_range, species=species, $
    errmsg=errmsg, get_name=get_name, suffix=suffix, update=update

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''
    
    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    out_var = prefix+'pa_spec_ele_kev'+suffix
    if keyword_set(get_name) then return, out_var
    if n_elements(energy_range) ne 2 then energy_range = [50d,500]
    my_energy_range = get_var_setting(out_var, 'energy_range', exist)
    if not exist then begin
        update = 1
    endif else begin
        if total(my_energy_range eq energy_range) ne 2 then update = 1
    endelse
    if keyword_set(update) then tmp = delete_var_from_memory(out_var)
    if ~check_if_update_memory(out_var, time_range) then return, out_var

    prefix = 'mms'+probe+'_'
    species_str = (species eq 'e') ? 'ele': 'ion'
    pad_var = mms_read_pad_feeps_cdaweb(input_time_range, probe=probe, $
        errmsg=errmsg, get_name=get_name, suffix=suffix, update=update)
    if errmsg ne '' then return, retval
    energy_range_ev = energy_range*1e3
    out_var = pad_get_pa_spec(pad_var=pad_var, energy_range=energy_range_ev, var_info=out_var, errmsg=errmsg)
    if errmsg ne '' then return, retval
    options, out_var, requested_time_range=time_range
    return, out_var

end


function mms_read_pa_spec_kev, input_time_range, probe=probe, $
    energy_range=energy_range, species=species, $
    id=id, $
    errmsg=errmsg, get_name=get_name, suffix=suffix, update=update

    if n_elements(id) eq 0 then id = 'pad3d'
    if id eq 'cdaweb' then return, $
        mms_read_pa_spec_kev_cdaweb(input_time_range, probe=probe, $
        energy_range=energy_range, species=species, errmsg=errmsg, get_name=get_name, suffix=suffix, update=update)

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = ''
    suffix = ''
    out_var = prefix+'pa_spec_ele_kev'+suffix
    if keyword_set(get_name) then return, out_var
    if n_elements(energy_range) ne 2 then energy_range = [50d,500]
    energy_range_ev = energy_range*1e3
    my_energy_range = get_var_setting(out_var, 'energy_range', exist)
    if not exist then begin
        update = 1
    endif else begin
        if total(my_energy_range eq energy_range) ne 2 then update = 1
    endelse
    if keyword_set(update) then tmp = delete_var_from_memory(out_var)
    if ~check_if_update_memory(out_var, time_range) then return, out_var

    if species eq 'e' then begin
        routine = 'mms_read_pa_spec_kev_ele'
    endif else begin
        routine = 'mms_read_pa_spec_kev_ion'
    endelse
    pa_var = call_function(routine, input_time_range, probe=probe, $
        energy_range=energy_range_ev, var_info=out_var, errmsg=errmsg, get_name=get_name, update=update)
    options, pa_var, extend_y_edges=1, $
        energy_range=energy_range, requested_time_range=time_range, $
    set_ytick, pa_var, yrange=[0,180], ytickv=[30,90,150], yminor=6
    return, pa_var
end


tr = ['2015-09-01','2015-09-02']
probe = '4'
energy_range = [60d,500]
pa_var = mms_read_pa_spec_kev(tr, probe=probe, energy_range=energy_range, species='e')
pa_var2 = mms_read_pa_spec_kev(tr, probe=probe, energy_range=energy_range, species='e', id='cdaweb')
end

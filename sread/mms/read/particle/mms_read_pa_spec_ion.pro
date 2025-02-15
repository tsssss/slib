;+
; Read ion pitch angle spectrogram.
; species=. ['p','o','he','alpha']
; id=. ['all','kev','thermal']
; instrument=. ['fpi','hpca'] for id='thermal'.
;-

function mms_read_pa_spec_ion, input_time_range, id=datatype, probe=probe, species=species, var_info=var_info, $
    energy_range=energy_range, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, instrument=instr_str, $
    get_name=get_name, suffix=suffix, update=update


    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'


    ; Prepare var name.
    if n_elements(species) eq 0 then species = 'p'


    if n_elements(datatype) eq 0 then datatype = 'thermal'
    if n_elements(suffix) eq 0 then suffix = '_'+datatype
    if n_elements(var_info) eq 0 then var_info = prefix+species+'_pa_spec'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    routine = 'mms_read_pad_ion_'+datatype
    pad_var = call_function(routine,time_range, probe=probe, errmsg=errmsg, species=species, id=instr_str)
    if errmsg ne '' then return, retval
    var_info = pad_get_pa_spec(pad_var=pad_var, energy_range=energy_range, var_info=var_info)
    return, var_info

end


tr = ['2015-09-01/18:00','2015-09-02']
probe = '1'
ion_species = ['p','o','he','alpha']
ion_species = ['p','o']
plot_vars = list()
plot_vars.add, mms_read_en_spec_ele(tr, probe=probe, id='kev')
plot_vars.add, mms_read_en_spec_ele(tr, probe=probe, id='thermal')
plot_vars.add, mms_read_en_spec_ion(tr, probe=probe, id='kev')
plot_vars.add, mms_read_en_spec_ion(tr, probe=probe, species=species, id='thermal', suffix='_fpi', instrument='fpi')
foreach species, ion_species do begin
    plot_vars.add, mms_read_en_spec_ion(tr, probe=probe, species=species, id='thermal', suffix='_hpca', instrument='hpca')
endforeach
plot_vars.add, mms_read_ion_vel(tr, probe=probe)
plot_vars = plot_vars.toarray()
sgopen
tplot, plot_vars, trange=tr
end
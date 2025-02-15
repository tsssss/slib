;+
; Read electron pitch angle spectrogram.
;
; energy_range=.    ; in eV.
; species=. ['e']
; id=. ['all','kev','thermal']
;-

function mms_read_pa_spec_ele, input_time_range, id=datatype, probe=probe, species=species, var_info=var_info, $
    energy_range=energy_range, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, update=update


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
    if n_elements(species) eq 0 then species = 'e'
    species_map = dictionary($
        'e', 'e', $
        'p', 'p', $
        'o', 'o', $
        'he', 'he', $
        'alpha', 'alpha')
    species_str = species_map[species]

    if n_elements(var_info) eq 0 then var_info = prefix+species_str+'_pa_spec'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    if n_elements(datatype) eq 0 then datatype = 'all'
    routine = 'mms_read_pad_ele_'+datatype
    pad_var = call_function(routine,time_range, probe=probe)

    return, pad_get_pa_spec(pad_var=pad_var, energy_range=energy_range, var_info=var_info)

end

tr = ['2016-10-14/20:00','2016-10-14/22:30']
probe = '1'
prefix = 'mms'+probe+'_'
high_var = mms_read_pa_spec_ele(tr, probe=probe, energy_range=[32,100]*1e3, var_info=prefix+'pa_spec_high', id='kev')
mid_var = mms_read_pa_spec_ele(tr, probe=probe, energy_range=[2,32]*1e3, var_info=prefix+'pa_spec_mid', id='thermal')
low_var = mms_read_pa_spec_ele(tr, probe=probe, energy_range=[0.2,2]*1e3, var_info=prefix+'pa_spec_low', id='thermal')

plot_file = 0
sgopen, plot_file, size=[6,4]
plot_vars = [high_var,mid_var,low_var]
tplot, plot_vars, trange=tr

ele_var = mms_read_pad_ele_all(tr, probe=probe)
plot_time = time_double('2016-10-14/21:43:30')
tmp = plot_pad_polygon(ele_var, plot_times=plot_time, test=1, zrange=[1e5,5e7], color_table=49)


;plot_times = 
;2016-10-14/20:37:41
;2016-10-14/20:39:20
;2016-10-14/21:20:50
;2016-10-14/21:23:00
;2016-10-14/21:32:00
;2016-10-14/21:34:30
;2016-10-14/21:37:20
;2016-10-14/21:39:30
;2016-10-14/22:03:40
;2016-10-14/22:06:38
end
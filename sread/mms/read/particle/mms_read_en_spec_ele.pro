;+
; Read electron pitch angle spectrogram.
; species=. ['e']
; pitch_angle_range=. [0,180]
; id=. ['all','kev','thermal']
;-

function mms_read_en_spec_ele, input_time_range, id=datatype, probe=probe, species=species, var_info=var_info, $
    pitch_angle_range=pitch_angle_range, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, $
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
    if n_elements(species) eq 0 then species = 'e'
    species_map = dictionary($
        'e', 'e', $
        'p', 'p', $
        'o', 'o', $
        'he', 'he', $
        'alpha', 'alpha')
    species_str = species_map[species]


    if n_elements(datatype) eq 0 then datatype = 'all'
    if n_elements(suffix) eq 0 then suffix = '_'+datatype
    if n_elements(var_info) eq 0 then var_info = prefix+species_map[species]+'_en_spec'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    routine = 'mms_read_pad_ele_'+datatype
    pad_var = call_function(routine,time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    pad_fluxs = get_var_data(pad_var, times=times, settings=settings)

    pa_centers = settings.pa_centers
    en_centers = settings.en_centers

    if n_elements(pitch_angle_range) ne 2 then pitch_angle_range = [0d,180]
    pa_index = where_pro(pa_centers, '[]', pitch_angle_range, count=count)
    if count eq 0 then begin
        errmsg = 'Invalid pitch angle range ...'
        return, retval
    endif

    en_fluxs = total(pad_fluxs[*,pa_index,*],2)/count
    store_data, var_info, times, en_fluxs, en_centers
    unit = settings.unit
    energy_unit = settings.en_unit
    add_setting, var_info, smart=1, {$
        requested_time_range: time_range, $
        display_type: 'spec', $
        unit: unit, $
        species: species, $
        species_name: species_str, $
        ytitle: 'Energy!C('+energy_unit+')', $
        subytitle: species_str, $
        ylog: 1, $
        zlog: 1, $
        short_name: ''}

    return, var_info
end
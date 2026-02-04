;+
; Read FEEPS electron pitch angle spectrogram from CDAWeb.
;-

function mms_read_pa_spec_ele_kev_cdaweb, time_range, probe=probe, $
    energy_range=energy_range, $
    errmsg=errmsg, get_name=get_name, suffix=suffix

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


    ; Collect active sensors.
    instr_str = 'feeps'
    mode_str = 'srvy'
    level_str = 'l2'
    species_str = 'electron'
    species_str2 = 'ele'
    nall_sensor = 12
    sensor_ids = findgen(nall_sensor)+1
    sensor_types = ['top','bottom']
    unit_type = 'intensity'
    ;unit_type = 'count_rate'
    prefix = 'mms'+probe+'_'
    prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'
    active_sensors = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)

    ; Load pitch angle.
    id = strjoin([level_str,mode_str,species_str],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_vars = prefix2+'pitch_angle'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', in_vars, $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    
    flux_vars = mms_read_feeps_flux_cdaweb(time_range, probe=probe, species_str=species_str, $
        errmsg=errmsg, get_name=get_name, suffix=suffix, update=update)


    ; mms_feeps_pad loads mms_feeps_pitch_angle, does calculations, and then run mms_feeps_pad_spinavg.
    ;
    mms_feeps_pad, energy=energy_range, $
        probe=probe, datatype=species_str, data_rate=mode_str, $
        level=level_str, data_units=unit_type, suffix=suffix
        
    en_str = strcompress(string(fix(energy_range[0])), /rem) + '-' + strcompress(string(fix(energy_range[1])), /rem) + 'keV'
    ;new_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'+suffix_in
    cdaweb_var = strcompress(prefix2+unit_type+'_'+ en_str +'_pad', /rem)+'_spin'
    out_var = rename_var(cdaweb_var, output=out_var)
    add_setting, out_var, smart=1, dictionary($
        'display_type', 'spec', $
        'ytitle', 'Pitch!C(deg)', $
        'yrange', [0d,180], $
        'ytickv', [30d,90,150], $
        'yticks', 2, $
        'yminor', 6, $
        'energy_range', energy_range, $
        'requested_time_range', time_range )
    
    return, out_var
end



tr = ['2015-09-01','2015-09-02']
tr = ['2016-03-05','2016-03-06']
tr = ['2017-01-12','2017-01-13']
probe = '1'
energy_range = [60,300]
prefix = 'mms'+probe+'_'
var1 = mms_read_pa_spec_ele_kev_cdaweb(tr, probe=probe, suffix='_test', energy_range=energy_range)
pa_spec = get_var_data(var1, times=times, pas)
;var2 = mms_read_kev_electron(tr, probe=probe, energy_range=[40,600]*1e3, spec=1)
flux_90 = mean(pa_spec[*,5:6],dimension=2,nan=1)
flux_0 = mean(pa_spec[*,[[0,1],[10,11]]],dimension=2,nan=1)
aniso_var = prefix+'aniso'
store_data, aniso_var, times, [[flux_0],[flux_90]], limits={labels:['0','90'],colors:sgcolor(['red','blue']), ylog:1}
tplot, [aniso_var,var1]
end
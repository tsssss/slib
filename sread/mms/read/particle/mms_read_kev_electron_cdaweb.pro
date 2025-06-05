;+
; This is a quick and dirty function to read FEEPS electron flux in raw unit.
;-

function mms_read_kev_electron_cdaweb, time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, suffix=suffix

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = ''
    suffix = ''
    out_var = prefix+'feeps_e_flux'+suffix
    if keyword_set(get_name) then return, out_var


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

    tmp = mms_read_feeps_flux_cdaweb(time_range, probe=probe, $
        errmsg=errmsg, get_name=get_name, suffix=suffix)

    ; Calculate the energy spectrogram.
    mms_feeps_omni, probe, datatype=species_str, data_rate=mode_str, $
        level=level_str, sensor_eyes=active_sensors, data_units=unit_type, suffix=suffix
    
    mms_feeps_spin_avg, probe=probe, datatype=species_str, data_rate=mode_str, $
        level=level_str, data_units=unit_type, suffix=suffix
    
    old_var = prefix2+unit_type+'_omni_spin'+suffix
    options, old_var, no_interp=1, unit='#/cm!U2!N-sr-s-keV'
    return, rename_var(old_var, output=out_var)


end


tr = ['2015-09-01','2015-09-02']
probe = '4'
tr = ['2015-08-18','2015-08-19']
var1 = mms_read_kev_electron_cdaweb(tr, probe=probe, suffix='_test')
;var2 = mms_read_kev_electron(tr, probe=probe, energy_range=[40,600]*1e3, spec=1)
end

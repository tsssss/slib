;+
; Read the energy-time spectrogram.
; time_range.
; probe=.
;-

function dmsp_read_en_spec_madrigal, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, suffix=suffix

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_madrigal'
    if n_elements(species) eq 0 then species = 'e'
    all_species = dmsp_ssj_species()
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    spec_var = prefix+species+'_en_spec'+suffix
    if keyword_set(get_name) then return, spec_var

    time_range = time_double(input_time_range)
    if ~check_if_update(spec_var, time_range) then return, spec_var

    files = dmsp_load_ssj_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    the_var = (species eq 'e')? 'el_d_ener': 'ion_d_ener'   ; energy flux.
    in_var = '/Data/Array Layout/2D Parameters/'+the_var
    fluxs = hdf_read_var(in_var, filename=files)
    en_var = '/Data/Array Layout/ch_energy'
    energy_bins = hdf_read_var(en_var, filename=files[0])   ; only one file is enough.

;---Calibrate the data.
    time_var = '/Data/Array Layout/timestamps'
    times = hdf_read_var(time_var, filename=files)
    time_index = lazy_where(times, '[]', time_range, count=count)
    if count eq 0 then begin
        errmsg = 'No data in given time_range ...'
        return, retval
    endif
    times = times[time_index]
    fluxs = fluxs[time_index,*]
    store_data, spec_var, times, fluxs, energy_bins
    zrange = (species eq 'e')? [1e5,1e9]: [1e4,1e8]
    species_name = (species eq 'e')? 'e-': 'H+'
    add_setting, spec_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'spec', $
        'unit', 'eV/cm!U2!N-sr-s-eV', $
        'zrange', zrange, $
        'species_name', species_name, $
        'ytitle', 'Energy (eV)', $
        'ylog', 1, $
        'zlog', 1, $
        'short_name', '' )
    
    return, spec_var

end


time_range = time_double(['2013-05-01/07:00','2013-05-01/10:00'])
probes = 'f'+['16','17','18']
time_range = time_double(['2015-03-16/07:00','2015-03-16/10:00'])
probes = 'f17'
species = 'e'
foreach probe, probes do begin
    var1 = dmsp_read_en_spec_madrigal(time_range, probe=probe, species=species)
    ;var2 = dmsp_read_en_spec_cdaweb(time_range, probe=probe, species=species)
    tplot, var1, trange=time_range

stop
endforeach
end
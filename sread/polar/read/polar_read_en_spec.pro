;+
;
;-

function polar_read_en_spec, input_time_range, errmsg=errmsg, $
    species=species, get_name=get_name, update=update, $
    pitch_angle_range=pitch_angle_range, suffix=suffix

    prefix = 'po_'
    errmsg = ''
    retval = ''
    if n_elements(suffix) eq 0 then suffix = ''
    if n_elements(species) eq 0 then species = 'e'
    spec_var = prefix+species+'_en_spec'+suffix
    if keyword_set(get_name) then return, spec_var
    if keyword_set(update) then del_data, spec_var
    time_range = time_double(input_time_range)
    if ~check_if_update(spec_var, time_range) then return, spec_var
    
    files = polar_ld_hydra(time_range, id='h0', errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()

    time_var = 'EPOCH'
    if species eq 'e' then begin
        energy_var = 'energy_ele'
        flux_var = 'electron_differential_energy_flux'
        species_name = 'e-'
        zrange = [1e3,1e8]
    endif else begin
        energy_var = 'energy_ion'
        flux_var = 'ion_differential_energy_flux'
        species_name = 'H+'
        zrange = [1e3,1e7]
    endelse
    energy_var = strupcase(energy_var)
    flux_var = strupcase(flux_var)
    var_list.add, dictionary($
        'in_vars', [flux_var], $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    en_centers = cdf_read_var(energy_var, filename=files[0])

    fillval = !values.f_nan
    get_data, flux_var, times, fluxs, limits=lim
    index = where(abs(fluxs) ge 1e30, count)
    if count ne 0 then fluxs[index] = fillval
    unit = '#/cm!E2!N-s-sr'
;    ; convert from #/cm^2-s-sr to eV/cm^2-s-sr-eV
    de_e = pad_get_de_e(en_centers)     ; in eV/eV.
;    ccs = de_e/en_centers
;    foreach cc, ccs, ii do begin
;        fluxs[*,ii] *= cc
;    endforeach
    fluxs *= de_e
    unit = 'eV/cm!E2!N-s-sr-eV'
    
    store_data, spec_var, times, fluxs, en_centers
    add_setting, spec_var, smart=1, {$
        display_type: 'spec', $
        unit: unit, $
        zrange: zrange, $
        species_name: species_name, $
        ytitle: 'Energy (eV)', $
        ylog: 1, $
        zlog: 1, $
        short_name: ''}
    

    return, spec_var

end

time_range = ['1998-10-05','1998-10-06']
;time_range = ['1998-09-25','1998-09-26']
var1 = polar_read_en_spec(time_range, species='e', update=1)
var2 = polar_read_en_spec(time_range, species='p', update=1)
vars = [var1,var2]
tplot, vars, trange=time_range
end
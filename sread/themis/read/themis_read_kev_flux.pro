;+
; Read high energy electron and ion fluxes.
; 
; id=. 'e' or 'p' or ['e','p'].
;-
function themis_read_kev_flux, input_time_range, probe=probe, id=datatype, $
    errmsg=errmsg, get_name=get_name, spec=spec, energy_range=energy_range

    time_range = time_double(input_time_range)
    files = themis_load_sst(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, ''

    prefix = 'th'+probe+'_'
    if n_elements(datatype) eq 0 then datatype = ['e','p']
    vars = prefix+'kev_'+datatype+'_flux'
    if keyword_set(get_name) then return, vars

    var_list = list()
    in_vars = prefix+['psif_en_eflux','psif_en_eflux_yaxis']
    out_vars = prefix+'kev_'+['p_flux','p_flux_energy']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+'psif_time', $
        'time_var_type', 'unix' )
    in_vars = prefix+['psef_en_eflux','psef_en_eflux_yaxis']
    out_vars = prefix+'kev_'+['e_flux','e_flux_energy']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+'psef_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    ct = 52
    min_flux = 1e-3
    foreach var, vars do begin
        get_data, var, times, flux
        get_data, var+'_energy', times, energy
        energy = reform(energy[0,*])*1e-3   ; assumes energy bins are time independent. True or not??
        index = where(finite(energy),nenergy)
        if nenergy eq 0 then message, 'inconsistency ...'
        energy = energy[index]
        flux = flux[*,index]>min_flux
        ; energy range.
        if n_elements(energy_range) eq 2 then begin
            index = lazy_where(energy, '[]', energy_range, count=nenergy)
            if nenergy eq 0 then return, ''
            energy = energy[index]
            flux = flux[*,index]
        endif
        for ii=0,nenergy-1 do flux[*,ii] /= energy[ii]
        short_name = (var eq prefix+'e_flux')? 'e!U-!N': 'H!U+!N'
        if ~keyword_set(spec) then begin
            store_data, var, times, flux, energy
            add_setting, var, smart=1, dictionary($
                'display_type', 'list', $
                'unit', '#/cm!U2!N-s-sr-keV', $
                'short_name', short_name, $
                'ylog', 1, $
                'color_table', ct, $
                'value_unit', 'keV' )
        endif else begin
            store_data, var, times, flux, energy
            add_setting, var, smart=1, dictionary($
                'display_type', 'spec', $
                'unit', '#/cm!U2!N-s-sr-keV', $
                'ylog', 1, $
                'ytitle', 'Energy (keV)', $
                'zlog', 1, $
                'color_table', ct, $
                'short_name', short_name )
        endelse
    endforeach

    return, vars

end

time_range = ['2008-01-19/06:00','2008-01-19/09:00']
probes = themis_probes()
probes = ['e','d','a']
plot_vars = list()
foreach probe, probes do begin
    vars = themis_read_kev_flux(time_range, probe=probe, spec=1)
;    ylim, vars, 30, 600, 1
;    options, vars, 'ytickv', [30,300]
;    options, vars, 'yticks', 1
;    options, vars, 'yminor', 10
    plot_vars.add, vars, extract=1
endforeach
plot_vars = plot_vars.toarray()
end
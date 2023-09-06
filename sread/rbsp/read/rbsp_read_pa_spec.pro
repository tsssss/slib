;+
; Read the pitch angle spectrogram, for a given energy range.
;-

function rbsp_read_pa_spec, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, $
    energy_range=energy_range

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species) eq 0 then species = 'e'
    all_species = ['e','p','o','he']
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    spec_var = prefix+species+'_pa_spec'
    if keyword_set(get_name) then return, spec_var

    time_range = time_double(input_time_range)
    files = rbsp_load_hope(time_range, id='l3%pa', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()

    suffix = (species eq 'e')? '_Ele': '_Ion'
    time_var = 'Epoch'+suffix
    energy_var = 'HOPE_ENERGY'+suffix
    flux_var = strupcase('f'+species+'du')
    var_list.add, dictionary($
        'in_vars', [energy_var,flux_var], $
        'time_var_name', time_var, $
        'time_var_type', 'Epoch' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    pitch_angles = cdf_read_var('PITCH_ANGLE', filename=files[0])
    npitch_angle = n_elements(pitch_angles)

    species_infos = dictionary()
    species_infos['e'] = dictionary('short_name', 'e!U-!N')
    species_infos['p'] = dictionary('short_name', 'H!U+!N')
    species_infos['o'] = dictionary('short_name', 'O!U+!N')
    species_infos['he'] = dictionary('short_name', 'He!U+!N')
    supported_species = species_infos.keys()


    fillval = !values.f_nan
    get_data, flux_var, times, fluxs
    index = where(abs(fluxs) ge 1e30, count)
    if count ne 0 then fluxs[index] = fillval
    energys = get_var_data(energy_var)


;---Treat en.
    ntime = n_elements(times)
    nenergy_input = n_elements(energy_range)
    if nenergy_input eq 1 then begin
        the_fluxs = fltarr(ntime,npitch_angle)
        for time_id=0,ntime-1 do begin
            for pitch_id=0,npitch_angle-1 do begin
                the_fluxs[time_id,pitch_id] = interpol(fluxs[time_id,*,pitch_id], energys[time_id,*], energy_range)
            endfor
        endfor
    endif else if nenergy_input eq 2 then begin
        the_fluxs = fltarr(ntime,npitch_angle)
        for time_id=0,ntime-1 do begin
            index = where_pro(energys[time_id,*], '[]', energy_range, count=count)
            if count eq 0 then continue
            the_fluxs[time_id,*] = total(fluxs[time_id,index,*],2, nan=1)/count
        endfor
    endif else begin
        energy_range = minmax(energys)
        dims = size(fluxs,dimensions=1)
        the_fluxs = total(fluxs,2,nan=1)/dims[2]
    endelse

    store_data, spec_var, times, the_fluxs, pitch_angles

    zrange = (species eq 'e')? [1e5,1e10]: [1e5,1e8]
    species_name = species_infos[species].short_name
    add_setting, spec_var, /smart, {$
        display_type: 'spec', $
        unit: '#/cm!U2!N-s-sr-keV', $
        zrange: zrange, $
        species_name: species_name, $
        ytitle: species_name+' PA (deg)', $
        ylog: 0, $
        zlog: 1, $
        yrange: [0,180], $
        short_name: ''}

    if nenergy_input eq 1 then begin
        the_energy = energy_range[0]
        energy_msg = sgnum2str(the_energy)
    endif else begin
        energy_msg = '['+sgnum2str(energy_range[0])+','+sgnum2str(energy_range[1])+']'
    endelse
    add_setting, spec_var, {$
        energy_range: energy_range, $
        ytitle: 'PA (deg)!C'+species_name+', PA '+energy_msg+' eV'}

    return, spec_var

end

time_range = time_double(['2013-05-01','2013-05-02'])
probe = 'b'

;time_range = time_double(['2013-06-01','2013-06-02'])
;probe = 'a'

vars = list()
foreach species, ['p','o'] do begin
    var = rbsp_read_pa_spec(time_range, probe=probe, species=species)
    vars.add, var
endforeach
vars = vars.toarray()

;tplot, vars, trange=time_range
end

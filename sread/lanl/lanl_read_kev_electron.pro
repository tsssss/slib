;+
; pitch_angle. A dummy keyword.
;-

pro lanl_read_kev_electron, time_range, probe=probe, errmsg=errmsg, energy=energy, pitch_angle=pitch_angle

    errmsg = ''
    pre0 = probe+'_'

    ; read 'flux'
    lanl_read_data, time_range, id='sopa', probe=probe

    var = 'e_flux'
    fillval = -1e31
    nan = !values.f_nan
    get_data, var, times, data
    index = where(data eq fillval, count)
    if count ne 0 then data[index] = nan
    store_data, var, times, data


    get_data, var, times, flux
    var = pre0+'kev_e_flux'
    energy_bins = get_var_data('e_energy')
    nenergy_bin = n_elements(energy_bins)

    ; apply energy range.
    if n_elements(energy) eq 0 then energy_index = findgen(nenergy_bin) else begin
        case n_elements(energy) of
            1: begin
                energy_index = where(energy_bins eq energy, count)
                if count eq 0 then tmp = min(energy_bins-energy[0], /absolute, energy_index)
                end
            2: begin
                energy_index = where_pro(energy_bins, energy, count=count)
                if count eq 0 then begin
                    errmsg = 'no energy in given range ...'
                    return
                endif
                end
            else: begin
                errmsg = 'wrong # of energy info ...'
                return
                end
        endcase
    endelse
    flux = flux[*,energy_index]
    energy_bins = energy_bins[energy_index]
    nenergy_bin = n_elements(energy_bins)

    store_data, var, times, flux, energy_bins

    yrange = 10d^ceil(alog10(minmax(flux)))
    add_setting, var, /smart, {$
        display_type: 'list', $
        ylog: 1, $
        yrange: yrange, $
        color_table: 52, $
        unit: '#/cm!U2!N-s-sr-keV', $
        value_unit: 'keV', $
        short_name: 'e!U-!N flux'}

end

time = time_double(['2014-08-28/09:00','2014-08-28/12:00'])
probes = ['LANL-01A','1991-080','1994-084','LANL-97A','LANL-04A','LANL-02A']
foreach probe, probes do lanl_read_kev_electron, time, probe=probe, energy=[0,1000]

e_probes = probes
p_probes = shift(reverse(probes),1)
end

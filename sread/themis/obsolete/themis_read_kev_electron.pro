;+
; Read THEIS keV electron flux. Save as 'thx_kev_e_flux'.
;
; pitch_angle. A dummy keyword.
;-

pro themis_read_kev_electron, time_range, probe=probe, errmsg=errmsg, energy=energy, pitch_angle=pitch_angle

    pre0 = 'th'+probe+'_'

    themis_read_sst, time_range, id='l2%e_kev', probe=probe

    get_data, pre0+'e_energy', times, energy_bins
    energy_bins = reform(energy_bins[0,*])*1e-3
    index = where(finite(energy_bins), count)
    if count eq 0 then begin
        errmsg = handle_error('No valid energy bin ...')
        return
    endif
    energy_bins = energy_bins[index]
    get_data, pre0+'e_flux', times, flux
    flux = flux[*,index]>1e-3
    foreach bin, energy_bins, ii do flux[*,ii] /= energy_bins[ii]   ; from eV/(cm^2-s-sr-eV) to #/cm^2-s-sr-keV.

    ; Apply energy range.
    nenergy_bin = n_elements(energy_bins)
    if n_elements(energy) eq 0 then energy_index = findgen(nenergy_bin) else begin
        case n_elements(energy) of
            1: tmp = min(energy_bins-energy[0], /absolute, energy_index)
            2: begin
                energy_index = lazy_where(energy_bins, energy, count=count)
                if count eq 0 then begin
                    errmsg = handle_error('No energy in given range ...')
                    return
                endif
                end
            else: begin
                errmsg = handle_error('Wrong # of input energy ...')
                return
                end
        endcase
    endelse
    flux = flux[*,energy_index]
    energy_bins = energy_bins[energy_index]

    ; Save data.
    yrange = 10d^ceil(alog10(minmax(flux)))>1
    tvar = pre0+'kev_e_flux'
    store_data, tvar, times, flux, energy_bins
    add_setting, tvar, /smart, {$
        display_type: 'list', $
        ylog:1, $
        yrange: yrange, $
        color_table: 52, $
        unit: '#/cm!U2!N-s-sr-keV', $
        value_unit: 'keV', $
        short_name: 'e!U-!N flux'}

end

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
time_range = time_double(['2017-01-01','2017-01-02'])
probe = 'e'
themis_read_kev_electron, time_range, probe=probe, energy=[0,1000]
end

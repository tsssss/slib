;+
; Read THEIS keV electron flux. Save as 'thx_kev_e_flux'.
;
;-

pro themis_read_kev_electron, time_range, probe=probe, errmsg=errmsg

    pre0 = 'th'+probe+'_'

    themis_read_sst, time_range, id='l2%e_kev', probe=probe

    get_data, pre0+'e_energy', times, energy
    energy_bins = reform(energy[0,*])*1e-3
    index = where(finite(energy_bins), count)
    if count eq 0 then begin
        errmsg = handle_error('No valid energy bin ...')
        return
    endif
    energy_bins = energy_bins[index]
    get_data, pre0+'e_flux', times, flux
    flux = flux[*,index]
    foreach bin, energy_bins, ii do flux[*,ii] /= energy_bins[ii]   ; from eV/(cm^2-s-sr-eV) to #/cm^2-s-sr-keV.

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

time_range = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
themis_read_kev_electron, time_range, probe='a'
end

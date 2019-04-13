;+
; Read GOES keV proton flux. Save as 'gxx_h_flux'.
;
;-

pro goes_read_kev_proton, time_range, probe=probe, errmsg=errmsg

    goes_init
    !goes.local_data_dir = join_path([default_local_root(),'data','goes'])
    goes_lib

    pre0 = 'g'+probe+'_'
    goes_load_data, trange=time_range, probe=probe, datatype='magpd', /noephem

    ; Energy channels for the MAGED instrument, from the GOES-N databook
    energy_bin_ranges = [80.,110,170,250,350,800]
    nenergy_bin = n_elements(energy_bin_ranges)-1
    energy_bins = round(energy_bin_ranges[1:nenergy_bin]+energy_bin_ranges[0:nenergy_bin-1])*0.5

    ; Combine to omni directional flux.
    ; From goes_part_omni_flux. The problem is it doesn't treat nan.
    vars = pre0+'magpd_'+string(energy_bins,format='(I0)')+'keV_dtc_uncor_flux'
    get_data, vars[0], times
    ntime = n_elements(times)
    flux = fltarr(ntime,nenergy_bin)
    frac_total_sa = 18.*!pi*(1-cos(15*!dtor))/(4*!pi) ;for all 9 telescopes, sr
    for ii=0,nenergy_bin-1 do begin
        get_data, vars[ii], uts, tflux
        tflux = sinterpol(tflux, uts, times)
        flux[*,ii] = total(tflux,2,/nan)/frac_total_sa
    endfor

    yrange = 10d^ceil(alog10(minmax(flux)))
    tvar = pre0+'kev_h_flux'
    store_data, tvar, times, flux, energy_bins
    add_setting, tvar, /smart, {$
        display_type: 'list', $
        ylog:1, $
        yrange: yrange, $
        color_table: 52, $
        unit: '#/cm!U2!N-s-sr-keV', $
        value_unit: 'keV', $
        short_name: 'H!U+!N flux'}

end

time_range = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
goes_read_kev_proton, time_range, probe='15'
end

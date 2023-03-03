;+
; probe. '15','16',etc. Without 'g'
;-

function goes_read_kev_proton, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, spec=spec

    errmsg = ''
    retval = ''


    prefix = 'g'+probe+'_'
    out_var = prefix+'kev_p_flux'
    if keyword_set(get_name) then return, out_var

    ; Init.
    goes_init
    !goes.local_data_dir = join_path([default_local_root(),'goes'])
    goes_lib
    time_range = time_double(input_time_range)
    goes_load_data, trange=time_range, probe=probe, datatype='magpd', noephem=1

    ; Energy channels for the MAGED instrument, from the GOES-N databook
    energy_bin_ranges = [80.,110,170,250,350,800]
    nenergy_bin = n_elements(energy_bin_ranges)-1
    energy_bins = round(energy_bin_ranges[1:nenergy_bin]+energy_bin_ranges[0:nenergy_bin-1])*0.5

    ; Combine to omni directional flux.
    ; From goes_part_omni_flux. The problem is it doesn't treat nan.
    vars = prefix+'magpd_'+string(energy_bins,format='(I0)')+'keV_dtc_uncor_flux'
    get_data, vars[0], times
    ntime = n_elements(times)
    if ntime eq 1 and times[0] eq 0 then begin
        errmsg = 'No data ...'
        return, retval
    endif
    flux = fltarr(ntime,nenergy_bin)
    frac_total_sa = 18.*!pi*(1-cos(15*!dtor))/(4*!pi) ;for all 9 telescopes, sr
    for ii=0,nenergy_bin-1 do begin
        get_data, vars[ii], uts, tflux
        tflux = sinterpol(tflux, uts, times)
        flux[*,ii] = total(tflux,2,/nan)/frac_total_sa
    endfor

    ; Apply energy range.
    nenergy_bin = n_elements(energy_bins)
    if n_elements(energy) eq 0 then energy_index = findgen(nenergy_bin) else begin
        case n_elements(energy) of
            1: tmp = min(energy_bins-energy[0], /absolute, energy_index)
            2: begin
                energy_index = lazy_where(energy_bins, energy, count=count)
                if count eq 0 then begin
                    errmsg = handle_error('No energy in given range ...')
                    return, retval
                endif
                end
            else: begin
                errmsg = handle_error('Wrong # of input energy ...')
                return, retval
                end
        endcase
    endelse
    flux = flux[*,energy_index]
    energy_bins = energy_bins[energy_index]

    ; Save data.
    yrange = 10d^ceil(alog10(minmax(flux)))
    flux_unit = '#/cm!U2!N-s-sr-keV'
    energy_unit = 'keV'
    short_name = 'H!U+!N'
    ct = 52
    store_data, out_var, times, flux, energy_bins
    add_setting, out_var, smart=1, {$
        display_type: 'list', $
        ylog:1, $
        yrange: yrange, $
        color_table: ct, $
        unit: flux_unit, $
        value_unit: energy_unit, $
        short_name: short_name }

    if keyword_set(spec) then begin
        options, out_var, 'spec', 1
        options, out_var, 'no_interp', 1
        options, out_var, 'zlog', 1
        options, out_var, 'ylog', 1
        options, out_var, 'ytitle', 'Energy ('+energy_unit+')'
        options, out_var, 'ztitle', short_name+' ('+flux_unit+')'
        if n_elements(energy_bins) ne 0 then begin
            ylim, out_var, min(energy_bins), max(energy_bins)
        endif
    endif


    return, out_var

end

probes = ['11']
time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
foreach probe, probes do var = goes_read_kev_proton(time_range, probe=probe)
end

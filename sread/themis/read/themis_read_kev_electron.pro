;+
; Read THEIS keV electron flux. Save as 'thx_kev_e_flux'.
;
; pitch_angle. A dummy keyword.
;-

function themis_read_kev_electron, time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, $
    pitch_angle_range=pitch_angle_range, energy_range=energy_range, spec=spec

    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    out_var = prefix+'kev_e_flux'
    if keyword_set(get_name) then return, out_var
    files = themis_load_sst(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = prefix+['psef_en_eflux','psef_en_eflux_yaxis']
    out_vars = prefix+'kev_'+['e_flux','e_flux_energy']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+'psef_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    min_flux = 1e-3
    get_data, out_var, common_times, fluxs
    get_data, out_var+'_energy', common_times, energy_bins
    energy_bins = reform(energy_bins[0,*])*1e-3   ; assumes energy bins are time independent. True or not??
    index = where(finite(energy_bins),nenergy_bin)
    if nenergy_bin eq 0 then message, 'inconsistency ...'
    energy_bins = energy_bins[index]
    fluxs = fluxs[*,index]>min_flux


;---Apply energy range.
    nenergy_range = n_elements(energy_range)
    if nenergy_range eq 0 then begin
        energy_index = findgen(nenergy_bin)
    endif else if nenergy_range eq 1 then begin
        energy_index = where(energy_bins eq energy_range, count)
        if count eq 0 then begin
            tmp = min(energy_bins-energy_range[0], absolute=1, energy_index)
        endif
        energy_ratio = 1.5
        the_energy_range = energy_range[0]*[energy_ratio,1/energy_ratio]
        index = lazy_where(energy_bins[energy_index], '[]', the_energy_range, count=count) 
        if count eq 0 then return, retval
    endif else if nenergy_range eq 2 then begin
        energy_index = lazy_where(energy_bins, '[]', energy_range, count=count)
        if count eq 0 then begin
            errmsg = 'no energy in given range ...'
            return, retval
        endif
    endif else begin
        errmsg = 'wrong # of energy info ...'
        return, retval
    endelse 
    fluxs = fluxs[*,energy_index,*]
    energy_bins = energy_bins[energy_index]
    nenergy_bin = n_elements(energy_bins)


;---Apply pitch angle range.
    ; Dummy.



;---Save data.
    for ii=0,nenergy_bin-1 do fluxs[*,ii] /= energy_bins[ii]
    flux_unit = '#/cm!U2!N-s-sr-keV'
    energy_unit = 'keV'
    short_name = 'e!U-!N'
    ct = 52
    if nenergy_bin eq 1 then begin
        store_data, out_var, common_times, fluxs
        add_setting, out_var, smart=1, {$
            display_type: 'scalar', $
            ylog: 1, $
            unit: flux_unit, $
            short_name: short_name+' '+sgnum2str(sround(energy_bins))+energy_unit}
    endif else begin
        store_data, out_var, common_times, fluxs, energy_bins
        add_setting, out_var, smart=1, {$
            display_type: 'list', $
            ylog: 1, $
            color_table: ct, $
            unit: flux_unit, $
            value_unit: energy_unit, $
            short_name: short_name }
    endelse

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

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
time_range = time_double(['2017-01-01','2017-01-02'])
time_range = time_double(['2013-01-01','2013-01-02'])
probe = 'e'
var = themis_read_kev_electron(time_range, probe=probe, spec=1)
end
;+
; Read RBSP keV electron flux.
; Save as rbspx_kev_e_flux.
;
; set pitch_angle_range to load data for a specific pitch angle, otherwise load all pitch angles.
;-
function rbsp_read_kev_electron, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, $
    pitch_angle_range=pitch_angle_range, energy_range=energy_range, spec=spec

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    out_var = prefix+'kev_e_flux'
    if keyword_set(get_name) then return, out_var

    time_range = time_double(input_time_range)
    files = rbsp_load_mageis(time_range, probe=probe, errmsg=errmsg, id='l3')
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = ['FEDU']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    energy_bins = cdf_read_var('FEDU_Energy', filename=files[0])
    nenergy_bin = n_elements(energy_bins)
    energy_index = where(finite(energy_bins) and energy_bins ge 0, nenergy_bin)
    energy_bins = energy_bins[energy_index]

    get_data, 'FEDU', common_times, fluxs
    fluxs = reform(fluxs[*,energy_index,*])>1

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
        index = where_pro(energy_bins[energy_index], '[]', the_energy_range, count=count) 
        if count eq 0 then return, retval
    endif else if nenergy_range eq 2 then begin
        energy_index = where_pro(energy_bins, '[]', energy_range, count=count)
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
    pitch_angle_bins = cdf_read_var('FEDU_Alpha', filename=files[0])
    npitch_angle_bin = n_elements(pitch_angle_bins)
    npitch_angle_range = n_elements(pitch_angle_range)
    if npitch_angle_range eq 0 then begin
        pitch_angle_index = findgen(npitch_angle_bin)
    endif else if npitch_angle_range eq 1 then begin
        pitch_angle_index = where(pitch_angle_bins eq pitch_angle_range, count)
        if count eq 0 then begin
            tmp = min(pitch_angle_bins-pitch_angle_range[0], absolute=1, pitch_angle_index)
        endif
    endif else if npitch_angle_range eq 2 then begin
        pitch_angle_index = where_pro(pitch_angle_bins, '[]', pitch_angle_range, count=count)
        if count eq 0 then begin
            errmsg = 'no pitch angle in given range ...'
            return, retval
        endif
    endif else begin
        errmsg = 'wrong # of pitch angle info ...'
        return, retval
    endelse
    fluxs = reform(fluxs[*,*,pitch_angle_index])
    pitch_angle_bins = pitch_angle_bins[pitch_angle_index]
    npitch_angle_bin = n_elements(pitch_angle_bins)

    ; Average pitch angle if no pitch angle info is provided.
    if npitch_angle_range eq 0 then begin
        fluxs = total(fluxs,3,nan=1)/npitch_angle_bin
        npitch_angle_bin = 0
    endif

;---Save data.
    flux_unit = '#/cm!U2!N-s-sr-keV'
    energy_unit = 'keV'
    short_name = 'e!U-!N'
    ct = 52
    if nenergy_bin eq 1 and npitch_angle_bin eq 1 then begin
        store_data, out_var, common_times, fluxs
        add_setting, out_var, smart=1, {$
            display_type: 'scalar', $
            ylog: 1, $
            unit: flux_unit, $
            short_name: short_name+' '+sgnum2str(sround(pitch_angle_bins))+'deg, '+sgnum2str(sround(energy_bins))+energy_unit}
    endif else if nenergy_bin eq 1 then begin    ; flux vs pitch angle at certain energy.
        store_data, out_var, common_times, fluxs, pitch_angle_bins
        add_setting, out_var, smart=1, {$
            display_type: 'list', $
            ylog: 1, $
            unit: flux_unit, $
            value_unit: 'deg', $
            short_name: short_name+' '+sgnum2str(sround(energy_bins))+energy_unit}
    endif else if npitch_angle_bin eq 1 then begin    ; flux vs energy at certain pitch angle.
        yrange = 10d^ceil(alog10(minmax(fluxs)))>1
        store_data, out_var, common_times, fluxs, energy_bins
        add_setting, out_var, smart=1, {$
            display_type: 'list', $
            ylog: 1, $
            yrange: yrange, $
            color_table: ct, $
            unit: flux_unit, $
            value_unit: energy_unit, $
            short_name: short_name+' '+sgnum2str(sround(pitch_angle_bins))+' deg'}
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

;    dt = 10.848
;    uniform_time, out_var, dt
    return, out_var

end

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:00'])
var = rbsp_read_kev_electron(time_range, probe='b', spec=1)
end

;+
; Read MMS keV electron flux. Save as 'mms1_kev_e_flux'.
;-

function mms_read_kev_electron, time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, update=update, $
    pitch_angle_range=pitch_angle_range, energy_range=energy_range, spec=spec, $
    _extra=ex

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    out_var = prefix+'kev_e_flux'
    if keyword_set(get_name) then return, out_var
    if keyword_set(update) then del_data, out_var
    pad_var = mms_read_pad_ele_kev(time_range, probe=probe, errmsg=errmsg, _extra=ex)
    if errmsg ne '' then return, retval

    var = pad_get_en_spec(pad_var=pad_var, var_info=out_var)


;---Apply energy range.
    fluxs = get_var_data(out_var, times=times, energy_bins)
    nenergy_bin = n_elements(energy_bins)
    nenergy_range = n_elements(energy_range)
    if nenergy_range eq 0 then begin
        energy_index = findgen(nenergy_bin)
    endif else if nenergy_range eq 1 then begin
        target_energy = energy_range[0]
        energy_index = where(energy_bins eq target_energy, count)
        if count eq 0 then begin
            tmp = min(energy_bins-target_energy, absolute=1, energy_index)
            ; Check if the closest energy bin is within the target energy range.
            energy_ratio = 1.5
            the_energy_range = target_energy*[1/energy_ratio,energy_ratio]
            index = where_pro(energy_bins[energy_index], '[]', the_energy_range, count=count)
            if count eq 0 then return, retval
        endif
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
    flux_unit = get_var_setting(out_var, 'unit')
    store_data, out_var, times, fluxs, energy_bins

    if keyword_set(spec) then begin
        energy_unit = 'eV'
        short_name = 'flux'
        options, out_var, 'spec', 1
        options, out_var, 'no_interp', 1
        options, out_var, 'zlog', 1
        options, out_var, 'ylog', 1
        options, out_var, 'ytitle', 'Energy ('+energy_unit+')'
        options, out_var, 'ztitle', short_name+' ('+flux_unit+')'
        if n_elements(energy_bins) ne 0 then begin
            ylim, out_var, min(energy_bins), max(energy_bins)
        endif
    endif else begin
        labels = strtrim(string(energy_bins*1e-3,format='(F20.1)'),2)+' keV'
        add_setting, out_var, smart=1, dictionary($
            'display_type', 'stack', $
            'labels', labels )
        options, out_var, $
            spec=0, ylog=1, ytitle='('+flux_unit+')'
    endelse


    return, out_var


end


time_range = ['2016-03-05','2016-03-06']
probe = '4'
vars = mms_read_kev_electron(time_range, probe=probe, spec=1)
; vars = read('mms', 'kev_electron', time_range, probe=probe, spec=1)
; -> mms_read_kev_electron(time_range, **kwarg)
tplot, vars
stop

time_range = ['2015-09-01','2015-09-02']
probes = ['1','2','3','4']
probes = ['4']
energy_range = 1.04e5 ; eV.
energy_range = !null
plot_vars = list()
foreach probe, probes do begin
    vars = mms_read_kev_electron(time_range, probe=probe, spec=0, energy_range=energy_range)
    plot_vars.add, vars, extract=1
endforeach
plot_vars = plot_vars.toarray()
tplot, plot_vars, trange=time_range
end

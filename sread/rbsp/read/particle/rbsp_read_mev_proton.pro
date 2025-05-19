;+
; Read MeV ion.
;-

function rbsp_read_mev_proton, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, no_spin_average=no_spin_average, $
    pitch_angle_range=pitch_angle_range, energy_range=energy_range, spec=spec


    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    out_var = prefix+'mev_p_flux'
    if keyword_set(get_name) then return, out_var

    time_range = time_double(input_time_range)
    files = rbsp_ld_rbspice(time_range, probe=probe, id='l3%tofxeh')
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = ['FPDU','Spin']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    orig_fluxs = get_var_data('FPDU', times=common_times)
    index = where(orig_fluxs le 0, count)
    if count ne 0 then begin
        orig_fluxs[index] = !values.f_nan
        store_data, 'FPDU', common_times, orig_fluxs
    endif
    energys = cdf_read_var('FPDU_Energy', filename=files[0])

    ; omni. from rbsp_rbspice_omni
    nsector = n_elements(orig_fluxs[0,0,*])
    fluxs = total(orig_fluxs,3, nan=1)/nsector  ; mean will skip nans.
    energys = mean(energys,dimension=2)
    ;energys = energys[0]
    nenergy = n_elements(energys)
    

    ; Convert from #/cm^2-s-sr-MeV to #/cm^2-s-sr-keV
    flux_unit = '#/cm!U2!N-s-sr-keV'
    fluxs *= 1e-3
    ; Convert from MeV to keV
    energy_unit = 'keV'
    energy_bins = energys*1e3
    

;---Save data.
    short_name = 'H!U+!N'
    ct = 52

    if keyword_set(no_spin_average) then begin
        store_data, out_var, common_times, fluxs, energy_bins
    endif else begin
        ; spin average. from rbsp_rbspice_spin_avg. This should be default b/c otherwise data contain artificial modulations.
        spins = get_var_data('Spin')
        spin_starts = uniq(spins)
        spin_sectors = [0,spin_starts]
        spin_times = common_times[spin_starts]
        nspin_time = n_elements(spin_times)
        spin_fluxs = fltarr(nspin_time,nenergy)+!values.f_nan
        for ii=0,nspin_time-1 do begin
            i0 = spin_sectors[ii]+1
            i1 = spin_sectors[ii+1]
            if i0 eq i1 then continue
            spin_fluxs[ii,*] = mean(fluxs[i0:i1,*],dimension=1,nan=1)
        endfor
        store_data, out_var, spin_times, spin_fluxs, energy_bins
    endelse
    add_setting, out_var, smart=1, {$
        display_type: 'list', $
        ylog: 1, $
        color_table: ct, $
        unit: flux_unit, $
        value_unit: energy_unit, $
        short_name: short_name }
    

    if keyword_set(spec) then begin
        options, out_var, 'display_type', 'spec'
        options, out_var, 'spec', 1
        options, out_var, 'no_interp', 1
        options, out_var, 'zlog', 1
        options, out_var, 'ylog', 1
        options, out_var, 'ytitle', 'Energy ('+energy_unit+')'
        options, out_var, 'ztitle', flux_unit
        ;m, [/ort_name+' ('+flux_unit+')'
        if n_elements(energy_bins) ne 0 then begin
            ylim, out_var, min(energy_bins), max(energy_bins)
        endif
    endif
    options, out_var, requested_time_range=time_range

;    dt = 10.848
;    uniform_time, out_var, dt
    return, out_var
    

    

end

test = 0
time_range = ['2015-10-16','2015-10-17']
time_range = ['2014-11-16','2014-11-16/09:00']

foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
    
    ;rbsp_load_rbspice, probe=probe, trange=time_range, datatype='TOFxEH', level='l3'
    ;rbsp_load_rbspice, probe=probe, trange=time_range, datatype='TOFxENonH', level='l3'
    ;
    ;var1 = rbsp_read_mev_proton(time_range, probe=probe, spec=1, no_spin_average=1)
    ;var1 = rename_var(var1, output=var1+'_orig')
    ;var2 = rbsp_read_mev_proton(time_range, probe=probe, spec=1)
    ;var = prefix+'rbspice_l3_TOFxEH_proton_omni'
    ;vars = [var1,var,var2,var+'_spin']
    ;options, vars, yrange=[60,600], zrange=[1e1,1e5], color_table=40
    ;
    ;stop
    
    var1 = rbsp_read_mev_proton(time_range, probe=probe, spec=1)
    var2 = rbsp_read_kev_proton(time_range, probe=probe, spec=1)
    var3 = rbsp_read_en_spec(time_range, probe=probe, species='p', update=1)
    lvar = rbsp_read_lshell(time_range, probe=probe)
    
    ylim = 5e4
    options, [var1,var2], zrange=[1e3,1e7], color_table=40, yrange=[ylim*1e-3,1.2e3]
    options, [var2], zrange=[1e3,1e7]*1e-2, color_table=40
    options, var3, zrange=[1e3,1e7], yrange=[500,ylim]
    options, [var1,var3], zrange=[1e3,1e5], color_table=52, zcharsize=0.9
    options, lvar, yrange=[1,6], ytickv=[2,4,6], yminor=2, yticks=2
    
    get_data, var1, times, data, energys
    data *= 0.5
    store_data, var1, times, data, energys
    
    plot_vars = [var1,var3,var2,lvar]
    nplot_var = n_elements(plot_vars)
    fig_labels = letters(nplot_var)+'. '+['RBSpice!C    x0.5','HOPE','MagEIS','L-shell']
    ypans = [0.5,0.8,0.5,0.3]
    ypads = [0,0.5,0.5]
    
    foreach var, plot_vars do begin
        data = get_var_data(var, times=times, vals)
        index = where(finite(data,nan=1) or data eq 0, count)
        if count ne 0 then begin
            data[index] = 0.1
            store_data, var, times, data, vals
        endif
    endforeach
    
    get_data, var3, times, data, vals, limits=lim
    store_data, var3, times, data, vals*1e-3, limits=lim
    options, var3, ytitle='Energy (keV)', yrange=lim.yrange*1e-3
    
    
    plot_file = join_path([homedir(),time_string(time_range[0],tformat='YYYY_MMDD')+'_'+prefix+'_hope_rbspice_v01.pdf'])
    if keyword_set(test) then plot_file = 0
    sgopen, plot_file, size=[8,6], xchsz=xchsz, ychsz=ychsz
    poss = sgcalcpos(nplot_var, margins=[12,4,10,2.5], ypans=ypans, ypad=ypads)
    tplot, plot_vars, position=poss, trange=time_range, title='RBSP-'+strupcase(probe)
    for ii=0,nplot_var-1 do begin
        tpos = poss[*,ii]
        tx = tpos[0]-xchsz*11
        ty = tpos[3]-ychsz*0.8
        msg = fig_labels[ii]
        xyouts, tx,ty,msg, normal=1
    endfor
    if keyword_set(test) then stop
    sgclose

endforeach
end
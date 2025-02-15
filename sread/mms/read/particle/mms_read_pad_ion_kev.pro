; This version has artificial peaks around 90 deg.
;+
; Read ion pitch angle distribution from FEEPS.
; 12 top sensors and 12 bottom sensors.
; 
; no_spin_average=. Set to skip spin average.
;-


function mms_read_pad_ion_kev, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    no_spin_average=no_spin_average, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, $
    update=update, get_name=get_name, suffix=suffix


    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'


    ; Prepare var name.
    species = 'p'
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = prefix+species+'_pad_kev'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    files = mms_ld_feeps_pad_ion(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = [prefix+'pad_feeps_ion']
    out_vars = [prefix+'pad_ion_kev']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    pad_unit = (cdf_read_setting(in_vars[0], filename=files[0]))['UNITS']
    phi_var = prefix+'phi_centers'
    phi_centers = cdf_read_var(phi_var, filename=files[0])
    phi_unit = (cdf_read_setting(phi_var, filename=files[0]))['UNITS']
    pa_var = prefix+'pa_centers'
    pa_centers = cdf_read_var(pa_var, filename=files[0])
    pa_unit = (cdf_read_setting(pa_var, filename=files[0]))['UNITS']
    en_var = prefix+'en_centers'
    en_centers = cdf_read_var(en_var, filename=files[0])
    en_unit = (cdf_read_setting(en_var, filename=files[0]))['UNITS']

    pad3d_var = out_vars[0]
    pad3d_fluxs = get_var_data(pad3d_var, times=times)
    nphi = n_elements(phi_centers)
    pad_fluxs = total(pad3d_fluxs,2)/nphi
    
    pad_var = var_info
    if ~keyword_set(no_spin_average) then begin
    ;--- spin average.
        instr_str = 'feeps'
        mode_str = 'srvy'
        level_str = 'l2'
        species_str = 'ion'
        id = strjoin([level_str,mode_str,species_str],'%')
        files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
        
        prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'
        spin_var = prefix2+'spinsectnum'
        var_list = list()
        var_list.add, dictionary($
            'in_vars', spin_var, $
            'time_var_name', 'epoch', $
            'time_var_type', 'tt2000' )
        read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
        
        ; spin averaged fluxs.
        spin_sectors = get_var_data(spin_var)
        ntime = n_elements(times)
        spin_index = where(spin_sectors[0:ntime-2] ge spin_sectors[1:ntime-1], count)+1
        nspin_sector = count-1
        sp_times = times[spin_index[0:nspin_sector-1]]
        sp_pad_fluxs = pad_fluxs[spin_index[0:nspin_sector-1],*,*]
        for ii=0,nspin_sector-1 do begin
            i0 = spin_index[ii]
            i1 = spin_index[ii+1]-1
            drec = (i1-i0)+1
            sp_pad_fluxs[ii,*,*] = total(pad_fluxs[i0:i1,*,*],1,nan=1)/drec
        endfor
        store_data, pad_var, sp_times, sp_pad_fluxs
    endif else begin
        store_data, pad_var, times, pad_fluxs
    endelse

    ; Convert to #/cm^2-s-sr-keV.
    get_data, pad_var, times, pad_fluxs
    nen_center = n_elements(en_centers)
    for ii=0,nen_center-1 do begin
        pad_fluxs[*,*,ii] /= en_centers[ii]*1e-3
    endfor
    pad_unit = '#/cm!U2!N-s-sr-keV'
    
    add_setting, pad_var, dictionary($
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms', $
        'mission_probe', 'mms'+probe, $
        'display_type', 'pad', $
        'unit', pad_unit, $
        'species', species, $
        'pa_centers', pa_centers, $
        'pa_unit', pa_unit, $
        'en_centers', en_centers, $
        'en_unit', en_unit )
    
    return, var_info
    

end





tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'

tr = ['2016-10-14/20:00','2016-10-14/22:30']
probe = '1'
plot_time = time_double('2016-10-14/21:43:30')
plot_time = time_double('2016-10-14/22:11:00')
tr = ['2015-09-01/18:00','2015-09-01/24:00']
plot_time = time_double('2015-09-01/22:00')


; keV ion.
ion_var2 = mms_read_pad_ion_kev(tr, probe=probe)
ion_en_var = mms_read_en_spec_ion(tr, probe=probe, id='kev')
tmp = plot_pad_polygon(ion_var2, plot_times=plot_time, test=1, zrange=[1e1,2e7], color_table=49)
stop

;dpa = total(pas*[-1,1])
;cpas = [pas-dpa*0.5,pas[npa-1]+dpa*0.5]
;den = mean(ens[1:nen-1]/ens[0:nen-2])
;cens = [ens/sqrt(den),ens[nen-1]*sqrt(den)]
;tts = pas # (fltarr(nen)+1)
;rrs = alog10(ens) ## (fltarr(npa)+1)
;ctts = cpas # (fltarr(nen+1)+1)
;crrs = alog10(cens) ## (fltarr(npa+1)+1)
;stop
;tmp = min(times-time_double('2016-08-04/22:10'), abs=1, time_id)
;sgdistr2d_polygon, reform(pad[time_id,*,*]), tts, rrs, ctts, crrs, ct=40


end
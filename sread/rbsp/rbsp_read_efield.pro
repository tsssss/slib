;+
; Read RBSP DC E field. Default is to read 'survey mgse' at 11 sec.
;-
;

pro rbsp_read_efield, time_range, probe=probe, resolution=resolution, errmsg=errmsg

    errmsg = ''
    pre0 = 'rbsp'+probe+'_'
    rgb = sgcolor(['red','green','blue'])
    xyz = ['x','y','z']
    unit = 'mV/m'


    resolution = (keyword_set(resolution))? strlowcase(resolution): 'survey'
    case resolution of
        'hires': dt = 1d/16
        'survey': dt = 11d
        else: begin
            errmsg = handle_error('Unknown resolution: '+resolution+' ...')
            return
            end
    endcase
    times = make_bins(time_range, dt)

    ; Load Q.
    q_var = pre0+'q_uvw2gse'
    if check_if_update(q_var, time_range) then rbsp_read_quaternion, time_range, probe=probe

    ; read 'rbspx_e_gse'
    evar = pre0+'e_gse'
    if resolution eq 'survey' then begin
        rbsp_read_efw, time_range, id='l3%efw', probe=probe, errmsg=errmsg
        if errmsg ne '' then return

        tevar = pre0+'e_mgse'
        get_data, tevar, uts, emgse
        emgse[*,0] = 0
        store_data, tevar, uts, emgse
        add_setting, tevar, /smart, {$
            display_type: 'vector', $
            unit: unit, $
            short_name: 'E', $
            coord: 'mGSE', $
            coord_labels: xyz, $
            colors: rgb}
        emgse = sinterpol(emgse, uts, times)
        egse = cotran(emgse, times, 'mgse2gse', probe=probe)
        store_data, evar, times, egse
    endif else if resolution eq 'hires' then begin
        uvw = ['u','v','w']        
        
    ;---Use spedas, esvy data directly.
        timespan, time_range[0], total(time_range*[-1,1]), /seconds
        rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=time_range
        
        ; Preprocess: remove Ew, remove DC offsets.
        evar_old = pre0+'efw_esvy'
        e_uvw = get_var_data(evar_old, at=times)
        e_uvw[*,2] = 0
        spin_period = 11d
        width = spin_period/dt
        for ii=0,1 do begin
            offset1 = smooth(e_uvw[*,ii], width, /nan, /edge_zero)
            offset2 = smooth(offset1, width, /nan, /edge_zero)
            e_uvw[*,ii] -= offset2
        endfor
        
        evar1 = pre0+'e_uvw'
        store_data, evar1, times, e_uvw
        add_setting, evar1, /smart, {$
            display_type: 'vector', $
            unit: unit, $
            short_name: 'E', $
            coord: 'UVW', $
            coord_labels: constant('uvw')}
        uniform_time, evar1, dt
        del_data, evar_old
        del_data, pre0+'efw_esvy_ccsds_data_'+['BEB','DFB']+'_config'
        
        ; Calc E GSE.
        e_gse = cotran(e_uvw, times, 'uvw2gse', probe=probe)
        store_data, evar, times, e_gse
    endif


    add_setting, evar, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: 'E0', $
        coord: 'GSE', $
        coord_labels: xyz, $
        colors: rgb}

    uniform_time, evar, dt

end

time_range = time_double(['2014-08-28','2014-08-29'])
;rbsp_read_efield, time_range, probe='b'
rbsp_read_efield, time_range, probe='b', resolution='hires'
end

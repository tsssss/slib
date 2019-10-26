;+
; Read RBSP DC E field. Default is to read 'survey mgse' at 11 sec.
;-
;

pro rbsp_read_efield, time_range, probe=probe, resolution=resolution, errmsg=errmsg

    errmsg = ''
    pre0 = 'rbsp'+probe+'_'

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

    rgb = sgcolor(['red','green','blue'])
    xyz = ['x','y','z']
    unit = 'mV/m'

    ; Load Q.
    q_var = pre0+'q_uvw2gsm'
    rbsp_read_quaternion, time_range, probe=probe

    ; read 'rbspx_e_gsm'
    evar = pre0+'e_gsm'
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

        get_data, q_var, uts, quvw2gsm
        quvw2gsm = qslerp(quvw2gsm, uts, times)
        muvw2gsm = qtom(quvw2gsm)
        wsc_gsm = reform(muvw2gsm[*,*,2])
        wsc_gse = cotran(wsc_gsm, times, 'gsm2gse')
        egsm = cotran(emgse, times, wsc=wsc_gse, 'mgse2gsm')

        store_data, evar, times, egsm
    endif else if resolution eq 'hires' then begin
        get_data, q_var, uts, quvw2gsm
        quvw2gsm = qslerp(quvw2gsm, uts, times)
        muvw2gsm = transpose(qtom(quvw2gsm))
        uvw = ['u','v','w']

        ; Load V[1-6].
        boom_lengths = [100d,100,12]    ; in m, twice of boom lengths.
        spin_rate = 12d                 ; sec.

        dat = sread_rbsp_efw_l2(time_range, probes=probe, type='vsvy')
        tuts = sfmepoch(dat.epoch, 'unix')
        vsvy = sinterpol(dat.vsvy, tuts, times)

        ; Calc Vsc.
        tvar = pre0+'vsc'
        vsc = mean(vsvy[*,0:1], dimension=2)
        store_data, tvar, times, vsc, limits={ytitle:'(V)', labels:'Vsc'}

        ; Calc E[uvw].
        tvar = pre0+'e_uvw'
        eu = (vsvy[*,0]-vsvy[*,1])/boom_lengths[0]*1e3   ; V -> V/m -> mV/m.
        ev = (vsvy[*,2]-vsvy[*,3])/boom_lengths[1]*1e3
        ew = dblarr(n_elements(eu))

        ; Remove dc-offset.
        nspin = 1
        width = nspin*spin_rate/dt
        eu = eu-smooth(eu, width, /edge_truncate, /nan)
        ev = ev-smooth(ev, width, /edge_truncate, /nan)
        store_data, tvar, times, [[eu],[ev],[ew]], limits={ytitle:'(mV/m)', labels:'E'+uvw, colors:rgb}

        ; Calc E GSM.
        get_data, pre0+'e_uvw', times, euvw
        euvw[*,2] = 0
        ex = euvw[*,0]*muvw2gsm[0,0,*] + euvw[*,1]*muvw2gsm[1,0,*] + euvw[*,2]*muvw2gsm[2,0,*]
        ey = euvw[*,0]*muvw2gsm[0,1,*] + euvw[*,1]*muvw2gsm[1,1,*] + euvw[*,2]*muvw2gsm[2,1,*]
        ez = euvw[*,0]*muvw2gsm[0,2,*] + euvw[*,1]*muvw2gsm[1,2,*] + euvw[*,2]*muvw2gsm[2,2,*]

        store_data, evar, times, [[ex],[ey],[ez]]
    endif


    add_setting, evar, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: 'E0', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

    uniform_time, evar, dt

end

time_range = time_double(['2014-08-28','2014-08-29'])
rbsp_read_efield, time_range, probe='b'
rbsp_read_efield, time_range, probe='b', resolution='survey'
end

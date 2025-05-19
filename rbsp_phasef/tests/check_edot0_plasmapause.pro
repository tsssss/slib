;+
; Check events of possible plasma flow outside plasmapause.
; 
; Does not follow simple convection pattern.
; Ez positive no matter if the sc are in the southern or northern hemisphere.
; Thus the v = ExB change from eastward to westward (forget which is which) when
; crossing the equator. This seems to be a wake effect problem, because the wake
; flag is mostly on during these orbits.
;-

;---Input.    
    ; a '2014-03-09/02:00'
    ; b '2014-10-30/06:00'
    ; ab '2014-11-25/19:00','2014-11-26/21:00', orbit 1&3 small p/sphere w/ westward convection, 2 large p/sphere w/ eastward convection.
    probe = 'b'
    times = time_double(['2014-11-26/17:00','2013-10-14/16:00','2013-09-17/08:00','2013-02-21/08:00','2013-06-13/04:00','2013-01-02/22:00','2012-12-29/00:00'])

;---Find the orbit.
    prefix = 'rbsp'+probe+'_'
    xyz = constant('xyz')
    min_bw_ratio = 0.2
    fillval = !values.f_nan
    fac = ['b','w','o']

    foreach time, times do begin
        time_range = time+[-1,1]*9*3600
        rbsp_read_orbit, time_range, probe=probe
        dis = snorm(get_var_data(prefix+'r_gse', times=uts))
        min_dis = 3.5
        index = where(dis ge min_dis, count)
        if count eq 0 then message, 'Inconsistency ...'
        time_ranges = uts[time_to_range(index,time_step=1)]
        index = where((time_ranges[*,0]-time)*(time_ranges[*,1]-time) le 0, count)
        if count eq 0 then message, 'Inconsistency ...'
        the_time_range = reform(time_ranges[index,*])
        the_time_range = time_double(['2014-11-23/22:00','2014-11-26/21:00'])

        ; Load Vsc.
        rbsp_efw_read_boom_flag, the_time_range, probe=probe
        ; Load E MGSE.
        pflux_grant_read_e_mgse, the_time_range, probe=probe
        
        ; Load B GSM.
        pflux_grant_read_b_gsm, the_time_range, probe=probe
        rbsp_read_orbit, the_time_range, probe=probe
        
        
;        get_data, prefix+'eu_fixed', uts, eu
;        get_data, prefix+'ev_fixed', uts, ev
;        ew = fltarr(n_elements(uts))
;        e_uvw = [[eu],[ev],[ew]]
;        e_mgse = cotran(e_uvw, uts, 'uvw2mgse', probe=probe)
;        store_data, prefix+'e_mgse', uts, e_mgse
;        interp_time, prefix+'e_mgse', to=prefix+'b_gsm'


        r_gse = get_var_data(prefix+'r_gse', in=the_time_range, times=uts)
        r_sm = cotran(r_gse, uts, 'gse2sm')
        store_data, prefix+'r_sm', uts, r_sm
        add_setting, prefix+'r_sm', /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'R', $
            'unit', 'Re', $
            'coord', 'SM', $
            'coord_labels', xyz )
        dis = snorm(r_gse)
        store_data, prefix+'dis', uts, dis
        add_setting, prefix+'dis', /smart, dictionary($
            'display_type', 'scalar', $
            'short_name', '|R|', $
            'unit', 'Re' )

        b_gsm = get_var_data(prefix+'b_gsm', times=uts)
        b_sm = cotran(b_gsm, uts, 'gsm2sm')
        store_data, prefix+'b_sm', uts, b_sm
        add_setting, prefix+'b_sm', /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'B', $
            'unit', 'nT', $
            'coord', 'SM', $
            'coord_labels', xyz )

        e_mgse = get_var_data(prefix+'e_mgse', times=uts)
        e_sm = cotran(e_mgse, uts, 'mgse2sm', probe=probe)
        store_data, prefix+'e0_sm', uts, e_sm
        add_setting, prefix+'e0_sm', /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'E', $
            'unit', 'mV/m', $
            'coord', 'SM', $
            'coord_labels', xyz )
        
        b_mgse = cotran(b_gsm, uts, 'gsm2mgse', probe=probe)
        e_mgse[*,0] = -(e_mgse[*,1]*b_mgse[*,1]+e_mgse[*,2]*b_mgse[*,2])/b_mgse[*,0]
        bw_ratio = b_mgse[*,0]/snorm(b_mgse)
        index = where(abs(bw_ratio) le min_bw_ratio, count)
        if count ne 0 then e_mgse[index,*] = fillval
        e_sm = cotran(e_mgse, uts, 'mgse2sm', probe=probe)
        store_data, prefix+'edot0_sm', uts, e_sm
        add_setting, prefix+'edot0_sm', /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'E', $
            'unit', 'mV/m', $
            'coord', 'SM', $
            'coord_labels', xyz )
        

        add_setting, prefix+'vsc_median', /smart, dictionary($
            'display_type', 'scalar', $
            'short_name', 'Vsc', $
            'unit', 'V' )
        
;        define_fac, prefix+'b_sm', prefix+'r_sm'
;        foreach var, prefix+['e0_sm','edot0_sm'] do to_fac, var
        

;        ntime = n_elements(uts)
;        ndim = 3
;        b_fac = fltarr(ntime,ndim)
;        b_fac[*,0] = 1/snorm(b_mgse)
;        e_fac = get_var_data(prefix+'edot0_fac')
;        v_fac = vec_cross(e_fac, b_fac)*1e3     ; mV/m/nT = m/s*1e6 = km/s*1e3
;        store_data, prefix+'v_fac', uts, v_fac
;        add_setting, prefix+'v_fac', /smart, dictionary($
;            'display_type', 'vector', $
;            'short_name', 'V', $
;            'unit', 'km/s', $
;            'coord', 'FAC', $
;            'coord_labels', fac )
        

        ndim = 3
        b_sm = get_var_data(prefix+'b_sm')
        e_sm = get_var_data(prefix+'edot0_sm')
        v_sm = vec_cross(e_sm, b_sm)*1e3     ; mV/m/nT = m/s*1e6 = km/s*1e3
        bmag = snorm(b_sm)
        for ii=0,ndim-1 do v_sm[*,ii] /= bmag
        store_data, prefix+'v_sm', uts, v_fac
        add_setting, prefix+'v_sm', /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'V', $
            'unit', 'km/s', $
            'coord', 'SM', $
            'coord_labels', xyz )
        
        
;    ;---Load HOPE velocity.
;        foreach species, ['p','o'] do begin
;            rbsp_read_hope_moments, the_time_range, probe=probe, species=species
;            vel_gsm = get_var_data(prefix+species+'_vbulk', times=uts)
;            vel_sm = cotran(vel_gsm, uts, 'gsm2sm')
;            var = prefix+species+'_vbulk_sm'
;            store_data, var, uts, vel_sm
;            add_setting, var, /smart, dictionary($
;                'display_type', 'vector', $
;                'short_name', strupcase(species)+' V', $
;                'unit', 'km/s', $
;                'coord', 'SM', $
;                'coord_labels', xyz )
;            to_fac, var
;        endforeach

        
;        tplot, prefix+['r_sm','dis','edot0_fac','e_mgse','v_fac','vsc_median'], trange=the_time_range
        tplot, prefix+['r_sm','dis','edot0_sm','e_mgse','v_sm','vsc_median'], trange=the_time_range
        stop
    endforeach

end

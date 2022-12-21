;+
; Use given position and trace it to the ionosphere.
; 
; r_var.
; models=.
; south=.
; north=.
; h0=.
; igrf=.
; t89_use_kp=.
; suffix=.
;-

function geopack_trace_to_ionosphere, r_var, models=models, $
    south=south, north=north, h0=h0, igrf=input_igrf, suffix=the_suffix, $
    _extra=ex

    if n_elements(models) eq 0 then models = ['t89']
    nmodel = n_elements(models)
    colors = get_color(nmodel)
    if n_elements(the_suffix) eq 0 then the_suffix = ''


    get_data, r_var, times, r_coord, limits=lims
    coord = lims.coord
    if strlowcase(coord) ne 'gsm' then begin
        r_gsm = cotran(r_coord, times, 'gsm2'+strlowcase(coord), _extra=ex)
    endif else begin
        r_gsm = temporary(r_coord)
    endelse

    trace_dir = -1  ; -1 is for northern hemisphere.
    if keyword_set(south) then trace_dir = 1
    if keyword_set(north) then trace_dir = -1
    if n_elements(h0) eq 0 then h0 = 100d
    r0 = h0/constant('re')+1
    t89_par = keyword_set(t89_use_kp)? !null: 2

    foreach model, models do begin
        t89 = (model eq 't89')? 1: 0
        t96 = (model eq 't96')? 1: 0
        t01 = (model eq 't01')? 1: 0
        t04s = (model eq 't04s')? 1: 0
        index = strpos(model, 's')
        storm = (index[0] ge 0)? 1: 0
        
        if n_elements(input_igrf) ne 0 then igrf = input_igrf
        if model eq 'igrf' then igrf = 1
        if model eq 'dip' or model eq 'dipole' then igrf = 0

        time_range = minmax(times)
        par_var = geopack_read_par(time_range, model=model, t89_par=t89_par, _extra=ex)
        pars = get_var_data(par_var, at=times)
        ntime = n_elements(times)
        ndim = 3
        f_gsm = fltarr(ntime,ndim)
        bf_gsm = fltarr(ntime,ndim)
        foreach time, times, time_id do begin
            ps = geopack_recalc(time)
            xp = r_gsm[time_id,0]
            yp = r_gsm[time_id,1]
            zp = r_gsm[time_id,2]

            geopack_trace, xp,yp,zp, trace_dir, reform(pars[time_id,*]), $
                xf,yf,zf, r0=r0, refine=1, ionosphere=1, $
                t89=t89, t96=t96, t01=t01, ts04=ts04, storm=storm, igrf=igrf
            f_gsm[time_id,*] = [xf,yf,zf]

            geopack_igrf_gsm, xf,yf,zf, bxf,byf,bzf
            bf_gsm[time_id,*] = [bxf,byf,bzf]
        endforeach

        deg = constant('deg')
        rad = constant('rad')
        f_mag = cotran(f_gsm, times, 'gsm2mag')
        fmlats = asin(f_mag[*,2]/r0)*deg
        fmlons = atan(f_mag[*,1],f_mag[*,0])*deg
        fmlts = mlon2mlt(fmlons, times)

        prefix = get_prefix(r_var)
        suffix = '_'+model
        fmlat_var = prefix+'fmlat'+suffix
        store_data, fmlat_var, times, fmlats
        add_setting, fmlat_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'unit', 'deg', $
            'short_name', 'F/Mlat', $
            'model', model, $
            'r0', r0 )

        fmlon_var = prefix+'fmlon'+suffix
        store_data, fmlon_var, times, fmlons
        add_setting, fmlon_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'unit', 'deg', $
            'short_name', 'F/Mlon', $
            'model', model, $
            'r0', r0 )

        fmlt_var = prefix+'fmlt'+suffix
        store_data, fmlt_var, times, fmlts
        add_setting, fmlt_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'unit', 'h', $
            'short_name', 'F/MLT', $
            'model', model, $
            'r0', r0 )
        
        bf_var = prefix+'bf_gsm_'+model+the_suffix
        store_data, bf_var, times, bf_gsm
        add_setting, bf_var, smart=1, dictionary($
            'display_type', 'vector', $
            'unit', 'nT', $
            'short_name', 'F/B', $
            'model', model, $
            'r0', r0, $
            'coord', 'GSM', $
            'coord_labels', constant('xyz') )
    endforeach
    
    vinfo = dictionary()
    foreach type, ['fmlat','fmlon','fmlt'] do begin
        var = prefix+type+the_suffix
        vars = prefix+type+'_'+models
        vinfo[type] = merge_var(vars, output=var)
        unit = get_setting(var, 'unit')
        add_setting, var, smart=1, dictionary($
            'display_type', 'stack', $
            'ytitle', strupcase(type)+'!C('+unit+')', $
            'labels', strupcase(models) )
        options, var, 'colors', colors
    endforeach

    foreach model, models do begin
        bf_var = prefix+'bf_gsm_'+model+the_suffix
        vinfo[bf_var] = bf_var
    endforeach
    

    return, vinfo

end

time_range = ['2015-02-18','2015-02-19']
probe = 'a'
r_var = rbsp_read_orbit(time_range, probe=probe)
vars = geopack_trace_to_ionosphere(r_var, models=['dip','igrf','t89','t96'],igrf=0)

end
;+
; Use an orbit variable in GSM to get in-situ model B in GSM (T89),
; footpoint in GSM, and mapping factor.
; These variables are saved as prefix_[fpt_gsm,bmod_gsm,c_map]_suffix.
; To replace read_geopack_bfield.
; 
;
; r_var. A string of an orbit variable.
; prefix. A string to be added before variables, e.g., 'rbspb_'. Default
;   behaviour is to figure out from r_var variable.
; igrf=. Boolean, set to use IGRF, otherwise use dipole.
;-

function geopack_read_bfield, time_range, mission_probe=mission_probe, $
    r_var=r_var, errmsg=errmsg, coord=coord, $
    models=models, igrf=igrf, t89_par=t89_par, suffix=input_suffix, $
    _extra=ex

    errmsg = ''
    retval = !null
    coord_orig = 'gsm'

;---Check inputs.
    if n_elements(time_range) eq 1 and size(time_range,type=1) eq 7 then r_var = time_range[0]
    if n_elements(r_var) eq 0 then begin
        pinfo = resolve_probe(mission_probe)
        routine = pinfo['routine_name']+'_read_orbit'
        probe = pinfo['probe']
        r_var = call_function(routine, time_range, probe=probe, coord=coord_orig, get_name=1)
        if check_if_update(r_var, time_range) then begin
            r_var = call_function(routine, time_range, probe=probe, coord=coord_orig)
        endif
    endif
    if tnames(r_var) eq '' then begin
        errmsg = handle_error('Orbit data not found: '+r_var+' ...')
        return, retval
    endif

    prefix = get_prefix(r_var)
    get_data, r_var, times, r_coord
    coord_in = get_setting(r_var, 'coord')
    if strlowcase(coord_in) ne coord_orig then begin
        r_gsm = cotran(r_var, times, strlowcase(coord_in)+'2'+coord_orig, _extra=ex)
    endif else begin
        r_gsm = temporary(r_coord)
    endelse
    if n_elements(time_range) eq 0 then time_range = minmax(times)
    if n_elements(time_range) eq 1 then time_range = minmax(times)
    ndim = 3
    ntime = n_elements(times)

    ; Check mapping model.
    if n_elements(models) eq 0 then models = ['t89']
    if n_elements(coord) eq 0 then coord = coord_orig

    vinfo = dictionary()
    if n_elements(input_suffix) eq 0 then input_suffix = ''
    foreach model, models do begin
        index = where(model eq ['dip','dipole','igrf','t89','t96','t01','t04s'], count)
        if count eq 0 then continue
        suffix = '_'+model+input_suffix
        
        tmp = geopack_resolve_model(model)
        t89 = tmp.t89
        t96 = tmp.t96
        t01 = tmp.t01
        ts04 = tmp.ts04
        storm = tmp.storm

        par_var = geopack_read_par(time_range, model=model, t89_par=t89_par)
        pars = get_var_data(par_var, at=times)
        b0gsm = fltarr(ntime,ndim)
        foreach time, times, time_id do begin
            ps = geopack_recalc(time)
            rx = r_gsm[time_id,0]
            ry = r_gsm[time_id,1]
            rz = r_gsm[time_id,2]
            par = reform(pars[time_id,*])

            if keyword_set(igrf) then begin
                geopack_igrf_gsm, rx,ry,rz, bx,by,bz
            endif else begin
                geopack_dip, rx,ry,rz, bx,by,bz
            endelse

            if model eq 'dip' or model eq 'dipole' or model eq 'igrf' then begin
                dbx = 0
                dby = 0
                dbz = 0
            endif else begin
                routine = 'geopack_'+model
                if model eq 't04s' then routine = 'geopack_ts04'
                call_procedure, routine, par, rx,ry,rz, dbx,dby,dbz
            endelse
            b0gsm[time_id,*] = [bx,by,bz]+[dbx,dby,dbz]
        endforeach

        if coord ne coord_orig then begin
            b0_coord = cotran(b0gsm, times, coord_orig+'2'+coord, _extra=ex)
        endif else begin
            b0_coord = temporary(b0gsm)
        endelse
        bmod_var = prefix+'bmod_'+coord+suffix
        store_data, bmod_var, times, b0_coord
        add_setting, bmod_var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(model)+' B', $
            'unit', 'nT', $
            'coord', strupcase(coord), $
            'coord_labels', constant('xyz'), $
            'model', model )
        
        vinfo[model] = bmod_var
    endforeach


    if n_elements(models) eq 1 then return, (vinfo.values())[0]
    return, vinfo
end



time_range = time_double(['2014-08-28/10:00','2014-08-28/11:00'])
models = ['igrf']
var = geopack_read_bfield(time_range, mission_probe='tha', models=models, t89_par=2)

end

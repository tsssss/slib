;+
; Read par for given model.
;-

function geopack_read_par, input_time_range, model=model, get_name=get_name, $
    t89_par=t89_par
    

    if n_elements(model) eq 0 then model = 't89'
    par_var = model+'_par'
    if keyword_set(get_name) then return, par_var

    tr = time_double(input_time_range)
    if model eq 't89' then begin
        if n_elements(t89_par) ne 0 then begin
            store_data, par_var, tr, [0,0]+t89_par
            return, par_var
        endif else begin
            return, rename_var(read_kp(tr), output=par_var)
        endelse
    endif

    if model eq 'dip' or model eq 'dipole' or model eq 'igrf' then begin
        store_data, par_var, tr, [0,0]
        return, par_var
    endif

    
    time_range = time_double(input_time_range)
    sw_b_var = omni_read_sw_b(time_range, coord='gsm')
    sw_n_var = omni_read_sw_n(time_range)
    sw_v_var = omni_read_sw_v(time_range, coord='gsm')
    dst_var = omni_read_symh(time_range)
;    foreach var, [sw_b_var,sw_n_var,sw_v_var] do begin
;        tdegap, var, overwrite=1
;        tdeflag, var, 'linear', overwrite
;    endforeach

    imf_var = sw_b_var+'_yz'
    get_data, sw_b_var, times, sw_b
    imf_vars = sw_b_var+'_'+['y','z']
    foreach var, imf_vars, ii do store_data, var, times, sw_b[*,ii+1]
    store_data, imf_var, data=imf_vars

    vp_var = sw_v_var+'_mag'
    get_data, sw_v_var, times, sw_v
    store_data, vp_var, times, snorm(sw_v)

    get_tsy_params, dst_var, imf_var, sw_n_var, vp_var, model, speed=1, imf_yz=1, trange=time_range

    get_data, par_var, times, pars
    ntime = n_elements(times)
    ndim = n_elements(pars)/ntime
    for ii=0,ndim-1 do begin
        index = where(finite(pars[*,ii],nan=1), count, complement=index2)
        if count eq 0 then continue
        pars[*,ii] = interpol(pars[index2,*],times[index2], times)
    endfor
    store_data, par_var, times, pars
    add_setting, par_var, smart=1, dictionary($
        'display_type', 'stack', $
        'labels', string(findgen(ndim),format='(I0)'), $
        'ytitle', strupcase(model)+' Par' )

    return, par_var

end


time_range = ['2019-01-01','2019-01-02']
foreach model, ['t89','dip','igrf','t96','t01','t04s'] do begin
    var = geopack_read_par(time_range, model=model)
    stop
endforeach
end
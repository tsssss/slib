;+
; Read B model (IGRF, dipole, T89)
;
; rbspx_b_mgse_[dipole,igrf,t89]
;-

pro rbsp_efw_phasef_read_b_model, time_range, probe=probe


;---Check inputs.
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time_range) ne 2 then begin
        errmsg = handle_error('No input time ...')
        return
    endif


;---Constants and settings.
    secofday = 86400d
    errmsg = ''
    models = ['dipole','igrf','t89']

    prefix = 'rbsp'+probe+'_'
    time_step = 60.
    common_times = make_bins(time_range, time_step)
    ntime = n_elements(common_times)

;---Load orbit.
    rbsp_efw_phasef_read_pos_var, time_range, probe=probe
    r_gse_var = prefix+'r_gse'
    interp_time, r_gse_var, common_times
    r_gse = get_var_data(r_gse_var)
    r_gsm = cotran(r_gse, common_times, 'gse2gsm')

    ndim = 3
    b_dip_gsm = fltarr(ntime,ndim)
    b_igrf_gsm = fltarr(ntime,ndim)
    db_t89_gsm = fltarr(ntime,ndim)
    par = 2.
    foreach time, common_times, time_id do begin
        tilt = geopack_recalc(time)

        rx = r_gsm[time_id,0]
        ry = r_gsm[time_id,1]
        rz = r_gsm[time_id,2]

        geopack_dip, rx,ry,rz, bx,by,bz
        b_dip_gsm[time_id,*] = [bx,by,bz]
        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        b_igrf_gsm[time_id,*] = [bx,by,bz]
        geopack_t89, par, rx,ry,rz, dbx,dby,dbz
        db_t89_gsm[time_id,*] = [dbx,dby,dbz]
    endforeach

    b_dip_mgse = cotran(b_dip_gsm, common_times, 'gsm2mgse', probe=probe)
    store_data, prefix+'b_mgse_dipole', common_times, b_dip_mgse
    b_igrf_mgse = cotran(b_igrf_gsm, common_times, 'gsm2mgse', probe=probe)
    store_data, prefix+'b_mgse_igrf', common_times, b_igrf_mgse
    b_t89_gsm = b_igrf_gsm+db_t89_gsm
    b_t89_mgse = cotran(b_t89_gsm, common_times, 'gsm2mgse', probe=probe)
    store_data, prefix+'b_mgse_t89', common_times, b_t89_mgse

end

time_range = time_double(['2013-06-07','2013-06-08'])
probe = 'a'
rbsp_efw_phasef_read_b_model, time_range, probe=probe
rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
end
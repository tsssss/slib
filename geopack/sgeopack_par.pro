
pro sgeopack_par, tr, model0, delete = delete

    ; which model?
    model = model0[0]
    if model eq 't89' then begin
        store_data, model0+'_par', tr, [2,2]
        return
    endif
    if model eq 'dip' then begin
        store_data, model0+'_par', tr, [0,0]
        return
    endif
    if model eq 'igrf' then begin
        store_data, model0+'_par', tr, [0,0]
        return
    endif
    if model eq '' then return

    ;dat = sread_omni(tr)
    omni_read, tr, id='sw'
    omni_read, tr, id='ae_dst'
    
    dst_var = 'dst'
    imf_var = 'imf_b_gsm'
    np_var = 'n'
    vp_var = 'vx_gse'
    
	vars = ['by_gsm','bz_gsm','vx_gse','n']
	nvar = n_elements(vars)
	for i = 0, nvar-1 do begin
		tdegap, vars[i], /overwrite
		tdeflag, vars[i], 'linear', /overwrite
    endfor
	store_data, imf_var, data=['by_gsm','bz_gsm']
	get_tsy_params, dst_var, imf_var, np_var, vp_var, $
		model, /speed, /imf_yz, trange = tr

    the_var = model+'_par'
    get_data, the_var, times, par
    index = where(finite(par,/nan), count)  ; NaN in par causes db[xyz] to be NaN
    if count ne 0 then begin
        par[index] = 0
        store_data, the_var, times, par
    endif

;	; set original time range back.
;	timespan, tr[0], tr[1]-tr[0], /second

  ; delete the vars.
  if keyword_set(delete) then store_data, pre0+'*', /delete
  
end

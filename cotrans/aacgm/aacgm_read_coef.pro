;+
; Read coef for conversion b/w aacgm and geo.
; This is coefs_v2.
;-

function aacgm_read_coef, coef_path=coef_path, get_name=get_name, errmsg=errmsg

    errmsg = ''
    retval = ''
    

    aacgm_coef_var = 'aacgm_coef'
    if keyword_set(get_name) then return, aacgm_coef_var
    if ~check_if_update(aacgm_coef_var) then return, aacgm_coef_var
    

    if n_elements(coef_path) eq 0 then coef_path = join_path([srootdir(),'coeffs'])
    coef_files = file_search(coef_path, 'aacgm_coeffs-13-*.asc')
    
    
    ntime = n_elements(coef_files)
    order = aacgm_default_order()
    kmax = (order+1)^2  ; kmax_v2
    ncoord = 3    ; xyz
    nquart = 5    ; quartic altitude fit coefficients
    times = dblarr(ntime)
    coef_aacgm2geo = dblarr(ntime,kmax,ncoord,nquart)
    coef_geo2aacgm = dblarr(ntime,kmax,ncoord,nquart)

    nflag  = 2    ; 0: GEO->AACGM; 1: AACGM->GEO
    buffer = dblarr(kmax,ncoord,nquart,nflag)
    foreach file, coef_files, file_id do begin
        if file_test(file) eq 0 then begin
            errmsg = 'File does not exist: '+file+' ...'
            return, retval
        endif
        openr, lun, file, get_lun=1, stdio=1
        readf, lun, buffer
        free_lun, lun

        base = fgetbase(file)   ; aacgm_coeffs-13-1590.asc.
        year_str = (strsplit(base,'-.',extract=1))[2]
        times[file_id] = time_double(year_str)
        coef_aacgm2geo[file_id,*,*,*] = buffer[*,*,*,1]
        coef_geo2aacgm[file_id,*,*,*] = buffer[*,*,*,0]
    endforeach

    aacgm_coef_info = dictionary($
        'aacgm2geo', coef_aacgm2geo, $
        'geo2aacgm', coef_geo2aacgm )
    store_data, aacgm_coef_var, times, aacgm_coef_info
    return, aacgm_coef_var


end

aacgm_coef_var = aacgm_read_coef()
end
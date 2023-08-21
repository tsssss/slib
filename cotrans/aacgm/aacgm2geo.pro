;+
; Convert r_aacgm to r_geo (geocentric in Re).
; Note: only glat and glon are obtained. dis is just 1.
;-

function aacgm2geo, r_aacgm, times


    aacgm_coef_var = aacgm_read_coef()
    coef_v2 = (get_var_data(aacgm_coef_var, times=coef_times))['aacgm2geo']
    ; dims are [time,kmax,ncoord,nquat]
    coef_v2 = sinterpol(coef_v2, coef_times, times)
    dims = size(coef_v2, dimensions=1)
    ntime = dims[0]
    kmax = dims[1]
    ncoord = dims[2]
    nquart = dims[2]

    re = constant('re')
    deg = constant('deg')
    rad = constant('rad')
    dis = snorm(r_aacgm)
    mlat = asin(r_aacgm[*,2]/dis)*deg
    mlon = atan(r_aacgm[*,1],r_aacgm[*,0])*deg

    alts = (dis-1)*re
    alt_var = alts/2000.0   ; [ncoord]
    alt_var = alt_var # (dblarr(kmax*ncoord)+1) ; [ntime,kmax*ncoord]

    nquart = n_elements(coef_v2[0,0,0,*])
    coef_v2 = reform(coef_v2,[ntime,kmax*ncoord,nquart])
    ;cint_v2 = dblarr([ntime,kmax*ncoord])
    ;for ii=0,nquart-1 do cint_v2 += coef_v2[*,*,ii]*alt_var^ii
    cint_v2 = coef_v2[*,*,nquart-1]   ; [ntime,kmax,ncoord]
    for ii=nquart-2,0,-1 do begin
        cint_v2 = cint_v2*alt_var+coef_v2[*,*,ii]
    endfor
    cint_v2 = reform(cint_v2,[ntime,kmax,ncoord])
    coef_v2 = reform(coef_v2,[ntime,kmax,ncoord,nquart])

    

    order = sqrt(kmax)-1
    ylmval = aacgm_calc_rylm(mlat,mlon,order=order, degree=1) ; [ntime,kmax]

    
    r_geo = dblarr(ntime,ncoord)
    for ii=0,ncoord-1 do r_geo[*,ii] = total(ylmval*cint_v2[*,*,ii],2)
    
    
    glat = asin(r_geo[*,2])*deg
    glon = atan(r_geo[*,1],r_geo[*,0])*deg
    dis = snorm(r_geo)
    stop
    
    return, r_geo
    
end
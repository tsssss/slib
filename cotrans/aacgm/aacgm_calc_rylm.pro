;+
; This is adopted from aacgm_v2_rylm.
; Here glat and glon can be an array [n]. Returned value is in [n,k], k=(order+1)^2.
;-
function aacgm_calc_rylm, glat, glon, order=order, degree=degree

    if keyword_set(degree) then begin
        rad = constant('rad')
        colat = (90-glat)*rad
        lon = glon*rad
    endif else begin
        colat = 0.5*!dpi-glat
        lon = glon
    endelse

    cos_theta = cos(colat)
    sin_theta = sin(colat)
    cos_lon = cos(lon)
    sin_lon = sin(lon)

    d1 = -sin_theta
    z2 = dcomplex(cos_lon,sin_lon)
    z1 = d1*z2
    q_fac = z1

    ; Generate Zonal Harmonics (P_l^(m=0) for l = 1,order) using recursion
    ; relation (6.8.7), p. 252, Numerical Recipes in C, 2nd. ed., Press. W.
    ; et al. Cambridge University Press, 1992) for case where m = 0.
    ;
    ; l Pl = cos(theta) (2l-1) Pl-1 - (l-1) Pl-2          (6.8.7)
    ;
    ; where Pl = P_l^(m=0) are the associated Legendre polynomials
    ntime = n_elements(glat)
    if n_elements(order) eq 0 then order = aacgm_default_order()
    kmax = (order+1)^2
    ylmval = fltarr(ntime,kmax)
    ylmval[*,0] = 1.d         ; l = 0, m = 0
    ylmval[*,2] = cos_theta   ; l = 1, m = 0

    for l=2,order do begin
    ; indices for previous two values: k = l * (l+1) + m with m=0
        ia = (l-2)*(l-1)
        ib = (l-1)*l
        ic = l * (l+1)
        ylmval[*,ic] = (cos_theta*(2*l-1)* ylmval[*,ib] - (l-1)* ylmval[*,ia])/l
    endfor

    ; Generate P_l^l for l = 1 to (order+1)^2 using algorithm based upon (6.8.8)
    ; in Press et al., but incorporate longitude dependence, i.e., sin/cos (phi)
    ;
    ; Pll = (-1)^l (2l-1)!! (sin^2(theta))^(l/2)
    ;
    ; where Plm = P_l^m are the associated Legendre polynomials
    q_val = q_fac
    ylmval[*,3] = double(q_val)       ; l = 1, m = +1
    ylmval[*,1] = -imaginary(q_val)   ; l = 1, m = -1
    for l=2,order do begin
        d1 = l*2-1.
        z2 = d1*q_fac
        z1 = z2*q_val
        q_val = z1

        ; indices for previous two values: k = l * (l+1) + m
        ia = l*(l+2)    ; m = +l
        ib = l*l        ; m = -l

        ylmval[*,ia] = double(q_val)
        ylmval[*,ib] = -imaginary(q_val)
    endfor

    ; Generate P_l,l-1 to P_(order+1)^2,l-1 using algorithm based upon (6.8.9)
    ; in Press et al., but incorporate longitude dependence, i.e., sin/cos (phi)
    ;
    ; Pl,l-1 = cos(theta) (2l-1) Pl-1,l-1
    for l=2,order do begin
        l2 = l*l
        tl = 2*l
        ; indices for Pl,l-1; Pl-1,l-1; Pl,-(l-1); Pl-1,-(l-1)
        ia = l2 - 1
        ib = l2 - tl + 1
        ic = l2 + tl - 1
        id = l2 + 1

        fac = tl - 1
        ylmval[*,ic] = fac*cos_theta* ylmval[*,ia]     ; Pl,l-1
        ylmval[*,id] = fac*cos_theta* ylmval[*,ib]     ; Pl,-(l-1)
    endfor

    ; Generate remaining P_l+2,m to P_(order+1)^2,m for each m = 1 to order-2
    ; using algorithm based upon (6.8.7) in Press et al., but incorporate
    ; longitude dependence, i.e., sin/cos (phi).
    ;
    ; for each m value 1 to order-2 we have P_mm and P_m+1,m so we can compute
    ; P_m+2,m; P_m+3,m; etc.
    for m=1,order-2 do begin
        for l=m+2,order do begin
            ca = double(2.*l-1)/(l-m)
            cb = double(l+m-1.)/(l-m)

            l2 = l*l
            ic = l2 + l + m
            ib = l2 - l + m
            ia = l2 - l - l - l + 2 + m
            ; positive m
            ylmval[*,ic] = ca*cos_theta* ylmval[*,ib] - cb* ylmval[*,ia]

            ic -= (m+m)
            ib -= (m+m)
            ia -= (m+m)
            ; negative m
            ylmval[*,ic] = ca*cos_theta* ylmval[*,ib] - cb* ylmval[*,ia]
        endfor
    endfor

    ; Normalization added here (SGS)
    ;
    ; Note that this is NOT the standard spherical harmonic normalization factors
    ;
    ; The recursive algorithms above treat positive and negative values of m in
    ; the same manner. In order to use these algorithms the normalization must
    ; also be modified to reflect the symmetry.
    ;
    ; Output values have been checked against those obtained using the internal
    ; IDL legendre() function to obtain the various associated legendre
    ; polynomials.
    ;
    ; As stated above, I think that this normalization may be unnecessary. The
    ; important thing is that the various spherical harmonics are orthogonal,
    ; rather than orthonormal.
    fact = factorial(indgen(2*order+1))
    ffff = dblarr((order+1)*(order+1))
    for l=0,order do begin
        for m=0,l do begin
            k = l * (l+1) + m         ; 1D index for l,m
            ffff[k] = sqrt((2*l+1)/(4*!dpi) * fact[l-m]/fact[l+m])
        endfor
        for m=-l,-1 do begin
            k = l * (l+1) + m         ; 1D index for l,m
            kk = l * (l+1) - m
            ffff[k] = ffff[kk] * (-1)^(-m mod 2)
        endfor
    endfor


    return, ylmval*((dblarr(ntime)+1) # ffff)

end

glat = 50.
glon = 120.
order = 10

rad = constant('rad')
colat = (90-glat)*rad
lon = glon*rad
aacgmidl
aacgmlib_v2
AACGM_v2_Rylm, colat, lon, order, ylmval2
AACGM_v2_Rylm, colat, lon+10*rad, order, ylmval3
ylmval1 = aacgm_calc_rylm(glat+[0,0], glon+[0,10], order=order, degree=1)
print, minmax(ylmval1[0,*]-ylmval2)
print, minmax(ylmval1[1,*]-ylmval3)
end
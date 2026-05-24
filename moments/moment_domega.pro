;+
; Adopted from moments_3d_omega_weights.pro and smom3d_domega.pro.
;
; theta. latitudinal angle in deg, should be in [-90,90].
; phi. azimuthal angle in deg.
; dtheta. width of the latitudinal angle in deg.
; dphi. width of the azimuthal angle in deg.
;-
function moment_domega, theta, phi, dtheta, dphi, order=order

    ; Internal function to calculate the angular integration weights.
    dims = size(theta,/dimensions)
    omega = dblarr([13,dims])
    domega = dblarr([4,dims])

    deg = 180d/!dpi
    rad = !dpi/180d

    th = theta*rad
    ph = phi*rad
    dth = dtheta*rad
    dph = dphi*rad

    cth = cos(th)
    sth = sin(th)
    cph = cos(ph)
    sph = sin(ph)


;---The angular integration weights.
    ; For dv^3 = v^2*dv * cos(th)*dth*dph.
    d0 = cth*dth*dph

    ; x_hat = cos(th)*cos(ph)
    ; y_hat = cos(th)*sin(ph)
    ; z_hat = sin(th)
    x0 = cth*cph        ; v*cos(th)*cos(ph).
    y0 = cth*sph        ; v*cos(th)*sin(ph).
    z0 = sth            ; v*sin(th).

    ; moments_3d_omega_weights has other terms.
    ; They can be derived from the above basic terms.
    domega[0,*,*,*] = d0
    domega[1,*,*,*] = x0
    domega[2,*,*,*] = y0
    domega[3,*,*,*] = z0

    return, domega


end
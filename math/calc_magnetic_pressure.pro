;+
; Calculate magnetic pressure, in nPa.
;
; b_vec. In nT.
;-

function calc_magnetic_pressure, b_vec

    bmag = snorm(b_vec)*1e-9    ; nT to T.
    mu0 = constant('mu0')       ; N/A^2.
    cc = 1e9                    ; Pa to nPa.
    return, bmag^2/(2*mu0)*cc

end
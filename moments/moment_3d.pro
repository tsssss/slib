

function moment_3d, diff_energy_fluxs, $
    energy_bins, denergy_bins, $
    phi_angles, dphi_angles, $
    theta_angles, dtheta_angles, $
    vsc=vsc, energy_range=energy_range

;---Constants.
    mass_h = 1.67d-27   ; kg.
    q_e = 1.6d-19       ; Coulume.
    idx6 = [0,4,8,1,2,5]    ; map from matrix[3x3] to vec[6].
    idx3x3 = [[0,3,4],[3,1,5],[4,5,2]]  ; from vec[6] to matrix[3x3].
    deg = 180d/!dpi
    rad = !dpi/180d


;---The differential energy fluxs.
    f_E = diff_energy_fluxs   ; in eV/cm^2-eV-sr-s.
    index = where(finite(f_E,nan=1), count)
    if count ne 0 then f_E[index] = 0d

;---Energy bins and related.
    e0s = energy_bins   ; E, energy bins in eV.
    index = where(e0s le 0, count)
    if count ne 0 then e0s = e0s>0.1
    nenergy_bin = n_elements(e0s)

    if n_elements(denergy_bins) eq 0 then begin
        de_e = abs(shift(e0s,1)-shift(e0s,-1))*0.5/e0s
        de_e[0] = de_e[1]
        de_e[nenergy_bin-1] = de_e[nenergy_bin-2]
        des = de_e*e0s
    endif else begin
        des = denergy_bins
        de_e = des/e0s
    endelse
    e1s = e0s+vsc*q_e*1e6/mass_h    ; E after sc potential correction.
    vsc_weight = 0d> (e0s+vsc*q_e*1e6/mass_h)/des+0.5 <1d

    if n_elements(energy_range) eq 2 then begin   ; energy range in eV.
        index = where(e0s lt energy_range[0] or e0s gt energy_range[1], count)
        if count ne 0 then f_E[index] = 0d
    endif

    ; Imply the vsc_weight to de_e.
    de_e = de_e*vsc_weight





    domega_info = moment_domega(theta, phi, dtheta, dphi)
    domega = domega_info[0,*,*]
    x_hat = domega_info[1,*,*]
    y_hat = domega_info[2,*,*]
    z_hat = domega_info[3,*,*]



end
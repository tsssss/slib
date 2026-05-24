;+
; :Purpose: Combine positions.
; :Returns: [4]. The combined position.
; :Arguments:
;   pos: in, required, number in [4,*].
;-

function combine_pos, pos
    compile_opt idl2

    ndim = 4
    npanel = n_elements(pos)/ndim
    panel_poss = reform(pos,[ndim,npanel])
    plot_pos = dblarr(ndim)
    foreach ii, [0,1] do plot_pos[ii] = min(panel_poss[ii,*])
    foreach ii, [2,3] do plot_pos[ii] = max(panel_poss[ii,*])
    return, plot_pos

end
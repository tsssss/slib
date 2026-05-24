;+
; :Returns: [4]. Position
; :Arguments:
;   pos: in, required, position of the panel.
;   rel_pos: in, optional, str.
;       'right','left','above','below'. By default is 'right'.
;-

function calc_cbpos, pos, rel_pos, yshift=yshift, xshift=xshift
    compile_opt idl2

    if n_elements(rel_pos) eq 0 then rel_pos = 'right'
    tmp = get_charsize()
    xchsz = tmp[0]
    ychsz = tmp[1]

    plot_pos = combine_pos(pos)
    cbpos = plot_pos
    if rel_pos eq 'right' then begin
        cbpos[0] = plot_pos[2]+xchsz*0.7
        cbpos[2] = cbpos[0]+xchsz*0.7
    endif

    if rel_pos eq 'left' then begin
        cbpos[2] = plot_pos[0]-xchsz*0.7
        cbpos[0] = cbpos[2]-xchsz*0.7
    endif

    if rel_pos eq 'above' then begin
        cbpos[1] = plot_pos[3]+ychsz*0.5
        cbpos[3] = cbpos[1]+ychsz*0.5
    endif

    if rel_pos eq 'below' then begin
        cbpos[3] = plot_pos[1]-ychsz*0.5
        cbpos[1] = cbpos[3]-ychsz*0.5
    endif
  
    if n_elements(yshift) eq 0 then yshift = 0
    if n_elements(xshift) eq 0 then xshift = 0
    cbpos[[0,2]] = cbpos[[0,2]]+xshift
    cbpos[[1,3]] = cbpos[[1,3]]+yshift

    return, cbpos
end

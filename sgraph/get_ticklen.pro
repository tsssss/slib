;+
; Given a position in normalized unit, return the ticklen.
;-

function get_ticklen, tpos

    chsz = get_charsize()
    abs_ticklen = -!d.y_ch_size*0.3      ; in device unit.

    ; normalize to axis.
    xaxis_len = (tpos[2]-tpos[0])*!d.x_size
    yaxis_len = (tpos[3]-tpos[1])*!d.y_size
    ; xtick is along y.
    xticklen = abs_ticklen/yaxis_len
    ; ytick is along x.
    yticklen = abs_ticklen/xaxis_len

    return, [xticklen,yticklen]

end
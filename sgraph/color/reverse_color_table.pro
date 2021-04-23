;+
; Reverse the current loaded color table.
;-
pro reverse_color_table

    tvlct, rr, gg, bb, /get
    tvlct, reverse(rr), reverse(gg), reverse(bb)

end
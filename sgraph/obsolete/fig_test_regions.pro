;+
; Plot to test regions.
;-

pro fig_test_regions, fig

    pos_list = fig_calc_region_pos(fig)
    xstyle = 5
    ystyle = 5

    sgopen, 0, xsize=fig.xsize, ysize=fig.ysize, /inch
    foreach tpos, pos_list do begin
        plot, [0,1],[0,1], $
            xstyle=xstyle, ystyle=ystyle, $
            position=tpos, nodata=1, noerase=1
    endforeach

end

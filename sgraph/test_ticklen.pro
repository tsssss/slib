;+
;-

xticklen = -0.02
yticklen = -0.02

sgopen, 0, xsize=4, ysize=4, xchsz=xchsz, ychsz=ychsz
tpos = [0.2,0.2,0.9,0.9]
plot, [0,1], [0,1], $
    xstyle=1, ystyle=1, nodata=1, noerase=1, position=tpos, $
    xticklen=xticklen, yticklen=yticklen
sgclose


sgopen, 1, xsize=4, ysize=8, xchsz=xchsz, ychsz=ychsz
tpos = [0.2,0.2,0.9,0.9]
plot, [0,1], [0,1], $
    xstyle=1, ystyle=1, nodata=1, noerase=1, position=tpos, $
    xticklen=xticklen, yticklen=yticklen
sgclose


sgopen, 2, xsize=8, ysize=4, xchsz=xchsz, ychsz=ychsz
tpos = [0.2,0.2,0.9,0.9]
plot, [0,1], [0,1], $
    xstyle=1, ystyle=1, nodata=1, noerase=1, position=tpos, $
    xticklen=xticklen, yticklen=yticklen
sgclose


end
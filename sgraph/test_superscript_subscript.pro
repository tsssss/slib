;+
; U and D pairs are larger but too shifted.
; I and E paris are properly positioned but too small.
;-

test = 0


plot_file = join_path([srootdir(),'test_superscript_subscript.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, size=[2.5,4.5], xchsz=xchsz, ychsz=ychsz

charsize = 3
dx = xchsz*charsize*4
dy = ychsz*charsize*1.2

sub = tex2str('perp')+',west'
tx = xchsz*charsize
ty = ychsz*charsize
xyouts, tx, ty, normal=1, 'E!D'+sub, charsize=charsize
xyouts, tx, ty+dy, normal=1, 'E!I'+sub, charsize=charsize
xyouts, tx+dx, ty, normal=1, 'E!I'+sub, charsize=charsize

sup = '-2'
tx = xchsz*charsize
ty = ychsz*charsize*4
xyouts, tx,ty, normal=1, 'E!U'+sup, charsize=charsize
xyouts, tx+dx,ty, normal=1, 'E!E'+sup, charsize=charsize
xyouts, tx,ty+dy, normal=1, 'E!E'+sup, charsize=charsize


tx = xchsz*charsize
ty = ychsz*charsize*7
xyouts, tx,ty, normal=1, 'E!S!U'+sup+'!R!D'+sub, charsize=charsize
xyouts, tx+dx,ty, normal=1, 'E!S!E'+sup+'!R!I'+sub, charsize=charsize
xyouts, tx,ty+dy, normal=1, 'E!S!E'+sup+'!R!I'+sub, charsize=charsize

if keyword_set(test) then stop
sgclose

end
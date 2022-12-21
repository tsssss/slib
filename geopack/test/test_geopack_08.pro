;+
; test geopack_08
;-

deg = 180d/!dpi
rad = !dpi/180
re = 6378d & re1 = 1d/re
alt = 100   ; km.
r0 = 1+alt*re1

model0 = 't08'
t08 = 1

tplot_options, 'labflag', -1
tplot_options, 'ynozero', 1
tplot_options, 'ystyle', 1
tplot_options, 'symsize', 0.2

pre0 = ''
posvar = pre0+'pos_gsm'
coord0 = 'gsm'

; **** load pos.
; make up 2 hour of data.
dr = 60
nrec = 2*3600/dr

uts = time_double('2013-01-01/00:00')+smkarthm(0,dr,nrec,'x0')
utr = minmax(uts)
ets = uts*1d3 + 62167219200000d  ; epoch time.


xgsms = smkarthm(-4.8,-4.5,nrec,'n')
ygsms = dblarr(nrec)
zgsms = smkarthm(1,2,nrec,'n')
;zgsms = dblarr(nrec)
posgsms = [[xgsms],[ygsms],[zgsms]]

store_data, posvar, uts, posgsms, limits = $
    {ytitle:'R GSM!C(Re)', labels:['X','Y','Z']+' GSM', colors:[6,4,2]}


; **** ideal dipole position.
ilats = dblarr(nrec)
for j = 0, nrec-1 do begin
    tet = ets[j]
    geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
    
    xp = posgsms[j,0] & yp = posgsms[j,1] & zp = posgsms[j,2]
    geopack_conv_coord, xp,yp,zp, /from_gsm, txp,typ,tzp, /to_mag, epoch = tet
    lshell = (txp^2+typ^2+tzp^2)^1.5/(txp^2+typ^2)
    ilats[j] = acos(1d/sqrt(lshell))*deg
endfor
store_data, pre0+'ilat', uts, ilats, $
    limits = {ytitle:'ILat!C(deg)'}


; **** sawteeth in original geopack.
model = 't08'
dir = -1    ; -1 for parallel to B.
    
fptzgsms = dblarr(nrec)
fptmlats = dblarr(nrec)


for j = 0, n_elements(uts)-1 do begin
    tet = ets[j]
    par = dblarr(10)    ; dummy input. check get_tsy_params.pro and manual.
    geopack_epoch, tet, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    geopack_recalc_08, yr, mo, dy, hr, mi, sc+msc*0.001d, /date

    xp = posgsms[j,0] & yp = posgsms[j,1] & zp = posgsms[j,2]
    geopack_trace_08, xp, yp, zp, dir, par, xf, yf, zf, r0 = r0, $
        epoch = tet, /refine, /ionosphere, $
        igrf = igrf, t89 = t89, t96 = t96, t01 = t01, ts04 = ts04, storm = storm
        
    ; convert from gsm to mag.
    geopack_recalc, yr, mo, dy, hr, mi, sc+msc*0.001d, /date
    geopack_conv_coord, xf,yf,zf, /from_gsm, txf,tyf,tzf, /to_mag, epoch = tet
    fptmlats[j] = asin(tzf/r0)*deg
    
    fptzgsms[j] = zf
endfor
store_data, pre0+'fpt_rz_gsm_'+model, uts, fptzgsms, $
    limits = {ytitle:'Fpt Z GSM!C(Re)', labels:strupcase(model)}
store_data, pre0+'fpt_mlat_'+model, uts, fptmlats, $
    limits = {ytitle:'Fpt MLat!C(deg)', labels:strupcase(model)}

tplot, ['ilat',pre0+'fpt_mlat_'+model]

end

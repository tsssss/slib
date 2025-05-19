;+
; Check the data Solene sent.
;-

time_range = time_double(['2013-06-19/09:50','2013-06-19/10:20'])
file = join_path([homedir(),'Downloads','B_ExBGSE_0andT_BGSE_SCPOT_XGSE_VGSE_130619.txt'])
date = strmid(file_basename(file),36,6)
probe = strlowcase(strmid(file_basename(file),0,1))
prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')

data = (read_ascii(file)).(0)
time0 = time_double(date,tformat='yyMMDD')
times = reform(data[0,*])+time0
ntime = n_elements(times)
ndim = 3
b_gse = fltarr(ntime,ndim)
for ii=0,ndim-1 do b_gse[*,ii] = reform(data[7+ii,*])
store_data, prefix+'b_solene_gse', times, b_gse
add_setting, prefix+'b_solene_gse', /smart, dictionary($
    'display_type', 'vector', $
    'unit', 'nT', $
    'short_name', 'B', $
    'coord', 'Solene GSE', $
    'coord_labels', xyz )
store_data, prefix+'bmag_solene', times, snorm(b_gse)
    
v_gse = fltarr(ntime,ndim)
for ii=0,ndim-1 do v_gse[*,ii] = reform(data[14+ii,*])
store_data, prefix+'v_solene_gse', times, v_gse
add_setting, prefix+'v_solene_gse', /smart, dictionary($
    'display_type', 'vector', $
    'unit', 'km/s', $
    'short_name', 'V', $
    'coord', 'GSE', $
    'coord_labels', xyz )
    
re1 = 1d/constant('re')
r_gse = fltarr(ntime,ndim)
for ii=0,ndim-1 do r_gse[*,ii] = reform(data[11+ii,*])*re1
store_data, prefix+'r_solene_gse', times, r_gse
add_setting, prefix+'r_solene_gse', /smart, dictionary($
    'display_type', 'vector', $
    'unit', 'Re', $
    'short_name', 'R', $
    'coord', 'Solene GSE', $
    'coord_labels', xyz )
    
    
rbsp_read_emfisis, time_range, probe=probe, id='l3%magnetometer', resolution='1sec', coord='gse'
add_setting, prefix+'b_gse', /smart, dictionary($
    'display_type', 'vector', $
    'unit', 'nT', $
    'short_name', 'B', $
    'coord', 'Emfisis GSE', $
    'coord_labels', xyz )
bmag = snorm(get_var_data(prefix+'b_gse', times=uts))
store_data, prefix+'bmag', uts, bmag
bmag_solene = get_var_data(prefix+'bmag_solene', times=uts, in=time_range)
bmag = get_var_data(prefix+'bmag', at=uts)
store_data, prefix+'bmag_diff', uts, bmag_solene-bmag
add_setting, prefix+'bmag_diff', /smart, dictionary($
    'display_type', 'scalar', $
    'unit', 'nT', $
    'short_name', '|B| diff!C  Solene-Emfisis' )

b_solene_gse = get_var_data(prefix+'b_solene_gse', times=uts, in=time_range)
b_gse = get_var_data(prefix+'b_gse', at=uts)
store_data, prefix+'b_gse_diff', uts, b_gse-b_solene_gse
add_setting, prefix+'b_gse_diff', /smart, dictionary($
    'display_type', 'vector', $
    'short_name', 'dB', $
    'unit', 'nT', $
    'coord', 'GSE', $
    'coord_labels', xyz )
    
    
b_solene_mgse = cotran(b_solene_gse, uts, 'gse2mgse', probe=probe)
b_mgse = cotran(b_gse, uts, 'gse2mgse', probe=probe)


stop


; Check r_gse and v_gse. Results: they are very close to SPICE values.
rbsp_read_orbit, time_range, probe=probe, coord='gse'
rmag = snorm(get_var_data(prefix+'r_gse', times=uts))
store_data, prefix+'rmag', uts, rmag
rmag_solene = snorm(get_var_data(prefix+'r_solene_gse', times=uts, in=time_range))
rmag = get_var_data(prefix+'rmag', at=uts)
store_data, prefix+'rmag_diff', uts, rmag_solene-rmag



rbsp_read_sc_vel, time_range, probe=probe, coord='gse'
vmag = snorm(get_var_data(prefix+'v_gse', times=uts))
store_data, prefix+'vmag', uts, vmag
vmag_solene = snorm(get_var_data(prefix+'v_solene_gse', times=uts, in=time_range))
vmag = get_var_data(prefix+'vmag', at=uts)
store_data, prefix+'vmag_diff', uts, vmag_solene-vmag



plot_file = join_path([homedir(),'phase_f','solene_paper','test_bmag_'+prefix+time_string(time0,tformat='YYYY_MMDD')+'_v01.pdf'])
sgopen, plot_file, xsize=8, ysize=8
margins = [15,4,15,3]
vars = prefix+['b_solene_gse','b_gse','bmag_diff']
nvar = n_elements(vars)
poss = sgcalcpos(nvar, margins=margins, xchsz=xchsz, ychsz=ychsz)
tplot, vars, position=poss
tpos = poss[*,0]
tx = tpos[0]
ty = tpos[3]+ychsz*0.5
xyouts, tx,ty,/normal, 'Test |B| for RBSP-'+strupcase(probe)+' '+time_string(time0,tformat='YYYY-MM-DD')
sgclose

stop
    
tplot, prefix+['b','r','v']+'_solene_gse', trange=time_range
end
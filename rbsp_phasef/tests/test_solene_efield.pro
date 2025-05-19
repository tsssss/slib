pro read_solene_efield, file

    data = (read_ascii(file)).FIELD01
    base = file_basename(file)
    probe = strlowcase(strmid(base,0,1))
    prefix = 'rbsp'+probe+'_'
    date = strmid(base,36,6)
    date = time_double(date,tformat='yyMMDD')

    rgb = constant('rgb')
    xyz = constant('xyz')

    time = reform(data[0,*])
    time = time+date


    vxi = reform(data[1,*])
    vyi = reform(data[2,*])
    vzi = reform(data[3,*])

    vx = reform(data[4,*])
    vy = reform(data[5,*])
    vz = reform(data[6,*])

    bx = reform(data[7,*])
    by = reform(data[8,*])
    bz = reform(data[9,*])

    store_data, prefix+'ExBscxGSE!Cinertial-frame',data={x:time,y:[[vxi],[vyi],[vzi]]},dlim={labels:['x','y','z'],colors:rgb}
    store_data, prefix+'ExBscxGSE!Cspacecraft-frame',data={x:time,y:[[vx],[vy],[vz]]},dlim={labels:['x','y','z'],colors:rgb}
    store_data, prefix+'b_gse_solene',data={x:time,y:[[bx],[by],[bz]]},dlim={labels:['x','y','z'],colors:rgb}

    ; E = -vxB.
    ex = -(vy*bz-vz*by)/1000.
    ey = -(vz*bx-vx*bz)/1000.
    ez = -(vx*by-vy*bx)/1000.

    store_data, prefix+'E-GSE-from-vXB!Cspacecraft-frame',data={x:time,y:[[ex],[ey],[ez]]},dlim={labels:['x','y','z'],colors:rgb}

    ; E = -vxB.
    exi = -(vyi*bz-vzi*by)/1000.
    eyi = -(vzi*bx-vxi*bz)/1000.
    ezi = -(vxi*by-vyi*bx)/1000.

    store_data, prefix+'E-GSE-from-vXB!Cinertial-frame',data={x:time,y:[[exi],[eyi],[ezi]]},dlim={labels:['x','y','z'],colors:rgb}

    
    re1 = 1d/constant('re')
    store_data, prefix+'r_gse', time, transpose(data[11:13,*])*re1, limits={$
        labels:xyz, colors:rgb}
    store_data, prefix+'v_gse', time, transpose(data[14:16,*]), limits={$
        labels:xyz, colors:rgb}


    vars = prefix+[$
        'b_gse_solene', $
        'ExBscxGSE!Cinertial-frame', $
        'ExBscxGSE!Cspacecraft-frame', $
        'E-GSE-from-vXB!Cspacecraft-frame', $
        'E-GSE-from-vXB!Cinertial-frame' ]
    foreach var, vars do begin
        pos = strpos(strlowcase(var),'gse')
        new_var = strmid(var,0,pos)+'mGSE'+strmid(var,pos+3)
        get_data, var, times, e_gse
        e_mgse = cotran(e_gse, times, 'gse2mgse', probe=probe)
        store_data, new_var, times, e_mgse, limits={$
            labels: xyz, colors:rgb }
    endforeach
end


; The 1-sec jump section.
date = '2014-06-14'
probe = 'b'

date = '2015-05-20'
probe = 'b'

; Scott's first example.
date = '2014-01-02'
probe = 'a'

;; The example sent to Wygant.
;date = '2012-12-25'
;probe = 'b'


secofday = constant('secofday')
time_range = time_double(date[0])+[0,secofday]
prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')
rgb = constant('rgb')

path = join_path([googledir(),'works','scottthaller','solene_efield_comparison','GSE'])
base = apply_time_to_pattern(strupcase(probe)+'_ExBGSE_0andT_BGSE_SCPOT_XGSE_VGSE_%y%m%d.txt', time_range[0])
file = join_path([path,base])
if ~file_test(file) then message, 'File does not exist ...'
read_solene_efield, file


rbsp_efw_read_p4, time_range, probe=probe
rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe



; Make sure to use the fixed B mgse.
b_uvw_var = prefix+'b_uvw'
rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
b_mgse_var = prefix+'b_mgse'
rbsp_fix_b_uvw, time_range, probe=probe
b_uvw = get_var_data(prefix+'b_uvw', times=times)
b_mgse2 = cotran(b_uvw, times, 'uvw2mgse', probe=probe)
store_data, b_mgse_var, times, b_mgse2


rbsp_read_emfisis, time_range, id='l3%magnetometer', probe=probe, resolution='4sec', coord='gse', errmsg=errmsg
get_data, prefix+'b_gse', times, b_gse
b_mgse = cotran(b_gse, times, 'gse2mgse', probe=probe)
store_data, prefix+'b_mgse_emfisis', times, b_mgse
store_data, prefix+'bmag_emfisis', times, snorm(b_mgse)
options, prefix+'b_mgse_emfisis', 'colors', rgb
options, prefix+'b_mgse_emfisis', 'labels', xyz
        
bp = rbsp_efw_phasef_get_boom_pair(time_range, probe=probe)
e_p4_var = prefix+'efw_efield_in_corotation_frame_spinfit_mgse_'+bp
options, e_p4_var, 'colors', constant('rgb')

e_var = prefix+'e_spinfit_mgse_v'+bp
e_mgse = get_var_data(e_var, times=times)
store_data, prefix+'e_mgse_in_corotation_frame', times, e_mgse, limits={$
    labels:xyz, colors:rgb}

e_coro = get_var_data(prefix+'ecoro_mgse', at=times)
e_mgse = e_mgse+e_coro
store_data, prefix+'e_mgse_in_spacecraft_frame', times, e_mgse, limits={$
    labels:xyz, colors:rgb}

r_var = prefix+'efw_position_gse'
get_data, r_var, times, r_gse
r_gse /= constant('re')
store_data, r_var, times, r_gse
options, prefix+'efw_'+['position','velocity']+'_gse', 'colors', rgb
options, prefix+'efw_'+['position','velocity']+'_gse', 'labels', xyz

tplot_options, 'labflag', -1


var = prefix+'E-mGSE-from-vXB!Ccorotation-frame'
dif_data, prefix+'E-mGSE-from-vXB!Cinertial-frame', prefix+'ecoro_mgse', $
    newname=var
get_data, var, times, vec
vec[*,0] = 0
store_data, var, times, vec, limits={colors:constant('rgb'),labels:constant('xyz')}



; Compare the latest of my result to Solene's.

sgopen, 0, xsize=6, ysize=4
vars = prefix+['e_spinfit_mgse_v'+bp,$
    'E-mGSE-from-vXB!Ccorotation-frame']
ylim, vars, [-1,1]*4
tplot, vars, trange=time_range
stop


get_data, prefix+'b_mGSE_solene', times, b_mgse
store_data, prefix+'bmag_solene', times, snorm(b_mgse)

get_data, prefix+'b_mgse', times, b_mgse
store_data, prefix+'bmag_sheng', times, snorm(b_mgse)
options, prefix+'b_mgse', 'colors', rgb
options, prefix+'b_mgse', 'labels', xyz


solene_vars = prefix+['r_gse','v_gse','bmag_solene','b_mGSE_solene']
;solene_vars = prefix+['r_gse','v_gse','bmag_emfisis','b_mgse_emfisis']
;sheng_vars = prefix+['efw_position_gse','efw_velocity_gse','bmag_sheng','b_mgse']
sheng_vars = prefix+['efw_position_gse','efw_velocity_gse','bmag_emfisis','b_mgse_emfisis']
foreach sheng_var, sheng_vars, var_id do begin
    get_data, sheng_var, times, sheng_data, limits=lim
    
    ; Make a copy and interp to the same time.
    solene_var = solene_vars[var_id]
    copy_data, solene_var, solene_var+'_tmp'    
    interp_time, solene_var+'_tmp', times
    yrange = sg_autolim(minmax(sheng_data))
    vars = [solene_var+'_tmp',sheng_var]
    options, vars, 'yrange', yrange
    options, vars, 'ystyle', 1
    
    solene_data = get_var_data(solene_var+'_tmp')
    diff = sheng_data-solene_data
    store_data, sheng_var+'_diff', times, diff, limits=lim
    yrange = sg_autolim(diff)
    ylim, sheng_var+'_diff', yrange
    ylim, sheng_var+'_diff', -1
endforeach


; Check B field.
get_data, prefix+'bmag_sheng', times, bmag
foreach var, prefix+'bmag_'+['solene','emfisis'] do begin
    copy_data, var, var+'_tmp'
    interp_time, var+'_tmp', times
endforeach
bmag1 = get_var_data(prefix+'bmag_solene_tmp')
bmag2 = get_var_data(prefix+'bmag_emfisis_tmp')
store_data, prefix+'bmag_sheng-emfisis', times, bmag-bmag2
store_data, prefix+'bmag_solene-emfisis', times, bmag1-bmag2
store_data, prefix+'bmag_sheng-solene', times, bmag-bmag1


get_data, prefix+'b_mgse', times, bmag
foreach var, prefix+['b_mGSE_solene','b_mgse_emfisis'] do begin
    copy_data, var, var+'_tmp'
    interp_time, var+'_tmp', times
endforeach
bmag1 = get_var_data(prefix+'b_mGSE_solene_tmp')
bmag2 = get_var_data(prefix+'b_mgse_emfisis_tmp')
store_data, prefix+'b_mgse_sheng-emfisis', times, bmag-bmag2
store_data, prefix+'b_mgse_solene-emfisis', times, bmag1-bmag2
store_data, prefix+'b_mgse_sheng-solene', times, bmag-bmag1
vars = prefix+'b_mgse_'+['sheng-emfisis','solene-emfisis','sheng-solene']
options, vars, 'colors', rgb
options, vars, 'labels', xyz
vars = prefix+[$
    'b_mgse_'+['sheng-emfisis','solene-emfisis','sheng-solene'], $
    'bmag_'+['sheng-emfisis','solene-emfisis','sheng-solene']]
tplot, vars

stop


sgopen, ofile, xsize=12, ysize=4
nypan = n_elements(sheng_vars)
nxpan = 3
poss = sgcalcpos(nypan,nxpan, xpad=20, margins=[16,5,5,2])

dis = snorm(get_var_data(prefix+'efw_position_gse', times=times))
index = where(dis ge 4)
apogee_time_ranges = times[time_to_range(index,time_step=1)]
plot_time_range = reform(apogee_time_ranges[1,*])
plot_time_range = time_range

tpos = reform(poss[*,0,*])
tplot, sheng_vars, position=tpos, noerase=1, trange=plot_time_range

tpos = reform(poss[*,1,*])
tplot, solene_vars+'_tmp', position=tpos, noerase=1, trange=plot_time_range

tpos = reform(poss[*,2,*])
tplot, sheng_vars+'_diff', position=tpos, noerase=1, trange=plot_time_range
stop

vars = [prefix+['efw_lshell',$
    'r_gse','v_gse','b_mGSE_solene'], $
    
;    'ExBscxmGSE!Cinertial-frame','ExBscxmGSE!Cspacecraft-frame'],$
    
    prefix+'efw_'+['position_gse','velocity_gse'],prefix+'b_mgse', $
    
 ;   e_p4_var,prefix+'e_mgse_in_'+['corotation','spacecraft']+'_frame', $
        
    '']
tplot, vars, trange=time_range

end


;readme
;Each .txt. file corresponds to one day of mesurement with the following title format

;'NEW_GSE_'+sc+'/'+sc+'_ExBGSE_0andT_BGSE_SCPOT_XGSE_VGSE_'+yymmdd+'.txt'

;where sc is either A or B
;yy is the last 2 digits of the year
;mm is the month
;and dd is the day

;Each line is made of 17 elements:
;time_secs, ExBxGSE,ExByGSE,ExBzGSE,ExBscxGSE,ExBscyGSE,ExBsczGSE,BxGSE,ByGSE,BzGSE, scpot, xGSE,yGSE,zGSE,VxGSE, VyGSE,VzGSE
;where
;1:  time_secs is the time of the day, in seconds (86400s per day)
;2:  ExBxGSE is the x component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the INERTIAL FRAME - with a shorting factor assumed to be 1
;3:  ExByGSE is the y component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the INERTIAL FRAME - with a shorting factor assumed to be 1
;4:  ExBzGSE is the z component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the INERTIAL FRAME - with a shorting factor assumed to be 1
;5:  ExBscxGSE is the x component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the SPACECRAFT FRAME
;6:  ExBscyGSE is the y component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the SPACECRAFT FRAME
;7:  ExBsczGSE is the z component of the electric drift (ExB/B^2) in GSE coordinates in km/s in the SPACECRAFT FRAME
;8:  BxGSE is the x component of the magnetic field in in GSE coordinates in nT
;9:  ByGSE is the y component of the magnetic field in in GSE coordinates in nT
;10: BzGSE is the z component of the magnetic field in in GSE coordinates in nT
;11:   scpot is the spacecraft potential (multiplied by -1) in Volts
;12: xGSE is the x GSE coordinate of the spacecraft location in km
;13: yGSE is the y GSE coordinate of the spacecraft location in km
;14: zGSE is the z GSE coordinate of the spacecraft location in km
;15: VxGSE is the x GSE coordinate of the spacecraft velocity in km/s
;16: VyGSE is the x GSE coordinate of the spacecraft velocity in km/s
;17: VzGSE is the x GSE coordinate of the spacecraft velocity in km/s

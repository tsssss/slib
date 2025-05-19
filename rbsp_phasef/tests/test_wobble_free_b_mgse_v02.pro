
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

    ex = (vy*bz-vz*by)/1000.
    ey = (vz*bx-vx*bz)/1000.
    ez = (vx*by-vy*bx)/1000.

    store_data, prefix+'E-GSE-from-vXB!Cspacecraft-frame',data={x:time,y:[[ex],[ey],[ez]]},dlim={labels:['x','y','z'],colors:rgb}

    exi = (vyi*bz-vzi*by)/1000.
    eyi = (vzi*bx-vxi*bz)/1000.
    ezi = (vxi*by-vyi*bx)/1000.

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


date = '2012-12-25'
probe = 'b'


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


rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe


rbsp_read_emfisis, time_range, id='l3%magnetometer', probe=probe, resolution='hires', coord='gse', errmsg=errmsg
get_data, prefix+'b_gse', times, b_gse
b_mgse = cotran(b_gse, times, 'gse2mgse', probe=probe)
store_data, prefix+'b_mgse_emfisis', times, b_mgse
store_data, prefix+'bmag_emfisis', times, snorm(b_mgse)
options, prefix+'b_mgse_emfisis', 'colors', rgb
options, prefix+'b_mgse_emfisis', 'labels', xyz


tplot_options, 'labflag', -1


get_data, prefix+'b_mGSE_solene', times, b_mgse
store_data, prefix+'bmag_solene', times, snorm(b_mgse)

get_data, prefix+'b_mgse', times, b_mgse
store_data, prefix+'bmag_sheng', times, snorm(b_mgse)
options, prefix+'b_mgse', 'colors', rgb
options, prefix+'b_mgse', 'labels', xyz


solene_vars = prefix+['bmag_solene','b_mGSE_solene']
sheng_vars = prefix+['bmag_sheng','b_mgse']
;sheng_vars = prefix+['bmag_emfisis','b_mgse_emfisis']
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
    'b_mgse_'+['sheng-emfisis','sheng-solene'], $
    'bmag_'+['sheng-emfisis','sheng-solene']]
    
sgopen, 0, xsize=5, ysize=8
nvar = n_elements(vars)
tpos = sgcalcpos(nvar,margins=[10,4,3,2])
tplot, vars, position=tpos

end

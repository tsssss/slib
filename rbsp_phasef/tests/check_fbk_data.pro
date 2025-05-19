;+
; Check fbk data.
;-

; Have burst data on this day.
time_range = time_double(['2013-06-07/04:30','2013-06-07/04:35'])
probe = 'b'


prefix = 'rbsp'+probe+'_'

rbsp_efw_read_l2, time_range, probe=probe, datatype='fbk'
rbsp_efw_read_burst_efield, time_range, probe=probe
options, prefix+'efw_eb1_mgse', 'colors', constant('rgb')

var = prefix+'efw_fbk7_e12dc_pk'
get_data, var, times, data, val, lim=lim, dlim=dlim
time_tag_offset = -1d/8
store_data, var+'_shift', times+time_tag_offset, data, val, lim=lim, dlim=dlim

vars = prefix+['efw_fbk7_e12dc_pk','efw_fbk7_e12dc_pk_shift','efw_eb1_mgse']
nvar = n_elements(vars)

tplot_options, 'labflag', -1
tplot_options, 'version', 1

plot_list = list()
plot_list.add, time_double('2013-06-07/04:30')+[36.5,38.5]
plot_list.add, time_double('2013-06-07/04:30')+[58.0,60.0]

foreach plot_time_range, plot_list, plot_id do begin
    margins = [12,4,10,2]
    ofn = plot_id
    sgopen, ofn, xsize=5, ysize=5, xchsz=xchsz, ychsz=ychsz
    poss = sgcalcpos(nvar, margins=margins)
    tplot, vars, position=poss, trange=plot_time_range, window=plot_id
    
    labels = ['a. FBK!C    orig', 'b. FBK!C    shift', 'c. B1']
    for ii=0,nvar-1 do begin
        tpos = poss[*,ii]
        tx = tpos[0]-xchsz*10
        ty = tpos[3]-ychsz*0.7
        msg = labels[ii]
        xyouts, tx,ty,/normal, msg
    endfor
    sgclose
endforeach


end
;+
; In the previous version, the residue of e_spinfit is much smaller than that of e_spinfit_diagonal.
;
; Now that the time tags for B and E_uvw and e_uvw_diagonal have been corrected.
; 
; I check the residues of e_spinfit and e_spinfit_diagonal again. If the difference in residues is caused by the time tag offset, then they should be about the same now.
;-

date = '2015-05-01'
probe = 'a'

secofday = constant('secofday')
time_range = time_double(date)+[0,secofday]
prefix = 'rbsp'+probe+'_'

;foreach version, ['v02','v03'] do begin
;    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe, version=version
;    vars = prefix+['r','v','b']+'_mgse'
;    foreach var, vars do rename_var, var, to=var+'_'+version
;endforeach
;stop
;foreach version, ['v01','v02'] do begin
;    rbsp_read_e_model, time_range, probe=probe, version=version
;    copy_data, prefix+'emod_mgse', prefix+'emod_mgse_'+version
;endforeach
;rbsp_efw_read_e_mgse, time_range, probe=probe
;stop


root_dir = homedir()
foreach type, 'spinfit'+['','_diagonal'] do begin
    file = join_path([root_dir,'test_e_'+type+date+'.cdf'])
    if file_test(file) eq 0 then begin
        routine = 'rbsp_efw_phasef_read_e_'+type+'_gen_file'
        call_procedure, routine, time_range[0], probe=probe, filename=file, keep_e_model=1
    endif
    cdf2tplot, file
endforeach

rbsp_read_e_model, time_range, probe=probe
emod_var = prefix+'emod_mgse'
get_data, emod_var, times, emod
emod[*,0] = 0
store_data, emod_var, times, emod
bps = ['12','34','13','14','23','24']
foreach var, prefix+'e_spinfit_mgse_v'+bps do begin
    dif_data, var, emod_var, newname=var+'_diff'
endforeach

yrange = [-1,1]*5
sgopen, 0, xsize=8, ysize=5
poss = sgcalcpos(6,2, xpad=15, margins=[15,4,2,2])
tpos = reform(poss[*,0,*])
vars = prefix+'e_spinfit_mgse_v'+bps+'_diff'
options, vars, 'colors', constant('rgb')
ylim, vars, yrange[0], yrange[1]
tplot, vars, position=tpos, noerase=1, trange=time_range


; Load old version.
version = 'v02'
data_dir = '/Volumes/data/rbsp/efw_phasef'
rbspx = 'rbsp'+probe
year = time_string(time_range[0],tformat='YYYY')
foreach type, ['','_diagonal'] do begin
    base = prefix+'efw_e'+type+'_spinfit_mgse_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_'+version+'.cdf'
    dir = 'e_spinfit'+type+'_'+version
    data_file = join_path([data_dir,dir,rbspx,year,base])
    cdf2tplot, data_file
endforeach
tpos = reform(poss[*,1,*])
vars = prefix+'e_spinfit_mgse_v'+bps
options, vars, 'colors', constant('rgb')
ylim, vars, yrange[0], yrange[1]
tplot, vars, position=tpos, noerase=1, trange=time_range

end

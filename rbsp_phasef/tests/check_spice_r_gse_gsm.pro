;+
; Aaron says spice r_gse differ from ect counterpart.
; The weird thing is r_gsm differ less than r_gse, which suggests to me that the problem is gse/gsm conversion.
;-

day = time_double('2014-01-01')
probe = 'a'
time_range = day+[0,constant('secofday')]
prefix = 'rbsp'+probe+'_'
rbsp_read_orbit, time_range, probe=probe, coord='gsm'
rbsp_read_orbit, time_range, probe=probe, coord='gse'
r_gsm = get_var_data(prefix+'r_gsm', times=times)
r_gse_cotran = cotran(r_gsm, times, 'gsm2gse')
cotrans, prefix+'r_gsm', prefix+'r_gse_cotrans', gsm2gse=1
r_gse_cotrans = get_var_data(prefix+'r_gse_cotrans')
r_gse_spice = get_var_data(prefix+'r_gse')
r_gse_geopack = r_gse
foreach time, times, ii do begin
    ps = geopack_recalc(time)
    geopack_conv_coord, r_gsm[ii,0],r_gsm[ii,1],r_gsm[ii,2], rx,ry,rz, /from_gsm, /to_gse
    r_gse_geopack[ii,*] = [rx,ry,rz]
endforeach

tplot_options, 'labflag', -1
colors = sgcolor(['red','green','blue'])
labels = ['SPICE','Cotrans','Geopack']
foreach component, ['x','y','z'], ii do begin
    data = [[r_gse_spice[*,ii]],[r_gse_cotrans[*,ii]],[r_gse_geopack[*,ii]]]
    for jj=0,2 do data[*,jj] -= r_gse_spice[*,ii]
    store_data, prefix+component+'_gse', times, data, $
        limits = {ytitle:'GSM d'+strupcase(component)+' (Re)', labels:labels, colors:colors}
endforeach

stop
end
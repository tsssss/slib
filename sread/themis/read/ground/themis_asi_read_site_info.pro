;+
; Read the info of the site center.
;-

function themis_asi_read_site_info, site, errmsg=errmsg, site_info=site_info

    info = themis_read_asi_info([0,0], site=site, id='asc', errmsg=errmsg, input_site_info=site_info)
    
    if site eq 'pgeo' then info['asc_midn'] = '08:55'   ; interpolated from fsim, whit and gako.
    if site eq 'nrsq' then info['asc_midn'] = '01:51'   ; extrapolated from all other sites.
    
    ; Conver midn from string to ut in sec.
    midn = info['asc_midn']
    if strtrim(midn,2) eq '' then stop
    hr = double(strmid(midn,0,2))
    mi = double(strmid(midn,3,2))
    midn_ut = (hr*60+mi)*60d
    info['midn_ut'] = midn_ut
    
    return, info
    
end

site_info = orderedhash()
midns = list()
mlons = list()
midn_uts = list()
foreach site, themis_read_asi_sites() do begin
    site_info[site] = themis_asi_read_site_info(site)
    midns.add, (site_info[site])['asc_midn']
    mlons.add, (site_info[site])['asc_mlon']
    midn_uts.add, (site_info[site])['midn_ut']
endforeach
midns = midns.toarray()
mlons = mlons.toarray()
midn_uts = midn_uts.toarray()
index = where(mlons le 43, complement=index2)
tmp = linfit(midn_uts[index], mlons[index])
plot, midn_uts, mlons, psym=1
plots, midn_uts, tmp[1]*midn_uts+tmp[0]

the_midn_ut = (mlons[index2]-tmp[0])/tmp[1]
hr = floor(the_midn_ut/3600)
mi = (the_midn_ut-hr*3600)/60
print, hr, mi
end
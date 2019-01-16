;+
; Find the midnight local time
;-
;

function themis_asi_find_midn, times

    sites = themis_asi_sites()
    nsite = n_elements(sites)
    
    midns = dblarr(nsite)
    mlons = dblarr(nsite)
    mlats = dblarr(nsite)
    glons = dblarr(nsite)
    glats = dblarr(nsite)
    foreach site, sites, i do begin
        asc_var = 'thg_asc_'+site+'_'+['midn','mlon','mlat','glon','glat']
        themis_read_asi, 0, id='asc', site=site, in_vars=asc_var, skip_index=1
        midns[i] = get_data(asc_var[0])
        mlons[i] = get_data(asc_var[1])
        mlats[i] = get_data(asc_var[2])
        glons[i] = get_data(asc_var[3])
        glats[i] = get_data(asc_var[4])
        store_data, asc_var, /delete
    endforeach
    
    index = where(midns ne 0)
    midns = midns[index]
    mlons = mlons[index]
    mlats = mlats[index]
    glons = glons[index]
    glats = glats[index]
    sites = sites[index]
    index = sort(mlons)
    midns = midns[index]
    mlons = mlons[index]
    mlats = mlats[index]
    glons = glons[index]
    glats = glats[index]
    sites = sites[index]
    
    secofday = 86400d
    ut = times[0]
    et = stoepoch(ut, 'unix')
    nsite = n_elements(mlons)
    
    ; test 1: use the Polar and Image way.
    apexfile = sparentdir(srootdir())+'/support/mlatlon.1997a.xdr'
    geotoapex, glats, glons, apexfile, mlats_polar, mlons_polar
    get_local_time, et, glats, glons, apexfile, glts, mlts_polar
    index = where(mlts_polar gt 12, count)
    if count ne 0 then mlts_polar[index] -= 24
    
    ; test 2: use my conversion function.
    mlts_sheng = dblarr(nsite)
    for i=0, nsite-1 do mlts_sheng[i] = slon2lt(mlons[i], et, /mag, /degree)
    

stop
    
end

time = time_double('2014-08-28/10:00')
midn = themis_asi_find_midn(time)
end
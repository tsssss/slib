;+
; Read horizontal and vertical currents.
; To replace themis_read_weygand.
; 
; id=. Can be 'j_hor','j_ver','j_west','j_north','j_hor_mag'.
;-

function themis_read_weygand_j, input_time_range, id=datatype, get_name=get_name, errmsg=errmsg

    errmsg = ''
    time_range = time_double(input_time_range)
    files = themis_load_weygand_j(time_range, errmsg=errmsg)
    if errmsg ne '' then return, ''

    prefix = 'thg_'
    if n_elements(datatype) eq 0 then datatype = 'j_ver'
    j_vars = prefix+datatype
    if keyword_set(get_name) then return, j_vars
    
    if n_elements(types) eq 0 then types = ['hor','ver']
    foreach type, types, type_id do begin
        suffix = '_'+type

        var_list = list()
        j_var = prefix+'j'+suffix
        var_list.add, dictionary( 'in_vars', j_var )
        read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
        if errmsg ne '' then return, ''
        
        glat_var = prefix+'glat_j'+suffix
        glon_var = prefix+'glon_j'+suffix
        glat = cdf_read_var(glat_var, filename=files[0])
        glon = cdf_read_var(glon_var, filename=files[0])
        glat_bins = sort_uniq(glat)
        glon_bins = sort_uniq(glon)
        nglatbin = n_elements(glat_bins)
        nglonbin = n_elements(glon_bins)

        glatbinsize = glat_bins[1]-glat_bins[0]
        glonbinsize = glon_bins[1]-glon_bins[0]
        glat_index = round((glat-glat_bins[0])/glatbinsize)
        glon_index = round((glon-glon_bins[0])/glonbinsize)

        get_data, j_var, times, j_orig
        ntime = n_elements(times)
        ndim = (type eq 'hor')? 2: 1
        jdata = fltarr(ntime,nglonbin*nglatbin,ndim)
        mapping_index = glon_index+glat_index*nglonbin
        jdata[*,mapping_index,*] = j_orig
        jdata = reform(jdata, [ntime,nglonbin,nglatbin,ndim])
        store_data, j_var, times, jdata
        options, j_var, 'glon_bins', glon_bins
        options, j_var, 'glat_bins', glat_bins
        
        vatt = cdf_read_setting(j_var, filename=files[0])
        options, j_var, 'unit', vatt.unit
    endforeach

    if datatype eq 'j_hor_mag' then begin
        get_data, j_var, times, jdata, limits=lim
        store_data, j_vars, times, sqrt(total(jdata^2,4)), limits=lim
    endif else if datatype eq 'j_west' then begin
        get_data, j_var, times, jdata, limits=lim
        store_data, j_vars, times, jdata[*,*,*,0], limits=lim
    endif else if datatype eq 'j_north' then begin
        get_data, j_var, times, jdata, limits=lim
        store_data, j_vars, times, jdata[*,*,*,1], limits=lim
    endif

;---Add more position info.
    foreach j_var, j_vars do begin
        get_data, j_var, times, limits=lim
        glon_bins = lim.glon_bins
        glat_bins = lim.glat_bins
        nglon_bin = n_elements(glon_bins)
        nglat_bin = n_elements(glat_bins)
        glon_grids = (fltarr(nglat_bin)+1) ## glon_bins
        glat_grids = glat_bins ## (fltarr(nglon_bin)+1)
        geo2mag2d, times, glon=glon_grids, glat=glat_grids, $
            mlon=mlon_grids, mlat=mlat_grids, use_apex=1
        midn_mlons = themis_asi_midn_mlon(times)
        add_setting, j_var, dictionary($
            'glon_grids', glon_grids, $
            'glat_grids', glat_grids, $
            'mlon_grids', mlon_grids, $
            'mlat_grids', mlat_grids, $
            'midn_mlons', midn_mlons )
    endforeach


    return, j_vars

end

time_range = ['2008-01-19/06:00','2008-01-19/09:00']
time_range = ['2013-05-01/07:38','2013-05-01/07:39']
vars = themis_read_weygand_j(time_range)
end
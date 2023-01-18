;+
; To replace geotoapex because it doesn't work on Mac OS anymore.
;-

pro geo2apex, glat, glon, apex_lat, apex_lon

    root_dir = srootdir()
    cdf_file = join_path([root_dir,'mlatlon.1997a.cdf'])
    if file_test(cdf_file) eq 0 then begin
        xdr_file = join_path([root_dir,'mlatlon.1997a.xdr'])
        if file_test(xdr_file) eq 0 then begin
            errmsg = 'No input xdr file, need "mlatlon.1997a.xdr" ...'
            stop
        endif
        apex_lat = fltarr(361,181)
        apex_lon = fltarr(361,181)
        openr, lun, xdr_file, get_lun=1, xdr=1
        readu, lun, apex_lat
        readu, lun, apex_lon
        free_lun, lun

        cdf_save_var, 'apex_lat', value=apex_lat, filename=cdf_file, save_as_one=1 
        cdf_save_var, 'apex_lon', value=apex_lon, filename=cdf_file, save_as_one=1 
    endif

    apex_lat = cdf_read_var('apex_lat', filename=cdf_file)
    apex_lon = cdf_read_var('apex_lon', filename=cdf_file)

    rad = constant('rad')
    deg = constant('deg')
    ; the interpolation requires longitude 0 to 360
    ; Map the line segment (-180,180) into a circle in the
    ; complex plane, perform the interpolation, map back to
    ; the original line segment
    sin_apex_lon = sin(rad*apex_lon)
    cos_apex_lon = cos(rad*apex_lon)
    sin_apex_lon = interpolate(sin_apex_lon, ((glon+360) mod 360), glat + 90)
    cos_apex_lon = interpolate(cos_apex_lon, ((glon+360) mod 360), glat + 90)
    apex_lon = atan(sin_apex_lon,cos_apex_lon)*deg
    apex_lat = interpolate(apex_lat, ((glon+360) mod 360), glat + 90)

end

geo2apex, 0, 0, a, b
end
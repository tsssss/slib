; %W% %G%
;
pro GeotoApex, geographic_lat, geographic_lon, apexfile, apex_lat, apex_lon

; Transform geographic coordinates to apex magnetic coordinates.
; This requires a data file (supplied by Art Richmond) which contains
; the apex coordinates for all geographic coordinates on a 1x1 degree
; grid.  The routine works for all latitudes and longitudes, and the
; data file is valid only for the epoch 1997.

apex_lat = FltArr(361, 181)
apex_lon = FltArr(361, 181)

; Sheng: auto find the apexfile.
if n_elements(apexfile) eq 0 then apexfile = ''
if file_test(apexfile) eq 0 then begin
    image_root = sparentdir(srootdir())
    apexfile = join_path([image_root,'support','mlatlon.1997a.xdr'])
endif
OpenR, lun, apexfile, /Get_Lun, /xdr
ReadU, lun, apex_lat
ReadU, lun, apex_lon
Free_Lun, lun

degree_to_radian = !DPI / 180D

; the interpolation requires longitude 0 to 360
; Map the line segment (-180,180) into a circle in the
; complex plane, perform the interpolation, map back to
; the original line segment
sin_apex_lon = sin(degree_to_radian*apex_lon)
cos_apex_lon = cos(degree_to_radian*apex_lon)
sin_apex_lon = interpolate(sin_apex_lon, ((geographic_lon+360) mod 360), geographic_lat + 90)
cos_apex_lon = interpolate(cos_apex_lon, ((geographic_lon+360) mod 360), geographic_lat + 90)
apex_lon = atan(sin_apex_lon,cos_apex_lon)/degree_to_radian
apex_lat = interpolate(apex_lat, ((geographic_lon+360) mod 360), geographic_lat + 90)
end

;+
; Return the dipole direction (unit vector) in GEO, work within 1900 to 2015.
;
; times. An array of UT sec in [n].
; v1, v2, v3. The components of the dipole direction in GEO.
; radian. A boolean sets v1/v2 as lat/lon in rad.
; degree. A boolean sets v1/v2 as lat/lon in deg.
;
; In Hapgood 1992, there are two ways to calculate the dipole GEO
; latitude and longitude: (a) interpolate from IGRF model coefficients
; (g01, g11, h11); (b) estimate from, e.g., the two equation below
; equation (9).
;
; Method (b) is used in this program. According to test_dipole_dir.pro,
; (a)'s error is < 0.01 deg, or 2e-4 rad,
; (b)'s error is < ~0.3 deg, or 5e-3 rad.
; The accuray of (b) is good enough.
;
; Method (a) use igrf11coeffs.txt at
; http://www.ngdc.noaa.gov/IAGA/vmod/igrf.html, which lists semi-
; normalized spherical harmonics coefficient. Only n=1 harmonics (g01, g11,
; and h11) are used, they are the beginning coefficients, thus no Schidt
; normalization is needed.
;-

pro dipole_dir, time, v1, v2, v3, degree=degree, radian=radian

;    secofday1 = 1/86400d
;    mjd = secofday1*time+40587d
;
;    t0 = mjd - 46066d
;    v1 = 1.3753194505715316d + 0.0000020466107099d*t0    ; in radian.
;    v2 = 5.0457468675156072d - 0.0000006751951087d*t0    ; in radian.
;
;    if keyword_set(radian) then return
;    if keyword_set(degree) then begin
;        deg = 180d/!dpi
;        v1 *= deg
;        v2 *= deg
;        return
;    endif
;
;    t = 0.5*!dpi - v1
;    p = v2
;    v1 = sin(t)*cos(p)
;    v2 = sin(t)*sin(p)
;    v3 = cos(t)


    ; Use IGRF coefficient.
    url = 'http://wdc.kugi.kyoto-u.ac.jp/igrf/coef/igrf13coeffs.txt'
    base_name = file_basename(url)
    file = join_path([srootdir(),base_name])
    if file_test(file) eq 0 then download_file, file, url
    nheader = 3
    start_column = 8
    nline = 4
    lines = strarr(nline)

    ; Read year, g01, g11, h11.
    openr, lun, file, /get_lun
    skip_lun, lun, nheader, /lines
    readf, lun, lines
    free_lun, lun
    times = strsplit(strmid(lines[0], start_column), /extract)
    ntime = n_elements(times)-1
    times = float(times[0:ntime-1])
    times = convert_time(string(times,format='(I04)')+'0101', from='%Y%m%d', to='unix')
    g01s = float(strsplit(strmid(lines[1], start_column), /extract))
    g11s = float(strsplit(strmid(lines[2], start_column), /extract))
    h11s = float(strsplit(strmid(lines[3], start_column), /extract))
    
    max_time = max(time)
    if max_time gt max(times) then begin
        times = [times,max_time]
        coef = (max_time-times[ntime-1])/(365.25*86400)
        g01s[ntime] = g01s[ntime-1]+g01s[ntime]*coef
        g11s[ntime] = g11s[ntime-1]+g11s[ntime]*coef
        h11s[ntime] = h11s[ntime-1]+h11s[ntime]*coef
    endif else begin
        g01s = g01s[0:ntime-1]
        g11s = g11s[0:ntime-1]
        h11s = h11s[0:ntime-1]
    endelse
    
    nrec = n_elements(time)
    g01 = dblarr(nrec)
    g11 = dblarr(nrec)
    h11 = dblarr(nrec)
    for ii=0, nrec-1 do begin
        g01[ii] = interpol(g01s, times, time[ii])
        g11[ii] = interpol(g11s, times, time[ii])
        h11[ii] = interpol(h11s, times, time[ii])
    endfor

    if nrec eq 1 then begin
        g01 = g01[0]
        g11 = g11[0]
        h11 = h11[0]
    endif
    
    if keyword_set(radian) or keyword_set(degree) then begin
        v2 = atan(h11,g11)+!dpi
        v1 = atan(sin(v2)*g01/h11)
        if keyword_set(degree) then begin
            deg = 180d/!dpi
            v1 *= deg
            v2 *= deg
        endif
    endif else begin
        coef = -1d/sqrt(g01^2+g11^2+h11^2)
        v1 = g11*coef
        v2 = h11*coef
        v3 = g01*coef
    endelse

end

epoch = stoepoch('2013-06-07/04:53:23')
time = sfmepoch(epoch,'unix')
dipole_dir, time, v1,v2,v3
print, v1,v2,v3
print, gmst(time)
rgsm = [v1,v2,v3]
rsm = gsm2sm(rgsm, time)
print, rsm

; test against a previous version.
sdipoledir, epoch, v1,v2,v3, /interp
print, v1,v2,v3
sgmst, epoch, gmst
print, gmst
rgsm = [v1,v2,v3]
rsm = sgsm2sm(rgsm, epoch)
print, rsm
end

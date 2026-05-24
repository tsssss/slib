;+
; DMSP XYZ:
;   x: forward along spacecraft track.
;   z: perpendicular to spacecraft track and toward the center of the Earth.
;   y: perpendicular to spacecraft track and complete the triad.
;-

function ct_dmsp_xyz2gsm, vec0, time, probe=probe

    compile_opt idl2
    on_error, 2

    vec1 = double(vec0)

    ; Read orbit.
    pad_time = 60d
    tr = minmax(time)+[-1,1]*pad_time
    r_gsm_var = dmsp_read_orbit(tr, probe=probe)
    r_gsm = var_get_data(r_gsm_var, times=times)

    ; Get how to express x,y,z in GSM.
    ndim = 3
    ntime = n_elements(times)
;    dmsp_x_hat = r_gsm[1:ntime-1,*]-r_gsm[0:ntime-2,*]
;    uts = (times[0:ntime-2]+times[1:ntime-1])*0.5
;    dmsp_x_hat = sinterpol(dmsp_x_hat,uts, times)
    dmsp_x_hat = r_gsm
    for ii=0,ndim-1 do dmsp_x_hat[*,ii] = deriv(r_gsm[*,ii])
    dmsp_x_hat = sunitvec(dmsp_x_hat)
    
    dmsp_r_hat = sunitvec(r_gsm)    ; z is roughly -r.
    dmsp_y_hat = vec_cross(dmsp_x_hat, dmsp_r_hat)  ; y = z cross x = x cross r
    dmsp_z_hat = vec_cross(dmsp_x_hat, dmsp_y_hat)

    ; Get the rotation matrix and quaternion.
    m_dmsp_xyz2gsm = dblarr(ntime,ndim,ndim)
    m_dmsp_xyz2gsm[*,0,*] = dmsp_x_hat
    m_dmsp_xyz2gsm[*,1,*] = dmsp_y_hat
    m_dmsp_xyz2gsm[*,2,*] = dmsp_z_hat
    
    ; Do rotation.
    vec1 = rotate_vector(vec1, m_dmsp_xyz2gsm)
    return, vec1

end

compile_opt idl2
time_range = ['2013-05-01/01:30','2013-05-01/04:00']
probe = 'f18'
prefix = 'dmsp'+probe+'_'
b_gsm_var = dmsp_read_bfield_cdaweb(time_range, probe=probe)
b_xyz_var = dmsp_read_bfield_madrigal(time_range, probe=probe)
b_xyz_var_noaa = dmsp_read_bfield_noaa(time_range, probe=probe)
db_xyz = var_get_data(b_xyz_var, times=times)
db_gsm = ct_dmsp_xyz2gsm(db_xyz, times, probe=probe)
settings = var_get_setting(b_gsm_var)
b_gsm_var_cotran = var_store(prefix+'db_gsm_cotran', db_gsm, times, settings=settings)

vars = [b_gsm_var,b_xyz_var]
times = var_get_time(b_gsm_var)
ntime = n_elements(times)
nvar = n_elements(vars)
bmags = fltarr(ntime,nvar)
foreach var, vars, vid do begin
    bmags[*,vid] = snorm(var_get_data(var,at=times))
endforeach
settings = dictionary($
    'colors', sgcolor(['red','blue']), $
    'labels', ['CDAWeb','Madrigal'])
bmag_var = var_store(prefix+'bmags', bmags, times, settings=settings)
plot_vars = [b_gsm_var,b_gsm_var_cotran,b_xyz_var,b_xyz_var_noaa,bmag_var]

sgopen, 0, size=[8,6]
tplot, plot_vars, trange=time_range
stop
sgclose
end
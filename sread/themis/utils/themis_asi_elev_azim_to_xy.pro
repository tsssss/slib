;+
; Get the x and y (continuous) coord for the given elev and azim on the given grids.
;
; the_elev.
; the_azim.
; pixel_elevs.
; pixel_azims.
;-
function themis_asi_elev_azim_to_xy, the_elev, the_azim, pixel_elevs, pixel_azims

    the_r3d = themis_asi_elev_azim_to_r3d(the_elev, the_azim)
    pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elevs, pixel_azims)

    angles = acos($
        pixel_r3d[*,*,0]*the_r3d[0]+$
        pixel_r3d[*,*,1]*the_r3d[1]+$
        pixel_r3d[*,*,2]*the_r3d[2])*constant('deg')
    index = where(finite(angles,nan=1), count)
    if count ne 0 then angles[index] = 720
    min_angle = min(angles, index)
    index2d = array_indices(pixel_elevs, index)
    return, index2d
    
    
    index = sort(angles)
    ncorner = 16
    corner_indexs = index[0:ncorner-1]
    corner_indexs_2d = fltarr(ncorner,2)
    for ii=0,ncorner-1 do corner_indexs_2d[ii,*] = array_indices(pixel_elevs, corner_indexs[ii])

    corner_iis = sort_uniq(corner_indexs_2d[*,0])
    corner_jjs = sort_uniq(corner_indexs_2d[*,1])
    if n_elements(corner_iis) eq 1 then stop
    if n_elements(corner_jjs) eq 1 then stop

    ii_range = minmax(corner_iis)
    jj_range = minmax(corner_jjs)
    
    clip_angles = angles[ii_range[0]:ii_range[1],jj_range[0]:jj_range[1]]
    clip_size = size(clip_angles,dimensions=1)
    scale = 100d
    clip_angles_hires = congrid(clip_angles, clip_size[0]*scale, clip_size[1]*scale, interp=1, cubic=-0.5)
    tmp = min(clip_angles_hires, clip_index)
    clip_index2d = array_indices(clip_size*scale, clip_index, dimensions=1)
    index2d = [ii_range[0],jj_range[0]]+clip_index2d/scale


;    min_angle = min(angles, index)
;    index2d = array_indices(pixel_elevs, index)
;    stop
    return, index2d
    
    

    ; Now we need to get the Jacobian around index2d.
    the_ii = index2d[0]
    the_jj = index2d[1]
    
;    delev_dx = (deriv(pixel_elevs[*,the_jj]))[the_ii]
;    delev_dy = (deriv(pixel_elevs[the_ii,*]))[the_jj]
;    dazim_dx = (deriv(pixel_azims[*,the_jj]))[the_ii]
;    dazim_dy = (deriv(pixel_azims[the_ii,*]))[the_jj]
    delev_dx = pixel_elevs[the_ii+1,the_jj]-pixel_elevs[the_ii,the_jj]
    delev_dy = pixel_elevs[the_ii,the_jj+1]-pixel_elevs[the_ii,the_jj]
    dazim_dx = pixel_azims[the_ii+1,the_jj]-pixel_azims[the_ii,the_jj]
    dazim_dy = pixel_azims[the_ii,the_jj+1]-pixel_azims[the_ii,the_jj]
    
    jacobian = [[delev_dx,delev_dy],[dazim_dx,dazim_dy]]
    jacobian_determ = determ(jacobian)
    jacobian_inverse = invert(jacobian)
    
    vec_elev_azim = [the_elev, the_azim]-[pixel_elevs[the_ii,the_jj],pixel_azims[the_ii,the_jj]]
    vec_ij = jacobian_inverse # vec_elev_azim
    
    index2d += vec_ij

    return, index2d

    

end

;+
; Transform the ASI image at a certain time to a given time to line up the moon.
; c.f. themis_asi_moon_linup_plot.pro
;
; asf_var. Required.
; times=. Output the times.
; return. The asf images whose moons are lined up.
;-


function get_continuous_values, values, times

    vals = sort_uniq(values)
    nval = n_elements(vals)
    counts = fltarr(nval)
    for ii=0,nval-1 do begin
        index = where(values eq vals[ii], count)
        counts[ii] = count
    endfor
    if nval le 10 then begin
        sign_count = mean(minmax(counts))
    endif else begin
        sign_count = median(counts)
    endelse
    sign_vals = vals[where(counts ge sign_count)]
    nsign_val = n_elements(sign_vals)
    sign_index = fltarr(nsign_val)
    for ii=0, nsign_val-1 do begin
        index = where(values eq sign_vals[ii])
        sign_index[ii] = median(index)
    endfor
    if sign_index[0] ne 0 then sign_index = [0,sign_index]
    conti_angles = interpol(values[sign_index], times[sign_index], times, quadratic=1)
    return, conti_angles
    
end




function find_pixel_index, the_elev, the_azim, pixel_elevs, pixel_azims

    the_r3d = themis_asi_elev_azim_to_r3d(the_elev, the_azim)
    pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elevs, pixel_azims)


    angles = acos($
        pixel_r3d[*,*,0]*the_r3d[0]+$
        pixel_r3d[*,*,1]*the_r3d[1]+$
        pixel_r3d[*,*,2]*the_r3d[2])*constant('deg')
    
    index = sort(angles)
    
    min_angle = min(angles, index)
    index2d = array_indices(pixel_elevs, index)
    
    return, index2d
    
end




function themis_asi_moon_align_read_info, input_time_range, site=site, $
    target_time=input_target_time, min_moon_elev=min_moon_elev
    
    
    time_range = time_double(input_time_range)
    ; Load pixel info.
    site_info = themis_read_asi_info(time_range, site=site, id='asf')
    pixel_elevs = site_info['asf_elev']
    pixel_azims = site_info['asf_azim']
    
    
    ; Load moon pos.
    moon_vars = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    moon_elev_var = moon_vars['moon_elev']
    moon_azim_var = moon_vars['moon_azim']
    if check_if_update(moon_elev_var, time_range) then moon_vars = themis_asi_read_moon_pos(time_range, site=site)
    moon_elevs = get_var_data(moon_elev_var, times=times)
    if n_elements(min_moon_elev) eq 0 then min_moon_elev = 5d
    
    
    ; Assume a same rotation applies to the entire time range.
    ; This works well for 1 hour (may be longer).
    the_times = [times[0],times[-1]]
    r2d_list = list()
    r3d_list = list()
    foreach time, the_times do begin
        moon_elev = get_var_data(moon_elev_var, at=time)
        moon_azim = get_var_data(moon_azim_var, at=time)
        r2d_list.add, [moon_elev,moon_azim]
        r3d_list.add, themis_asi_elev_azim_to_r3d(moon_elev, moon_azim)
    endforeach
    r3d_center = sunitvec(vec_cross(r3d_list[0], r3d_list[1]))
    r2d_center = themis_asi_r3d_to_elev_azim(r3d_center)
    center_elev = r2d_center[0]
    center_azim = r2d_center[1]
    rotation_center = themis_asi_elev_azim_to_xy(center_elev, center_azim, pixel_elevs, pixel_azims)
    rotation_start = themis_asi_elev_azim_to_xy((r2d_list[0])[0], (r2d_list[0])[1], pixel_elevs, pixel_azims)
    rotation_end = themis_asi_elev_azim_to_xy((r2d_list[1])[0], (r2d_list[1])[1], pixel_elevs, pixel_azims)
    r_start = rotation_start-rotation_center
    r_end = rotation_end-rotation_center
    rotation_angle = sang(r_start,r_end, deg=1)
    rotation_angles = interpol([0,rotation_angle], the_times, times)
    
        
    ; Target time, by default is when moon elev is max, or at least is within the time range.
    max_moon_elev = max(moon_elevs, index)
    default_target_time = times[index]
    if n_elements(input_target_time) eq 0 then input_target_time = default_target_time
    target_time = time_double(input_target_time)
    if n_elements(lazy_where(target_time, '[]', time_range)) eq 0 then target_time = default_target_time
    tmp = min(times-target_time, abs=1, target_index)
    rotation_angles = rotation_angles[target_index]-rotation_angles
    
    ; In case there is no moon.
    index = lazy_where(moon_elevs, 'lt', min_moon_elev, count=count)
    if count ne 0 then rotation_angles[index] = !values.f_nan

    ; Return the results.
    moon_align_info = dictionary($
        'rotation_angles', rotation_angles, $
        'rotation_center', rotation_center )
    return, moon_align_info

;    asf_images = get_var_data(asf_var, in=input_time_range, times=times)
;    
;    foreach time, times, time_id do begin
;        asf_image_current = reform(asf_images[time_id,*,*])
;        asf_images[time_id,*,*] = rot(asf_image_current, -rotation_angles[time_id], 1, $
;            rotation_centers[time_id,0], rotation_centers[time_id,1], pivot=1, missing=1, interp=1, cubic=-0.5)
;    endforeach
;
;    return, reform(asf_images)

end



time_range = ['2014-12-31/18:00','2015-01-01/12:00']
;time_range = ['2015-01-01/00:00','2015-01-01/06:00']
site = 'rank'
time_range = ['2008-01-19/01:00','2008-01-19/17:00']
site = 'inuv'
time_range = ['2008-01-18/23:00','2008-01-19/14:00']
site = 'gill'
test=0

info = themis_asi_moon_align_read_info(time_range, site=site)


; Test the align_info on real data.

root_dir = homedir()
movie_file = join_path([root_dir,'themis_asi_moon_align_'+site+'_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hh'),'_')+'_v02.mp4'])
plot_dir = join_path([root_dir,'themis_asi_moon_align'])

asf_var = themis_read_asf(time_range, site=site, get_name=1)
if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
orig_images = get_var_data(asf_var, times=times)
rotation_angles = info['rotation_angles']
rotation_center = info['rotation_center']

step = 600/3
orig_images = orig_images[0:*:step,*,*]
times = times[0:*:step]
rotation_angles = rotation_angles[0:*:step]


ntime = n_elements(times)
fig_files = strarr(ntime)
foreach time, times, time_id do begin
    plot_file = join_path([plot_dir,'themis_asi_moon_align_'+site+'_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'_v01.png'])
    fig_files[time_id] = plot_file
    sgopen, plot_file, size=[256*2,256], xchsz=xchsz, ychsz=ychsz, test=test
    
    asf_image_current = reform(orig_images[time_id,*,*])
    asf_image = rot(asf_image_current, rotation_angles[time_id], 1, $
        rotation_center[0], rotation_center[1], pivot=1, missing=1, interp=1, cubic=-0.5)

    tpos = [0,0,0.5,1]
    sgtv, bytscl(reform(orig_images[time_id,*,*]), top=254, min=4000, max=40000), ct=49, position=tpos
    msg = 'a) Orig'
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    xyouts, tx,ty, msg, normal=1
    
    msg = strupcase(site)+', '+time_string(time)+' UT'
    tx = tpos[0]+xchsz*0.5
    ty = tpos[1]+ychsz*0.5
    xyouts, tx,ty, msg, normal=1, charsize=0.8
    
    tpos = [0.5,0,1,1]
    sgtv, bytscl(reform(asf_image), top=254, min=4000, max=40000), ct=49, position=tpos
    msg = 'b) Moon aligned'
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    xyouts, tx,ty, msg, normal=1
    
    sgclose
endforeach

fig2movie, movie_file, fig_files=fig_files


end
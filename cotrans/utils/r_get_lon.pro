function r_get_lon, r_vec, degree=degree

    deg = constant('deg')
    lon = atan(r_vec[*,1],r_vec[*,0])
    if keyword_set(degree) then lon *= deg
    return, lon

end
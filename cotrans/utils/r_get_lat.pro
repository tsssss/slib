function r_get_lat, r_vec, degree=degree

    deg = constant('deg')
    lat = asin(r_vec[*,2]/snorm(r_vec))
    if keyword_set(degree) then lat *= deg
    return, lat

end
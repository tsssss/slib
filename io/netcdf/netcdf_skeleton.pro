;+
; Read or print the skeleton of a cdf file.
;-
pro netcdf_skeleton, cdf0, skeleton, filename=out_file

    nparam = n_params()
    if nparam eq 0 then return
    if ~isa(skeleton, 'dictionary') then skeleton = netcdf_read_skeleton(cdf0)
    if nparam eq 1 then netcdf_print_skeleton, skeleton, filename=out_file

end

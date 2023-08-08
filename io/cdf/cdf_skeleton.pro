;+
; Read or print the skeleton of a cdf file.
;-
pro cdf_skeleton, cdf0, skeleton, filename=out_file

    nparam = n_params()
    if nparam eq 0 then return
    if ~isa(skeleton, 'dictionary') then skeleton = cdf_read_skeleton(cdf0)
    if nparam eq 1 then cdf_print_skeleton, skeleton, filename=out_file

end

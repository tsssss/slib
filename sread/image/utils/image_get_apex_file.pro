function image_get_apex_file

    lib_dir = image_get_lib_dir()
    apex_file = join_path([lib_dir,'support','mlatlon.1997a.xdr'])
    return, apex_file

end
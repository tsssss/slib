function image_get_lib_dir

    my_dir = srootdir()
    my_parent_dir = sparentdir(my_dir)
    image_lib_dir = join_path([my_parent_dir,'libs'])
    return, image_lib_dir

end

print, image_get_lib_dir()
end
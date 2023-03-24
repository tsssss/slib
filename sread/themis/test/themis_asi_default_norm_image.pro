function themis_asi_default_norm_image, images

    zrange = [1e3,1e4]
    norm_images = bytscl(images, max=zrange[1], min=zrange[0], top=254)
    return, reform(norm_images)

end
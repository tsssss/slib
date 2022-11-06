;+
; Get the mesh grid for input 1-D arrays.
;-

function mesh_grid, data_list

    retval = !null

    ndim = n_elements(data_list)
    dims = list()
    for ii=0, ndim-1 do dims.add, n_elements(data_list[ii])
    dims = dims.toarray()

    for ii=0, ndim-1 do if dims[ii] eq 0 then begin
        errmsg = handle_error('Invalid dimensions ...')
        return, retval
    endif
    dtype = size((data_list[0])[0],/type)
    base = make_array(dims, value=1, type=dtype)
    base_index = indgen(ndim)

    mesh_list = list()
    for ii=0, ndim-1 do begin
        the_mesh = transpose(base,shift(base_index,-ii))
        the_ndim = n_elements(data_list[ii])
        for jj=0, the_ndim-1 do the_mesh[jj,*,*,*,*,*,*,*] = (data_list[ii])[jj]
        mesh_list.add, transpose(the_mesh, shift(base_index,ii))
    endfor

    return, mesh_list

end

data_list = list()
data_list.add, [0,1]
data_list.add, [0,1]
data_list.add, [0,1]
data_mesh = mesh_grid(data_list)
end

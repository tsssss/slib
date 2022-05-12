;pro idl_code_gh

  geopack_recalc,2015,01,01, 0, 0,0,/date, tilt=tilt_output

  xgsm = 0.95
  ygsm = 0.5
  zgsm = 5
  
;  xgsm = -10
;  ygsm = 0
;  zgsm = 0

  param = [5,0,1,1,0,0,0,0,0,0]
  geopack_epoch,epo,2015,01,01, 0, 0,0,/compute_epoch

  geopack_t96,param, xgsm, ygsm, zgsm, bx_t96, by_t96, bz_t96, epoch=epo
  geopack_t01,param, xgsm, ygsm, zgsm, bx_t01, by_t01, bz_t01, epoch=epo

  geopack_igrf_gsm, xgsm, ygsm, zgsm, bx_igrf, by_igrf, bz_igrf,epoch=epo
  

  print, [bx_t96, by_t96, bz_t96]
  print, bx_t01, by_t01, bz_t01
  print, bx_igrf, by_igrf, bz_igrf
  ;print, bx_igrf+bx_t96, by_igrf+by_t96, bz_igrf+bz_t96

stop

  v = 61

  ; Make sure increment is same as that of python code np.linspace(-15.1, 15, 61)
  x_gsm = findgen(v,INCREMENT=0.5016666666666669, start=-15)
  y_gsm = findgen(v,INCREMENT=0.5016666666666669, start=-15)
  z_gsm = findgen(v,INCREMENT=0.5016666666666669, start=-15)

  bx_t96 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  by_t96 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  bz_t96 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)

  bx_t01 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  by_t01 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  bz_t01 = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)

  bx_igrf = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  by_igrf = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  bz_igrf = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)

  bx_t96_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  by_t96_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  bz_t96_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)

  bx_t01_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  by_t01_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)
  bz_t01_total = MAKE_ARRAY(v,v,v, /FLOAT, VALUE = -9999)

  lenx = v
  leny = v
  lenz = v
  for xnum = 0, lenx-1 do begin
    for ynum = 0, lenx-1 do begin
      for znum = 0, lenx-1 do begin

        geopack_t96,param,x_gsm[xnum],y_gsm[ynum],z_gsm[znum],bx1, by1, bz1,epoch=epo
        bx_t96[xnum,ynum,znum] = bx1
        by_t96[xnum,ynum,znum] = by1
        bz_t96[xnum,ynum,znum] = bz1

        geopack_t01,param,x_gsm[xnum],y_gsm[ynum],z_gsm[znum], bx2, by2, bz2, epoch=epo
        bx_t01[xnum,ynum,znum] = bx2
        by_t01[xnum,ynum,znum] = by2
        bz_t01[xnum,ynum,znum] = bz2

        geopack_igrf_gsm,x_gsm[xnum],y_gsm[ynum],z_gsm[znum],bx3, by3, bz3, epoch=epo
        bx_igrf[xnum,ynum,znum] = bx3
        by_igrf[xnum,ynum,znum] = by3
        bz_igrf[xnum,ynum,znum] = bz3

        bx_t96_total[xnum,ynum,znum] = bx_t96[xnum,ynum,znum] + bx_igrf[xnum,ynum,znum]
        by_t96_total[xnum,ynum,znum] = by_t96[xnum,ynum,znum] + by_igrf[xnum,ynum,znum]
        bz_t96_total[xnum,ynum,znum] = bz_t96[xnum,ynum,znum] + bz_igrf[xnum,ynum,znum]

        bx_t01_total[xnum,ynum,znum] = bx_t01[xnum,ynum,znum] + bx_igrf[xnum,ynum,znum]
        by_t01_total[xnum,ynum,znum] = by_t01[xnum,ynum,znum] + by_igrf[xnum,ynum,znum]
        bz_t01_total[xnum,ynum,znum] = bz_t01[xnum,ynum,znum] + bz_igrf[xnum,ynum,znum]
        ;print, bz_t01_total[xnum,ynum,znum]
      endfor
    endfor
    print, xnum
  endfor

  ;print, bx_t96_total[50,50,50]

  ;'Enter file name:'
  file = 'idl_data.h5'
  fid = h5f_create(file)

  data_bx_t96 = bx_t96
  bx_t96_type_id = H5T_IDL_CREATE(data_bx_t96)
  bx_t96_space_id = H5S_CREATE_SIMPLE(size(data_bx_t96,/DIMENSIONS))
  bx_t96_set_id = H5D_CREATE(fid,'bx_t96',bx_t96_type_id,bx_t96_space_id)

  data_by_t96 = by_t96
  by_t96_type_id = H5T_IDL_CREATE(data_by_t96)
  by_t96_space_id = H5S_CREATE_SIMPLE(size(data_by_t96,/DIMENSIONS))
  by_t96_set_id = H5D_CREATE(fid,'by_t96',by_t96_type_id,by_t96_space_id)

  data_bz_t96 = bz_t96
  bz_t96_type_id = H5T_IDL_CREATE(data_bz_t96)
  bz_t96_space_id = H5S_CREATE_SIMPLE(size(data_bz_t96,/DIMENSIONS))
  bz_t96_set_id = H5D_CREATE(fid,'bz_t96',bz_t96_type_id,bz_t96_space_id)


  data_bx_t01 = bx_t01
  bx_t01_type_id = H5T_IDL_CREATE(data_bx_t01)
  bx_t01_space_id = H5S_CREATE_SIMPLE(size(data_bx_t01,/DIMENSIONS))
  bx_t01_set_id = H5D_CREATE(fid,'bx_t01',bx_t01_type_id,bx_t01_space_id)

  data_by_t01 = by_t01
  by_t01_type_id = H5T_IDL_CREATE(data_by_t01)
  by_t01_space_id = H5S_CREATE_SIMPLE(size(data_by_t01,/DIMENSIONS))
  by_t01_set_id = H5D_CREATE(fid,'by_t01',by_t01_type_id,by_t01_space_id)

  data_bz_t01 = bz_t01
  bz_t01_type_id = H5T_IDL_CREATE(data_bz_t01)
  bz_t01_space_id = H5S_CREATE_SIMPLE(size(data_bz_t01,/DIMENSIONS))
  bz_t01_set_id = H5D_CREATE(fid,'bz_t01',bz_t01_type_id,bz_t01_space_id)


  data_bx_igrf = bx_igrf
  bx_igrf_type_id = H5T_IDL_CREATE(data_bx_igrf)
  bx_igrf_space_id = H5S_CREATE_SIMPLE(size(data_bx_igrf,/DIMENSIONS))
  bx_igrf_set_id = H5D_CREATE(fid,'bx_igrf',bx_igrf_type_id,bx_igrf_space_id)

  data_by_igrf = by_igrf
  by_igrf_type_id = H5T_IDL_CREATE(data_by_igrf)
  by_igrf_space_id = H5S_CREATE_SIMPLE(size(data_by_igrf,/DIMENSIONS))
  by_igrf_set_id = H5D_CREATE(fid,'by_igrf',by_igrf_type_id,by_igrf_space_id)

  data_bz_igrf = bz_igrf
  bz_igrf_type_id = H5T_IDL_CREATE(data_bz_igrf)
  bz_igrf_space_id = H5S_CREATE_SIMPLE(size(data_bz_igrf,/DIMENSIONS))
  bz_igrf_set_id = H5D_CREATE(fid,'bz_igrf',bz_igrf_type_id,bz_igrf_space_id)


  data_bx_t96_total = bx_t96_total
  bx_t96_total_type_id = H5T_IDL_CREATE(data_bx_t96_total)
  bx_t96_total_space_id = H5S_CREATE_SIMPLE(size(data_bx_t96_total,/DIMENSIONS))
  bx_t96_total_set_id = H5D_CREATE(fid,'bx_t96_total',bx_t96_total_type_id,bx_t96_total_space_id)

  data_by_t96_total = by_t96_total
  by_t96_total_type_id = H5T_IDL_CREATE(data_by_t96_total)
  by_t96_total_space_id = H5S_CREATE_SIMPLE(size(data_by_t96_total,/DIMENSIONS))
  by_t96_total_set_id = H5D_CREATE(fid,'by_t96_total',by_t96_total_type_id,by_t96_total_space_id)

  data_bz_t96_total = bz_t96_total
  bz_t96_total_type_id = H5T_IDL_CREATE(data_bz_t96_total)
  bz_t96_total_space_id = H5S_CREATE_SIMPLE(size(data_bz_t96_total,/DIMENSIONS))
  bz_t96_total_set_id = H5D_CREATE(fid,'bz_t96_total',bz_t96_total_type_id,bz_t96_total_space_id)

  data_bx_t01_total = bx_t01_total
  bx_t01_total_type_id = H5T_IDL_CREATE(data_bx_t01_total)
  bx_t01_total_space_id = H5S_CREATE_SIMPLE(size(data_bx_t01_total,/DIMENSIONS))
  bx_t01_total_set_id = H5D_CREATE(fid,'bx_t01_total',bx_t01_total_type_id,bx_t01_total_space_id)

  data_by_t01_total = by_t01_total
  by_t01_total_type_id = H5T_IDL_CREATE(data_by_t01_total)
  by_t01_total_space_id = H5S_CREATE_SIMPLE(size(data_by_t01_total,/DIMENSIONS))
  by_t01_total_set_id = H5D_CREATE(fid,'by_t01_total',by_t01_total_type_id,by_t01_total_space_id)

  data_bz_t01_total = bz_t01_total
  bz_t01_total_type_id = H5T_IDL_CREATE(data_bz_t01_total)
  bz_t01_total_space_id = H5S_CREATE_SIMPLE(size(data_bz_t01_total,/DIMENSIONS))
  bz_t01_total_set_id = H5D_CREATE(fid,'bz_t01_total',bz_t01_total_type_id,bz_t01_total_space_id)

  H5D_WRITE,bx_t96_set_id, data_bx_t96
  H5D_WRITE,by_t96_set_id, data_by_t96
  H5D_WRITE,bz_t96_set_id, data_bz_t96

  H5D_WRITE,bx_t01_set_id, data_bx_t01
  H5D_WRITE,by_t01_set_id, data_by_t01
  H5D_WRITE,bz_t01_set_id, data_bz_t01

  H5D_WRITE,bx_igrf_set_id, data_bx_igrf
  H5D_WRITE,by_igrf_set_id, data_by_igrf
  H5D_WRITE,bz_igrf_set_id, data_bz_igrf

  H5D_WRITE,bx_t96_total_set_id, data_bx_t96_total
  H5D_WRITE,by_t96_total_set_id, data_by_t96_total
  H5D_WRITE,bz_t96_total_set_id, data_bz_t96_total

  H5D_WRITE,bx_t01_total_set_id, data_bx_t01_total
  H5D_WRITE,by_t01_total_set_id, data_by_t01_total
  H5D_WRITE,bz_t01_total_set_id, data_bz_t01_total

  H5D_CLOSE,bx_t96_set_id
  H5S_CLOSE,by_t96_space_id
  H5T_CLOSE,bz_t96_type_id

  H5D_CLOSE,bx_t01_set_id
  H5S_CLOSE,by_t01_space_id
  H5T_CLOSE,bz_t01_type_id

  H5D_CLOSE,bx_igrf_set_id
  H5S_CLOSE,by_igrf_space_id
  H5T_CLOSE,bz_igrf_type_id

  H5D_CLOSE,bx_t96_total_set_id
  H5S_CLOSE,by_t96_total_space_id
  H5T_CLOSE,bz_t96_total_type_id

  H5D_CLOSE,bx_t01_total_set_id
  H5S_CLOSE,by_t01_total_space_id
  H5T_CLOSE,bz_t01_total_type_id
  H5F_CLOSE,fid
end

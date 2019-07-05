;+
; Return a boolean, 1/0 for has/no connection to a given server.
;
; server. A string (optional) for a server. If not set, then just refer to
;   the internet in general.
; timeout=. A number in sec to set the maximum wait time. Default is 20.
;-

function net_check_connection, server, timeout=timeout, errmsg=errmsg
    errmsg = errmsg
    retval = !null

    catch, err
    if err ne 0 then begin
        obj_destroy, oo
        catch, /cancel
        errmsg = !error_state.msg
        return, retval
    endif

    url = (n_elements(server) eq 0)? 'https://www.google.com': server
    if n_elements(timeout) eq 0 then timeout = 20.

    url_info = parse_url(server)
    if url_info.scheme eq '' then begin
        server = 'http://'+server
        url_info = parse_url(server)
    endif
    ; Can be 'http','https','ftp','sftp'.
    scheme = strlowcase(url_info.scheme)

    oo = obj_new('IDLnetURL')
    oo->setproperty, connect_timeout=timeout
    oo->setproperty, url_scheme=scheme
    oo->setproperty, url_username=url_info.username
    oo->setproperty, url_password=url_info.password
    oo->setproperty, url_host=url_info.host
    oo->setproperty, ftp_connection_mode=0 ; set to passive mode to avoid firewalls

    if scheme eq 'ftp' or scheme eq 'sftp' then begin
        tmp = oo->getftpdirlist(/short)
        oo->getproperty, response_code=status_code
    endif else begin
        header = net_request_header(server, status_code=status_code, timeout=timeout)
        if header[0] eq '' then status_code = 404
    endelse
    obj_destroy, oo

    has_connection = (status_code lt 400 or status_code gt 500)
    return, has_connection

end

urls = list()
urls.add, 'www.google.com'
urls.add, 'https://www.google.com'
urls.add, 'ftp://swarm0555:othonwoo01@swarm-diss.eo.esa.int/Level1b/Latest_baselines/MAGx_LR'
urls.add, 'sftp://swarm-diss.eo.esa.int/Level1b/Latest_baselines/MAGx_LR'
foreach url, urls do print, check_network_connection(url)
end

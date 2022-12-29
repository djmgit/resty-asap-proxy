local shell = require "resty.shell"

local _M = {}

local str_const = {
    asap_issuer = "ASAP_ISSUER",
    asap_private_key = "ASAP_PRIVATE_KEY"
}


--@function tokensie a uri into components, split by /
--@param uri string the uri to tokenise
--@return table[strings] list of components
function tokenise_url(uri)
    url_components = {}
    for elem in string.gmatch(uri, "([^/]+)") do
        table.insert(url_components, elem)
    end
    return url_components
end


--@function generate and return asap token
--@param asap_audience string audience to use for the asap request
--return Table[string,string] Table containg asap token as response else stderr as error and status, reason.
function generate_asap_token(asap_audience)
    local asap_issuer = os.getenv(str_const.asap_issuer)
    local asap_private_key = os.getenv(str_const.asap_private_key)
    stdin = asap_issuer.." "..asap_private_key.." "..asap_audience
    
    -- use shell module to invoke python script. This is non-blocking IO
    local ok, stdout, stderr, reason, status = shell.run([[python3 lib/lua-resty-asap/lib/python/script.py]], stdin)
    
    if not ok then
        return {error=stderr, reason=reason, status=status}
    end
    return {response=stdout, status=status}
end


--@function get target host, the target uri and audience from the host
--          for example if the uri is /proxy/myapi.app.net/api/user/1 then
--          the target host is myapi.app.net, target uri is /api/user/1
--          and audience is myapi
--@param uri string the complete request uri
--return table(string,string) table container target_host, target_uri, asap_audience
function get_target_host_uri_audience(uri)
    url_components = tokenise_url(uri)
    target_host = url_components[2]
    target_uri = ""

    -- every thing after /proxy/<host> is the target uri
    for i = 3, #url_components, 1 do
        target_uri = target_uri.."/"..url_components[i]
    end
    if uri[#uri] == "/" then
        target_uri = target_uri.."/"
    end

    --- the first part of the domain or the service name is considered as the audience.
    --- this might not always be true but this is the convention we are following here.
    asap_audience = string.sub(target_host, 0, string.find(target_host, "%.")-1)

    return {target_host=target_host, target_uri=target_uri, asap_audience=asap_audience}

end


--@function set the asap header, the target host var got proxy pass and the target uri
function _M.setup_asap()
    r = get_target_host_uri_audience(ngx.var.request_uri)
    response = generate_asap_token(r.asap_audience)
    if response.error then
        ngx.say(response.error)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    jwt_token = response.response

    -- this is important! When reading from stdout the last character we get is %0A. We
    -- need to get rid of this, hence we we omit the last character.
    jwt_token = string.sub(jwt_token, 1, #jwt_token - 1)
    ngx.req.set_header("Authorization", jwt_token)

    ngx.var.target_host = r.target_host

    -- if our uri has url params, we need to get rid of those. Since we are doing a proxy_pass,
    -- nginx will automatically forward the url params as well. Setting the uri with url params
    -- will result in adding url params twice like /endpoint?param=1?param=1 which we dont want.
    if string.find(r.target_uri, "%?") ~= nil then
        target_uri_without_args = string.sub(r.target_uri, 1, string.find(r.target_uri, "%?")-1)
    else
        target_uri_without_args = r.target_uri
    end
    ngx.req.set_uri(target_uri_without_args)
                
end

return _M

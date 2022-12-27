local shell = require "resty.shell"

local _M = {}

local str_const = {
    asap_issuer = "ASAP_ISSUER",
    asap_private_key = "ASAP_PRIVATE_KEY"
}

function tokenise_url(uri)
    url_components = {}
    for elem in string.gmatch(uri, "([^/]+)") do
        table.insert(url_components, elem)
    end
    return url_components
end

function generate_asap_token(asap_audience)
    local asap_issuer = os.getenv(str_const.asap_issuer)
    local asap_private_key = os.getenv(str_const.asap_private_key)
    stdin = asap_issuer.." "..asap_private_key.." "..asap_audience
    
    local ok, stdout, stderr, reason, status = shell.run([[python3 lib/lua-resty-asap/lib/python/script.py]], stdin)
    
    if not ok then
        return {error=stderr, reason=reason, status=status}
    end
    return {response=stdout, status=status}
end

function get_target_host_uri_audience(uri)
    url_components = tokenise_url(uri)
    target_host = url_components[2]
    target_uri = ""
    for i = 3, #url_components, 1 do
        target_uri = target_uri.."/"..url_components[i]
    end
    if uri[#uri] == "/" then
        target_uri = target_uri.."/"
    end
    asap_audience = string.sub(target_host, 0, string.find(target_host, "%.")-1)

    return {target_host=target_host, target_uri=target_uri, asap_audience=asap_audience}

end

function _M.setup_asap()
    r = get_target_host_uri_audience(ngx.var.request_uri)
    response = generate_asap_token(r.asap_audience)
    if response.error then
        ngx.say(response.error)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    jwt_token = response.response
    jwt_token = string.sub(jwt_token, 1, #jwt_token - 1)
    ngx.req.set_header("Authorization", jwt_token)

    ngx.var.target_host = r.target_host
    if string.find(r.target_uri, "%?") ~= nil then
        target_uri_without_args = string.sub(r.target_uri, 1, string.find(r.target_uri, "%?")-1)
    else
        target_uri_without_args = r.target_uri
    end
    ngx.req.set_uri(target_uri_without_args)
                
end

return _M

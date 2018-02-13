-- 
-- Check Client Certificate & ACL
-- 

-- Import - IP Tools
local iputils = require "resty.iputils"

-- Import - Rate Limit
local limit_count = require "resty.limit.count"
local limit_conn = require "resty.limit.conn"
local limit_traffic = require "resty.limit.traffic"


----------------------------------------------
iputils.enable_lrucache()
local whitelist_ips = {
  "127.0.0.1",
  "10.10.10.0/24",
  "192.168.0.0/16",
}

GLOBAL_IPWhitelist = iputils.parse_cidrs(whitelist_ips)
----------------------------------------------


-- Log 
ngx.log(ngx.INFO, 'Check Client SSL Status - ', ngx.var.ssl_client_verify)

-- Did We Had A Valid Client SSL ?
-- Fallback To IP Auth If No Client SSL Is Present
if ngx.var.ssl_client_verify ~= "SUCCESS" then

	-- We Were Not Authorized By SSL Check The IP
	if not iputils.ip_in_cidrs(ngx.var.remote_addr, GLOBAL_IPWhitelist) then
		return ngx.exit(444)
	end

end

-- Log
ngx.log(ngx.INFO, "Passed SSL / IP Validation")

-- 
-- Rate Limit
-- 

-- Rate Limiters 

-- rate: 5000 requests per 3600s
-- https://github.com/openresty/lua-resty-limit-traffic/blob/master/lib/resty/limit/count.md
local LimitCount, ErrCount = limit_count.new("ssl_ip_count", 200, 5)

-- limit the requests under 200 concurrent requests with
-- a burst of 100 extra concurrent requests, that is, we delay
-- requests under 300 concurrent connections and above 200
-- connections, and reject any new requests exceeding 300 also, we assume a default request time of 0.5 sec
-- https://github.com/openresty/lua-resty-limit-traffic/blob/master/lib/resty/limit/conn.md
local LimitConn, ErrConn = limit_conn.new("ssl_ip_conn", 200, 100, 0.5)

-- Limiters List
local LimitersObj = {LimitCount, LimitConn}

-- Key Pairs
local KeysObj = {ngx.var.host, ngx.var.binary_remote_addr, ngx.var.binary_remote_addr}

-- Local States
local StateObj = {}

-- Combine And Return Result
local LimitDelay, LimitErr = limit_traffic.combine(LimitersObj, KeysObj, StateObj)

-- Check If We Shoud Delay
if not LimitDelay then

	-- Reject This Request
	if LimitErr == "rejected" then
		return ngx.exit(444)
	end

	-- Log
	ngx.log(ngx.ERR, "Failed To Limit Traffic Due To - ", LimitErr)

	-- Handoff
	return ngx.exit(500)

end

-- Delay This Request
if LimitDelay >= 0.001 then

	-- Log
	ngx.log(ngx.ERR, 'Delaying Request For ', LimitDelay, ' With State ', table.concat(StateObj, ", "))

	-- Delay Request
	ngx.sleep(LimitDelay)

end

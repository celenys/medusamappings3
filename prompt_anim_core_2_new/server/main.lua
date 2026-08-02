local config = require 'config.config_s'
local cconfig = require 'config.config_c'

lib.locale(cconfig.language ~= 'auto' and cconfig.language or nil)

SetConvarReplicated('ox:printlevel:' .. cache.resource, config.debug and 'debug' or 'info')

require 'server.callbacks'
require 'server.events'
if config.stats.enable then
    require 'server.threads'
end
require 'server.exports'

if config.gymCreator.enable then
    require 'server.creator'
end
if cconfig.boxingRing.enable then
    require 'server.boxing_ring'
end
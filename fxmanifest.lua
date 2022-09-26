fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'vSyncRevamped'
version '2.0.0'

shared_scripts {
	'config.lua',
	'@psr-core/shared/locale.lua',
	'locales/en.lua'
}

server_script 'server/server.lua'
client_script 'client/client.lua'

description 'ESX Races'

version '0.2.5'


dependencies {
  "mysql-async"
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'server/esx_races_sv.lua',
	'config.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'client/esx_races_cl.lua'
}
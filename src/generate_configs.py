from os import replace
import yaml

# Attempt to load user config data
try:
    with open('/opt/stig/config/userconfig.yaml','r') as cfile:
        config_data = yaml.safe_load(cfile)
except:
    print("Error loading YAML config file!")

# Pull in config templates
# For now, we are just testing telegraf
try:
    with open('/opt/stig/telegraf/telegraf.conf.temp','r') as tfile:
        telegraf_temp = tfile.read()
except:
    print("Error opening template!")

# Create the connection strings for the SQL hosts
conn_strings = ""
for host in config_data['telegraf']['sql_plugin']['hosts']:
    conn_strings += '    "Server={};Port={};User Id={};Password={};app name=STIG - Telegraf;",\r\n'.format(host['host'],host['port'],host['username'],host['password'])

# Write the new telegraf config
try:
    with open('/opt/stig/telegraf/telegraf.conf','w') as tconf:
        tconf.write(telegraf_temp.replace('{{conn_strings}}',conn_strings))
except:
    print('Error writing config file!')
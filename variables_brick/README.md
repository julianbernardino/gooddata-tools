# Variables Brick
This brick assigns variable values at the user level for one or more workspaces.

*Coming soon:* ability to toggle between workspace level variable assignment (default variable values) and user level variable assignment

## Prerequisites

1. A mapping table, `vb_var_map`, which contains the following fields. See appendix.
```
login, variable, value, label, client_id
```

2. A mapping table, `vb_pid_map`, which contains the following fields. See appendix.
```
client_id, pid
```

3. An input source table, `vb_input`, which is used directly by the brick.
```
login, variable, value, label, pid
```

## Steps

1. Ensure that the prerequisite tables exist and are populated.
2. Deploy script with the following parameters to the environment's SERVICE workspace.

| Parameter | Example Value |
| --- | --- |
| gd_encoded_params | (see appendix) |
| CLIENT_GDC_HOSTNAME | secure.gooddata.com |
| GDC_USERNAME | ps-etl+tech-user@gooddata.com |
| GDC_PASSWORD | (secure parameter) |
| ads_client\|username | ps-etl+tech-user@gooddata.com |
| ads_client\|password | (secure parameter) |

## Appendix

Example value for `gd_encoded_params`:
```
{
  "input_source": {
    "type": "ads",
    "query": "SELECT login, variable, value, label, pid FROM vb_input"
  },
  "ads_client": {
    "ads_id": "ADS_ID",
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example data for `vb_var_map`:
```
login,variable,value,label,client_id
spongebob@krustykrab.com,YxdT5fpMfoef,'sales',label.dept.dept,krustykrab
spongebob@krustykrab.com,YxdT5fpMfoef,'facilities',label.dept.dept,krustykrab
patrick@krustykrab.com,YxdT5fpMfoef,'marketing',label.dept.dept,krustykrab
squidward@krustykrab.com,YxdT5fpMfoef,'finance',label.dept.dept,krustykrab
mrspuff@puffsboatingschool.com,YxdT5fpMfoef,'services',label.dept.dept,puffsboatingschool
```

Example data for `vb_pid_map`:
```
client_id,pid
krustykrab,8t7yjpgwu74u8csup28ywur2asktvbw5
puffsboatingschool,na9djp97y9crtatkh9snvswjs7r365jh
```

Example result for `vb_input`:
```
login,variable,value,label,client_id
spongebob@krustykrab.com,YxdT5fpMfoef,'sales',label.dept.dept,8t7yjpgwu74u8csup28ywur2asktvbw5
spongebob@krustykrab.com,YxdT5fpMfoef,'facilities',label.dept.dept,8t7yjpgwu74u8csup28ywur2asktvbw5
patrick@krustykrab.com,YxdT5fpMfoef,'marketing',label.dept.dept,8t7yjpgwu74u8csup28ywur2asktvbw5
squidward@krustykrab.com,YxdT5fpMfoef,'finance',label.dept.dept,8t7yjpgwu74u8csup28ywur2asktvbw5
mrspuff@puffsboatingschool.com,YxdT5fpMfoef,'services',label.dept.dept,na9djp97y9crtatkh9snvswjs7r365jh
```
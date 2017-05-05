# Variables Brick
This brick assigns variable values at the user level for one or more workspaces.

## Prerequisites
1. A mapping table, `vb_var_map`, which contains the following fields:
```
login, variable, value, label, client_id
```

2. A mapping table, `vb_pid_map`, which contains the following fields:
```
client_id, pid
```

3. A table joining the preceding two, `vb_input`, which is used as the input source for the brick:
```
login, variable, value, label, pid
```

## Steps

1. Ensure that the prequisite tables exist and are populated.
2. Deploy script with following parameters.

| Parameter | Example Value |
| --- | --- |
| gd_encoded_params | (see below) |
| CLIENT_GDC_HOSTNAME | secure.gooddata.com |
| GDC_USERNAME | ps-etl+tech-user@gooddata.com |
| GDC_PASSWORD | (secure parameter) |
| ads_client\|username | ps-etl+tech-user@gooddata.com |
| ads_client\|password | (secure parameter) |

Example Value - gd_encoded_params:
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

## Appendix

Example Data for `vb_var_map`:
```
login,variable,value,label,client_id
spongebob@krustykrab.com,YxdT5fpMfoef,'sales',label.dept.dept,krustykrab
spongebob@krustykrab.com,YxdT5fpMfoef,'facilities',label.dept.dept,krustykrab
patrick@krustykrab.com,YxdT5fpMfoef,'marketing',label.dept.dept,krustykrab
squidward@krustykrab.com,YxdT5fpMfoef,'finance',label.dept.dept,krustykrab
mrspuff@puffboating.com,YxdT5fpMfoef,'services',label.dept.dept,puffboating
```

Example Data for `vb_pid_map`:
```
client_id,pid
8t7yjpgwu74u8csup28ywur2asktvbw5,krustykrab
na9djp97y9crtatkh9snvswjs7r365jh,puffboatingschool
```

# Variables Brick
This brick assigns variable values at the user level for one or more workspaces.

*Coming soon:* ability to toggle between workspace level variable assignment (default variable values) and user level variable assignment

## Prerequisites

The brick requires only one input source table, `vb_input`, which is referenced directly at runtime. See appendix.
```
login, variable, value, label, client_id
```

## Steps

Deploy script with the following parameters to the environment's SERVICE workspace.

| Parameter | Example Value |
| --- | --- |
| gd_encoded_params | (see appendix) |
| CLIENT_GDC_HOSTNAME | secure.gooddata.com |
| CLIENT_GDC_PROTOCOL | https |
| GDC_USERNAME | ps-etl+tech-user@gooddata.com |
| GDC_PASSWORD | (secure parameter) |
| ads_client\|username | ps-etl+tech-user@gooddata.com |
| ads_client\|password | (secure parameter) |
| organization | organization_name |
| segment | segment_name |

## Appendix

Example value for `gd_encoded_params`:
```
{
  "input_source": {
    "type": "ads",
    "query": "SELECT login, variable, value, label, client_id FROM vb_input"
  },
  "ads_client": {
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example result for `vb_input`:
```
login,variable,value,label,client_id
spongebob@krustykrab.com,YxdT5fpMfoef,'sales',label.dept.dept,krustykrab
spongebob@krustykrab.com,YxdT5fpMfoef,'facilities',label.dept.dept,krustykrab
patrick@krustykrab.com,YxdT5fpMfoef,'marketing',label.dept.dept,krustykrab
squidward@krustykrab.com,YxdT5fpMfoef,'finance',label.dept.dept,krustykrab
mrspuff@puffsboatingschool.com,YxdT5fpMfoef,'services',label.dept.dept,puffsboatingschool
```
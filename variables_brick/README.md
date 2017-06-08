# Variables Brick
This brick assigns variable values at the user level for one or more workspaces.

*Coming soon:* ability to toggle between workspace level variable assignment (default variable values) and user level variable assignment

## Prerequisites

The brick requires only one input source table, `vb_input`, which is referenced directly at runtime. See appendix.
```
client_id, login, label, variable, value
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
    "query": "SELECT client_id, login, label, variable, value FROM vb_input"
  },
  "ads_client": {
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example result for `vb_input`:
```
client_id,login,label,variable,value
krustykrab,spongebob@krustykrab.com,label.dept.dept,YxdT5fpMfoef,'sales'
krustykrab,spongebob@krustykrab.com,label.dept.dept,YxdT5fpMfoef,'facilities'
krustykrab,patrick@krustykrab.com,label.dept.dept,YxdT5fpMfoef,'marketing'
krustykrab,squidward@krustykrab.com,label.dept.dept,YxdT5fpMfoef,'finance'
puffsboatingschool,mrspuff@puffsboatingschool.com,label.dept.dept,YxdT5fpMfoef,'services'
```
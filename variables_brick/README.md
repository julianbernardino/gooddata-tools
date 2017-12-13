# Variables Brick
This brick assigns variable values for workspaces within a segment.

It can toggle between workspace-level assignment, i.e. default variable values, and user-level assignment.

## Prerequisites

The brick requires an input source table `lcm_variable` with the following fields. You are allowed to change the table name but not the field names. See appendix.

Fields for `sync_mode = workspace`:
```
client_id, label, variable, value
```

Fields for `sync_mode = user`:
```
client_id, login, label, variable, value
```

## Deployment

Pick one of two options for deployment. Both require the same set of parameters specified below. 
- Deploy to a **MASTER workspace**, then run a release and rollout. Variables will be assigned in each client workspace by independent executions.
- Deploy to a **SERVICE workspace**. Variables will be assigned in the selected segment's workspaces by a single execution.

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
| sync_mode | user |

## Appendix

Example value for `gd_encoded_params` if `sync_mode = workspace`:
```
{
  "input_source": {
    "type": "ads",
    "query": "SELECT client_id, label, variable, value FROM lcm_variable"
  },
  "ads_client": {
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example value for `gd_encoded_params` if `sync_mode = user`:
```
{
  "input_source": {
    "type": "ads",
    "query": "SELECT client_id, login, label, variable, value FROM lcm_variable"
  },
  "ads_client": {
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example data for `lcm_variable` if `sync_mode = workspace`:
```
client_id,label,variable,value
baratheon,label.location.location,A3nbo7Ws2mpq,stormlands
lannister,label.location.location,A3nbo7Ws2mpq,casterlyrock
stark,label.location.location,A3nbo7Ws2mpq,winterfell
```

Example data for `lcm_variable` if `sync_mode = user`:
```
client_id,login,label,variable,value
baratheon,robert@baratheon.com,label.dept.dept,YxdT5fpMfoef,devops
baratheon,stannis@baratheon.com,label.dept.dept,YxdT5fpMfoef,devops
lannister,jaime@lannister.com,label.dept.dept,YxdT5fpMfoef,finance
stark,ned@stark.com,label.dept.dept,YxdT5fpMfoef,marketing
stark,ned@stark.com,label.dept.dept,YxdT5fpMfoef,product
```
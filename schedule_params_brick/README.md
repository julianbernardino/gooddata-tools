# Schedule Params Brick
This brick sets schedule parameter values for all workspaces within a segment.

By design, it does not support secure parameters.

## Prerequisites

The brick requires an input source table `lcm_schedule_param` with the following fields. You are allowed to change the table name but not the field names. See appendix.

Fields:
```
client_id, schedule_name, param_name, param_value
```

Only schedule parameters that will be created or updated by the brick should be loaded to `lcm_schedule_param`. Existing schedule parameters that are missing from the input source will not be affected.

## Deployment

Deploy to a **SERVICE workspace** with the following parameters:

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
    "query": "SELECT client_id, schedule_name, param_name, param_value FROM lcm_schedule_param"
  },
  "ads_client": {
    "jdbc_url": "jdbc:gdc:datawarehouse://HOSTNAME:443/gdc/datawarehouse/instances/ADS_ID"
  }
}
```

Example data for `lcm_schedule_param`:
```
"client_id","schedule_name","param_name","param_value"
"baratheon","etl_initialize","client_group","south"
"lannister","etl_initialize","client_group","south"
"stark","etl_initialize","client_group","north"
```
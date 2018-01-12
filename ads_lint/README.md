# ADS Lint (Beta)
This tool automatically reviews your ADS queries and guides you on how to optimize them. 

## How It Works

ADS Lint will:
- Run an EXPLAIN on all of the queries in a target directory.
- Write query plans to a separate directory. This directory is timestamped and specific to each lint execution so you can easily compare plans as you update your queries.
- Flag queries and plans if certain keywords are present or missing. Keywords are configurable.
- Filter out low priority changes by ignoring query plans that fall below your defined cost minimum.
- Extract join keys and compare table sizes to provide projection recommendations. **ADS Lint will find the best key for ordering and segmentation** even when one table is joined to multiple tables on different keys across different files.

The output of ADS Lint is a summary file that shows queries above your cost threshold, flagged keywords, and suggested projection clauses.

By default, it will flag:
- Resegmentation
- Broadcasting
- High cost
- Hash joins
- Group by hash
- SELECT * anti-pattern
- Missing DIRECT hint
- Missing ANALYZE_STATISTICS

## Usage

Ready to boost your productivity?

1. Download and unzip this package
2. Update the mandatory parameters in config.json
3. Make sure you're using jruby (9.0+). If you're using rvm, run:
```
rvm install jruby
rvm list
rvm use jruby-x.x.x.x
```
4. Install dependencies:
```
bundle install
```
5. Go to the unzipped package and run the executable:
```
ruby ads_lint.rb
```

## Parameters

| Parameter | Description |
| --- | --- |
| dir_dml | local source directory containing queries to be reviewed |
| dir_qp | local target directory to write EXPLAIN output (default: ./qp) |
| ads_username | self-explanatory |
| ads_password | self-explanatory |
| ads_hostname | customer.na.gooddata.com, analytics.customer.com, etc. |
| ads_instance_id | instance id only, do not write jdbc url |
| cost_minimum | only queries above this value will be flagged (default: 10M) |
| projection_recommendations | OFF or ON (default: ON) |

Abbreviations (K: thousands, M: millions, B: billions) for the cost_minimum value are supported. For example, 300,000 and 300K are equivalent.

## Limitations

The current version of ADS Lint:
- Cannot provide projection recommendations for queries that alias table or field names. If some of your queries use aliases, please set "projection_recommendations" to "OFF" in the configuration file.
- Cannot support multiple INSERT or MERGE statements within a single file. If there is no need for the statements to be sequential, consider a UNION ALL. Also consider splitting them into multiple files.
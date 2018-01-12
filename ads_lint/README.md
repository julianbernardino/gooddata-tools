# ADS Lint
This tool automatically reviews your ADS queries and guides you on how to optimize them. 

## How It Works

ADS Lint will:
- Run an EXPLAIN on all of the queries in a target directory.
- Write query plans to a separate directory. This directory is timestamped and specific to each lint execution so you can easily compare plans as you update your queries.
- Flag queries and plans if certain keywords are present or missing. Keywords are configurable.
- Ignore query plans that fall below your defined cost minimum, allowing you to focus on what matters.
- Extract join keys and compare table sizes to provide projection recommendations. When one table is joined to multiple tables on different keys, **ADS Lint will find the best key for segmentation.** This is true both within queries and across the entire set of queries.

The output of ADS Lint is a summary file that shows queries above your cost threshold, flagged keywords, and suggested projection clauses.

By default, it will flag:
- Resegmentation
- Broadcasting
- High cost
- Hash joins
- Group by hash
- SELECT * anti-pattern
- Missing /*+DIRECT*/ if an INSERT or MERGE command
- Missing ANALYZE_STATISTICS

## Usage

Ready to boost your productivity? To use ADS lint, simply;

1. Download and unzip this package
2. Update the mandatory parameters in config.json
3. Make sure you're using jruby in your shell
```
rvm install jruby
rvm list
rvm use jruby-x.x.x.x
```
4. Navigate to the unzipped package
5. Run ads_lint.rb:
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

Abbreviations (K: thousands, M: millions, B: billions) for the cost_minimum value are supported. For example, 300000 and 300K are equivalent.

## Limitations

The current version of ADS Lint cannot provide projection recommendations for queries that alias table or field names. If your queries use aliases, please set "projection_recommendations" to "OFF" in the configuration file.

ADS Lint does not currently support multiple INSERT or MERGE statements within a single file.
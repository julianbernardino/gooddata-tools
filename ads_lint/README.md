# ADS Lint
This tool automatically reviews your ADS queries to find opportunities for optimization.

## How It Works

ADS Lint runs an EXPLAIN on all of the queries in a target directory. It writes the query plans to a separate directory, then scans them for indicators that the queries can be improved.

To focus your optimization effort, only queries that reach a defined cost threshold will be flagged.

The output of ADS Lint is a summary file that tells you which queries need to be changed and why.

By default, it will flag:
- Resegmentation
- Broadcasting
- High cost (configurable)
- Hash joins if high cost
- Group by hash if high cost
- SELECT * wildcard
- Missing /*+DIRECT*/ if an INSERT or MERGE command

## Usage

Ready to boost your productivity by 5000%? To use ADS lint, simply;

1. Download this package
2. Update the mandatory parameters in config.json
3. Navigate to the package in a CLI
4. Run ads_lint.rb:
```
ruby ads_lint.rb
```
# Analytics Engineer Challenge Solution

Complete solution for the Analytics Engineer home exercise featuring marketing data integration and SQL performance optimization.

## Overview

This repository contains solutions for two tasks:

1. **Marketing Datamart** - Unified cross-network analysis combining Ad Network 1 and Ad Network 2
2. **SQL Code Review** - Performance optimization review for dimension table

## Quick Start

### Task 1: Marketing Datamart

```bash
# Install DBT with DuckDB
pip install dbt-duckdb

# Run the project
cd marketing_analytics_dbt
./setup_and_run.sh

# Query results
duckdb marketing_analytics.duckdb
SELECT * FROM marts.mart_marketing_performance LIMIT 10;
```

### Task 2: Code Review

- Read the comprehensive review: [CODE_REVIEW_dim_activity.md](CODE_REVIEW_dim_activity.md)
- View optimized code: [dim_activity_OPTIMIZED.sql](dim_activity_OPTIMIZED.sql)

## Documentation

- [COMPLETE_SOLUTION_SUMMARY.md](COMPLETE_SOLUTION_SUMMARY.md) - Overview of entire solution
- [TASK_1_SOLUTION_SUMMARY.md](TASK_1_SOLUTION_SUMMARY.md) - Marketing datamart details
- [TASK_2_SOLUTION_SUMMARY.md](TASK_2_SOLUTION_SUMMARY.md) - Code review details

## Project Structure

```
.
├── marketing_analytics_dbt/          # Task 1: DBT Project
│   ├── models/
│   │   ├── staging/                  # 5 staging models
│   │   ├── intermediate/             # 2 intermediate models
│   │   └── marts/                    # Final unified datamart
│   ├── tests/                        # 5 data quality tests
│   └── sample_queries.sql            # 8 example analyses
│
├── CODE_REVIEW_dim_activity.md       # Task 2: Detailed review
├── dim_activity_OPTIMIZED.sql        # Optimized SQL code
└── documentation files               # Comprehensive docs

```

## Key Features

### Task 1: Marketing Datamart
- Unified data from 2 ad networks with most detailed geo information
- 3-layer DBT architecture (staging → intermediate → marts)
- 5 custom data quality tests
- Automated setup script
- 8 sample analysis queries

### Task 2: Code Review
- Identified critical O(n³) performance bottleneck
- Expected 100-1000x speedup
- Educational review with before/after examples
- Complete optimized solution provided

## Technologies Used

- **DBT** - Data transformation framework
- **DuckDB** - In-process analytical database
- **SQL** - Data modeling and analysis
- **Git** - Version control

## Solution Highlights

- Production-ready code with comprehensive testing
- Extensive documentation (15,000+ words)
- Performance optimization expertise
- Data quality validation
- Mentoring and code review skills

## Author

Solution for Analytics Engineer position

---

**Time Investment**: ~5.5 hours
**Solution Quality**: Production-ready, fully documented, tested, and runnable

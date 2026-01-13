markdown

# eCommerce Analytics Lakehouse

## Project Overview

Building a production-quality eCommerce analytics data platform from scratch using modern cloud data engineering patterns and tools.

### Learning Objectives
- Master SQL fundamentals (OLTP & OLAP design)
- Learn Azure cloud data services (ADF, Databricks, Synapse)
- Implement data quality and governance patterns
- Build professional Power BI semantic models
- Practice Git version control and team workflows

### Architecture

```
Data Sources (CSV, SQL, API)
    ↓
Azure Data Factory (Orchestration)
    ↓
Databricks (Transformations)
    ↓
Medallion Architecture (Bronze/Silver/Gold)
    ↓
Azure Synapse SQL (Analytics Warehouse)
    ↓
Power BI (Analytics & Dashboards)
```

### Project Structure

- **phase1_sql/** — SQL fundamentals (OLTP, star schema)
- **phase2_azure/** — Cloud migration (ADF, Databricks, Medallion)
- **phase3_production/** — Production ready (Synapse, Power BI, documentation)

### Tech Stack

- SQL Server (local development)
- Azure Data Factory (orchestration)
- Databricks (PySpark, Spark SQL, Delta Lake)
- Azure Synapse SQL (data warehouse)
- Power BI (analytics & visualization)
- Git (version control)

### Timeline

- Phase 1: 12-15 hours (SQL Foundation + Git)
- Phase 2: 15-18 hours (Cloud Migration + Medallion)
- Phase 3: 13-17 hours (Production + Power BI + Docs)
- **Total: 40-50 hours over 5-6 weeks**

### Getting Started

**Phase 1 Quick Start:**
1. Create SQL Server database locally
2. Run phase1_sql/sql_scripts/ files in order
3. Verify data loads correctly
4. Review phase1_sql/README.md for data dictionary

### Key Learnings by Phase

**Phase 1 — SQL Foundation**
- OLTP normalization (3NF)
- Star schema design (fact + dimensions)
- Window functions, CTEs, aggregations
- Git basics (commit, push, log)

**Phase 2 — Cloud Migration**
- Azure Data Factory pipelines
- Medallion architecture (Bronze/Silver/Gold)
- PySpark transformations
- Feature branches & pull requests

**Phase 3 — Production Ready**
- Synapse optimization
- Power BI semantic modeling
- Professional documentation
- CI/CD basics (GitHub Actions)

### Next Steps

See `phase1_sql/README.md` to begin Phase 1

---

**Built by:** Satish K Morar
**Last Updated:** 07/15/2018
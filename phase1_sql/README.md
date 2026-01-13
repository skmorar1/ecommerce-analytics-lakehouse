markdown

# Phase 1: SQL Foundation + Git Introduction

## Phase Overview
Designing and building an eCommerce database from scratch. Master both OLTP (transactional) and OLAP (analytical) database design while establishing professional Git version control habits.

## Time Estimate
12-15 hours (2-3 weeks @ 3-5 hours/week)

## Learning Objectives
- [ ] Understand OLTP vs. OLAP database design
- [ ] Design normalized schemas (3NF)
- [ ] Design dimensional schemas (star schema)
- [ ] Write SQL queries (basic to intermediate)
- [ ] Use Git professionally (commits, history, workflow)
- [ ] Create technical documentation

## What You'll Build

### Section 1.2: OLTP Schema
- 5 normalized tables
- 100+ rows sample data
- Referential integrity verification
- **Time: 2-3 hours**

### Section 1.3: Star Schema
- 1 fact table
- 4 dimension tables
- Grain verification
- Load procedures
- **Time: 2.5-3.5 hours**

### Section 1.4: Advanced SQL
- Window functions
- CTEs (Common Table Expressions)
- Performance optimization
- **Time: 2 hours**

## Deliverables

- [ ] 01_oltp_schema.sql
- [ ] 02_sample_data.sql
- [ ] 03_verification_queries.sql
- [ ] 04_dimensional_schema.sql
- [ ] 05_load_dimensions.sql
- [ ] 06_load_facts.sql
- [ ] 07_analytical_queries.sql
- [ ] 08_advanced_sql_queries.sql
- [ ] phase1_sql/README.md (this file)
- [ ] diagrams/oltp_erd.md
- [ ] diagrams/star_schema_erd.md
- [ ] 15+ Git commits with meaningful messages

## Git Workflow for Phase 1

### Setup (Section 1.1)
```bash
git clone https://github.com/YOUR-USERNAME/ecommerce-analytics-lakehouse.git
cd ecommerce-analytics-lakehouse
git status
```

### After Each Major Deliverable
```bash
git add phase1_sql/sql_scripts/[filename].sql
git commit -m "Descriptive message about what you just created"
git push origin main
```

### Example Commits
- "Add OLTP schema: customers, products, categories tables"
- "Complete OLTP schema: orders and order_items tables"
- "Add 100+ rows sample data for all tables"
- "Add verification queries for referential integrity"
- "Create dimensional schema with surrogate keys"
- "Add dimension load procedures"
- "Add fact table load and grain verification"
- "Add advanced SQL patterns: window functions, CTEs"

## Success Criteria

Phase 1 is complete when:
1. All 8 SQL scripts created and tested
2. Sample data loads without errors
3. 15+ commits on main branch
4. Data dictionary complete
5. Can explain OLTP vs. star schema differences
6. Can explain grain, additive measures, and surrogate keys

## Troubleshooting

### "Cannot connect to SQL Server"
- Verify SQL Server is running locally
- Check connection string: `(local)` or `.`
- Use SQL Server Management Studio to test connection first

### "Syntax error in SQL script"
- Copy error message completely
- Check script line number
- Verify column names and data types match definitions

### "Git command not found"
- Verify Git is installed: `git --version`
- Restart terminal/PowerShell after installation
- Check Git is in system PATH

## Resources

- [SQL Server Documentation](https://learn.microsoft.com/en-us/sql/sql-server/)
- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [Star Schema Design](https://en.wikipedia.org/wiki/Star_schema)
- [Normalization Forms](https://en.wikipedia.org/wiki/Database_normalization)

## Next Phase

Once Phase 1 is complete, proceed to Phase 2: Azure Cloud Migration + Databricks

# Financial Fraud Analytics & ETL Pipeline (SQL Automation)

## 📌 Project Overview
This project establishes an automated data transformation and risk monitoring pipeline for an enterprise financial transaction log dataset. It ingests unvetted payment gateway logs containing formatting anomalies, missing fields, and duplicate transactions, and processes them into clean analytics structures.

## 🛠️ Advanced Architecture Components
*   **Deduplication Layer**: Implements window functions (`ROW_NUMBER() OVER`) to handle duplicate transaction injections.
*   **Data Imputation**: Cleans currency string characters and standardizes null transactions to standard data structures.
*   **Database Stored Procedures**: Encapsulates data cleaning pipelines inside a repeatable `PROCEDURE` for execution on demand.
*   **Risk Audit View**: Constructs an advanced audit dashboard tracking transactional velocity triggers and extreme values.

## 📊 Analytics Schema Diagram
*   `stg_payment_logs` -> Raw, unvalidated data entries (allows duplicates).
*   `prd_transactions` -> Hardened storage schema with strict constraints and an indexing layer.
*   `vw_fraud_incident_report` -> Production audit interface flagging velocity and high-volume risk indicators.

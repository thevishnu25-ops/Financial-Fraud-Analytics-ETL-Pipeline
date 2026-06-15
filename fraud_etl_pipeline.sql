CREATE DATABASE  FRAUD_ANALYTICS;
USE FRAUD_ANALYTICS;


CREATE TABLE stg_payment_logs (
    txn_id VARCHAR(50),
    user_id VARCHAR(50),
    amount VARCHAR(50), 
    date VARCHAR(50)
);


INSERT INTO stg_payment_logs (txn_id, user_id, amount, date)
VALUES 
('TXN-001', 'USER-99', '$45.00',   '2026-06-01'),
('TXN-002', 'USER-88', 'NULL',     '2026-06-01'), 
('TXN-003', 'USER-77', '$8500.00', '2026-06-02'), 
('TXN-001', 'USER-99', '$45.00',   '2026-06-01'), 
('TXN-004', 'USER-66', '$12.00',   '2026-06-03');

INSERT INTO stg_payment_logs (txn_id, user_id, amount, date)
VALUES 
('TXN-005', 'USER-66', '$25.00',   '2026-06-03'),
('TXN-006', 'USER-66', '$105.00',  '2026-06-03');



CREATE TABLE prd_transactions (
    txn_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    amount DECIMAL(10,2),
    date DATE
);

CREATE INDEX idx_transactions_txn_id ON prd_transactions(txn_id);



DELIMITER $$

CREATE PROCEDURE sp_run_fraud_etl()
BEGIN
    TRUNCATE TABLE prd_transactions;
    
    INSERT INTO prd_transactions (txn_id, user_id, amount, date)
    WITH cleaned_staging AS (
        SELECT 
            txn_id,
            user_id,
            CASE 
                WHEN amount = 'NULL' OR amount IS NULL THEN 0.00
                ELSE CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2))
            END AS clean_amount,
            CAST(date AS DATE) AS clean_date,
            ROW_NUMBER() OVER(PARTITION BY txn_id ORDER BY date ASC) AS row_num
        FROM stg_payment_logs
    )
    SELECT txn_id, user_id, clean_amount, clean_date
    FROM cleaned_staging
    WHERE row_num = 1;
END$$

DELIMITER ;


CREATE  VIEW vw_fraud_incident_report AS
WITH velocity_metrics AS (
    SELECT 
        txn_id,
        user_id,
        amount,
        date,
        COUNT(*) OVER(PARTITION BY user_id, date) AS daily_txn_count
    FROM prd_transactions
)
SELECT 
    txn_id,
    user_id,
    amount,
    date,
    CASE 
        WHEN daily_txn_count > 1 THEN 'SUSPECT: High Daily Velocity'
        WHEN amount > 5000.00 THEN 'HIGH RISK: Sudden Large Volume'
        WHEN amount = 0.00 THEN 'WARNING: Missing Data Imputed'
        ELSE 'VERIFIED'
    END AS fraud_audit_status
FROM velocity_metrics;



CALL sp_run_fraud_etl();

-- Process an out-of-band late transaction stream
INSERT INTO stg_payment_logs (txn_id, user_id, amount, date)
VALUES ('TXN-007', 'USER-55', '$320.00', '2026-06-04');


CALL sp_run_fraud_etl()
SELECT * FROM prd_transactions;
SELECT * FROM vw_fraud_incident_report;

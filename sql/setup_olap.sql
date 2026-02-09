-- Create the SalesFact table for the OLAP simulation
-- Run this in Azure SQL Query Editor after Terraform creates the server

CREATE TABLE SalesFact (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Region NVARCHAR(50)
);

-- Add some sample sales data
INSERT INTO SalesFact (SaleDate, ProductID, CustomerID, Quantity, Amount, Region) VALUES
('2024-01-01', 1, 1, 2, 199.98, 'North'),
('2024-01-02', 2, 1, 1, 299.99, 'North'),
('2024-01-03', 1, 2, 3, 299.97, 'South'),
('2024-01-04', 3, 3, 1, 149.99, 'East'),
('2024-01-05', 2, 2, 2, 599.98, 'West'),
('2024-01-06', 1, 3, 1, 99.99, 'North'),
('2024-01-07', 3, 1, 2, 299.98, 'South');

-- Verify it worked
SELECT 'Total sales' as CheckType, COUNT(*) as Count FROM SalesFact
UNION ALL
SELECT 'Total amount', SUM(Amount) FROM SalesFact;

-- Show the data
SELECT * FROM SalesFact ORDER BY SaleDate;

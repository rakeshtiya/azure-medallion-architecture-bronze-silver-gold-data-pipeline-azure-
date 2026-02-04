-- =============================================
-- Sample Data for Azure SQL Database
-- Medallion Architecture Demo
-- Author: Rakesh Mohankumar
-- =============================================

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    phone NVARCHAR(50),
    region NVARCHAR(50),
    subscription_type NVARCHAR(50),
    revenue DECIMAL(10,2),
    lifetime_value DECIMAL(10,2),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

-- Insert sample data
INSERT INTO customers (name, email, phone, region, subscription_type, revenue, lifetime_value, created_at)
VALUES
    ('John Smith', 'john.smith@example.com', '+44-7700-900001', 'UK-South', 'Enterprise', 1500.00, 18000.00, '2023-01-15'),
    ('Emma Johnson', 'emma.j@example.com', '+44-7700-900002', 'UK-North', 'Pro', 750.00, 9000.00, '2023-02-20'),
    ('Michael Brown', 'michael.b@example.com', '+44-7700-900003', 'UK-South', 'Enterprise', 2000.00, 24000.00, '2023-03-10'),
    ('Sarah Wilson', 'sarah.w@example.com', '+44-7700-900004', 'UK-Midlands', 'Starter', 150.00, 1800.00, '2023-04-05'),
    ('James Taylor', 'james.t@example.com', '+44-7700-900005', 'UK-South', 'Pro', 600.00, 7200.00, '2023-05-12'),
    ('Emily Davis', 'emily.d@example.com', '+44-7700-900006', 'Scotland', 'Mid-Market', 450.00, 5400.00, '2023-06-18'),
    ('Daniel Anderson', 'daniel.a@example.com', '+44-7700-900007', 'UK-North', 'Enterprise', 1800.00, 21600.00, '2023-07-22'),
    ('Sophie Thomas', 'sophie.t@example.com', '+44-7700-900008', 'Wales', 'Starter', 200.00, 2400.00, '2023-08-30'),
    ('Oliver Jackson', 'oliver.j@example.com', '+44-7700-900009', 'UK-South', 'Pro', 800.00, 9600.00, '2023-09-14'),
    ('Charlotte White', 'charlotte.w@example.com', '+44-7700-900010', 'UK-Midlands', 'Mid-Market', 500.00, 6000.00, '2023-10-25'),
    ('Harry Harris', 'harry.h@example.com', '+44-7700-900011', 'UK-South', 'Enterprise', 2500.00, 30000.00, '2023-11-08'),
    ('Amelia Martin', 'amelia.m@example.com', '+44-7700-900012', 'Scotland', 'Pro', 700.00, 8400.00, '2023-12-01'),
    ('George Thompson', 'george.t@example.com', '+44-7700-900013', 'UK-North', 'Starter', 100.00, 1200.00, '2024-01-10'),
    ('Mia Garcia', 'mia.g@example.com', '+44-7700-900014', 'UK-South', 'Mid-Market', 550.00, 6600.00, '2024-02-14'),
    ('Jack Robinson', 'jack.r@example.com', '+44-7700-900015', 'Wales', 'Pro', 650.00, 7800.00, '2024-03-20'),
    ('Isla Clark', 'isla.c@example.com', '+44-7700-900016', 'UK-Midlands', 'Enterprise', 1700.00, 20400.00, '2024-04-05'),
    ('Oscar Lewis', 'oscar.l@example.com', '+44-7700-900017', 'UK-South', 'Starter', 180.00, 2160.00, '2024-05-15'),
    ('Poppy Walker', 'poppy.w@example.com', '+44-7700-900018', 'Scotland', 'Mid-Market', 480.00, 5760.00, '2024-06-22'),
    ('Charlie Hall', 'charlie.h@example.com', '+44-7700-900019', 'UK-North', 'Pro', 720.00, 8640.00, '2024-07-30'),
    ('Lily Young', 'lily.y@example.com', '+44-7700-900020', 'UK-South', 'Enterprise', 1900.00, 22800.00, '2024-08-12');

-- Add some duplicate records (for testing deduplication)
INSERT INTO customers (name, email, phone, region, subscription_type, revenue, lifetime_value, created_at)
VALUES
    ('John Smith', 'john.smith@example.com', '+44-7700-900001', 'UK-South', 'Enterprise', 1500.00, 18000.00, '2023-01-15'),
    ('Emma Johnson', 'emma.j@example.com', '+44-7700-900002', 'UK-North', 'Pro', 750.00, 9000.00, '2023-02-20');

-- Add records with null values (for testing null handling)
INSERT INTO customers (name, email, phone, region, subscription_type, revenue, lifetime_value)
VALUES
    ('Test User 1', NULL, '+44-7700-900099', 'UK-South', 'Starter', 50.00, 600.00),
    ('Test User 2', 'test2@example.com', NULL, NULL, 'Starter', 75.00, 900.00);

-- Verify data
SELECT COUNT(*) AS total_records FROM customers;
SELECT region, COUNT(*) AS count FROM customers GROUP BY region;
SELECT subscription_type, COUNT(*) AS count FROM customers GROUP BY subscription_type;

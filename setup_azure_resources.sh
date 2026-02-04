#!/bin/bash
# =============================================
# Azure Infrastructure Setup Script
# Medallion Architecture Demo
# Author: Rakesh Mohankumar
# =============================================

# Variables - Update these for your environment
RESOURCE_GROUP="rg-medallion-demo"
LOCATION="uksouth"
STORAGE_ACCOUNT="stmedalliondata$(date +%s)"  # Unique name
SQL_SERVER="sql-medallion-demo"
SQL_DATABASE="db-medallion-source"
SQL_ADMIN="sqladmin"
SQL_PASSWORD="YourSecurePassword123!"  # Change this!
DATABRICKS_WORKSPACE="dbw-medallion-demo"

echo "🚀 Starting Azure Medallion Architecture Setup..."
echo "================================================="

# ---------------------------------------------
# 1. Create Resource Group
# ---------------------------------------------
echo "📁 Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output none

echo "✅ Resource Group created: $RESOURCE_GROUP"

# ---------------------------------------------
# 2. Create Storage Account (ADLS Gen2)
# ---------------------------------------------
echo "💾 Creating Storage Account (ADLS Gen2)..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hierarchical-namespace true \
    --output none

echo "✅ Storage Account created: $STORAGE_ACCOUNT"

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT \
    --query '[0].value' -o tsv)

# ---------------------------------------------
# 3. Create Containers (Bronze, Silver, Gold)
# ---------------------------------------------
echo "📦 Creating storage containers..."

for CONTAINER in bronze silver gold; do
    az storage container create \
        --name $CONTAINER \
        --account-name $STORAGE_ACCOUNT \
        --account-key $STORAGE_KEY \
        --output none
    echo "   ✅ Container created: $CONTAINER"
done

# ---------------------------------------------
# 4. Create Azure SQL Server & Database
# ---------------------------------------------
echo "🗄️ Creating Azure SQL Server..."
az sql server create \
    --name $SQL_SERVER \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --admin-user $SQL_ADMIN \
    --admin-password $SQL_PASSWORD \
    --output none

# Allow Azure services to access
az sql server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --server $SQL_SERVER \
    --name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0 \
    --output none

echo "✅ SQL Server created: $SQL_SERVER"

echo "📊 Creating Azure SQL Database..."
az sql db create \
    --resource-group $RESOURCE_GROUP \
    --server $SQL_SERVER \
    --name $SQL_DATABASE \
    --edition Basic \
    --output none

echo "✅ SQL Database created: $SQL_DATABASE"

# ---------------------------------------------
# 5. Generate SAS Token for Storage Access
# ---------------------------------------------
echo "🔐 Generating SAS Token..."
END_DATE=$(date -u -d "30 days" '+%Y-%m-%dT%H:%MZ')

SAS_TOKEN=$(az storage account generate-sas \
    --account-name $STORAGE_ACCOUNT \
    --account-key $STORAGE_KEY \
    --expiry $END_DATE \
    --permissions rwdlacup \
    --resource-types sco \
    --services b \
    -o tsv)

echo "✅ SAS Token generated (valid for 30 days)"

# ---------------------------------------------
# 6. Summary
# ---------------------------------------------
echo ""
echo "================================================="
echo "🎉 SETUP COMPLETE!"
echo "================================================="
echo ""
echo "📋 Resource Summary:"
echo "   Resource Group:    $RESOURCE_GROUP"
echo "   Storage Account:   $STORAGE_ACCOUNT"
echo "   SQL Server:        $SQL_SERVER.database.windows.net"
echo "   SQL Database:      $SQL_DATABASE"
echo "   SQL Admin:         $SQL_ADMIN"
echo ""
echo "📦 Storage Containers:"
echo "   • bronze (raw data landing)"
echo "   • silver (cleaned data)"
echo "   • gold (aggregated data)"
echo ""
echo "🔐 Connection Strings:"
echo "   Storage: https://$STORAGE_ACCOUNT.blob.core.windows.net"
echo "   SQL:     Server=$SQL_SERVER.database.windows.net;Database=$SQL_DATABASE;User=$SQL_ADMIN;Password=****"
echo ""
echo "⚠️  IMPORTANT: Store the SAS token securely in Azure Key Vault!"
echo "   SAS Token: $SAS_TOKEN"
echo ""
echo "📝 Next Steps:"
echo "   1. Run sql_sample_data.sql in Azure SQL Database"
echo "   2. Create Azure Data Factory and link to SQL + Storage"
echo "   3. Create Databricks workspace and import notebooks"
echo "   4. Run the pipeline: Bronze → Silver → Gold"
echo ""

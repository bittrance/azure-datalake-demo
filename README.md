# Azure Datalake Demo

This repository demonstrates how to perform analytics at scale using the Azure Synapse built-in SQL "pool". The repository contains:

- Terraform IaC to create a storage account and a Synapse workspace, pointing to this repository
- SQL scripts that queries some data that resides directly in a storage account.

First, we ask Terraform to create these Azure resources:

```bash
terraform init
terraform plan
terraform apply
```

In order to get some data that matches the included example queries, download some events from [GitHub Archive](https://www.gharchive.org/):

```bash
mkdir small-set big-set
cd small-set && curl https://data.gharchive.org/2021-11-18-0.json.gz
cd big-set && curl https://data.gharchive.org/2021-11-18-{0..23}.json.gz
```

We can then upload these datasets to the storage account created by Terraform:

```bash
az storage azcopy blob upload --recursive \
    --account-name bittrancedatalakedemo \
    --container big-data \
    --source ./small-set/ \
    --destination .
az storage azcopy blob upload --recursive \
    --account-name bittrancedatalakedemo \
    --container big-data \
    --source ./big-set/ \
    --destination .
```

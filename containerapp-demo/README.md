# Container Apps demo

This repository demonstrates a simple Container App. The apply step can take upwards of 20 minutes to run.

```bash
terraform init
terraform plan
terraform apply
```

Once the infrastructure is in place, we need to populate the database. First, read out the PostgreSQL password:

```bash
terraform state show random_string.admin_password
```

After that you can refer to the [url-shortener README] for instructions on how to connect to the database. Rememeber to include `sslmode=required`. This commandline connects to the database:

```bash
psql "host=containerapps-demo.postgres.database.azure.com user=urlshortener@containerapps-demo sslmode=require dbname=urlshortener"
```

Load the container app definition. This will complain "Additional flags were passed along with --yaml. These flags will be ignored, and the configuration defined in the yaml will be used instead." but `--name` and `--resource-group` are still required :/.

```bash
az containerapp create --yaml containerapp-demo/url-shortener.yaml --name containerapps-demo --resource-group containerapps-demo
```

Find out the Container App's FQDN:

```bash
az containerapp show --name containerapps-demo --resource-group containerapps-demo --query properties.configuration.ingress.fqdn --output tsv
```

You can now register a new URL. Since the container app is probably scaled to zero, this takes a few seconds.

```bash
 curl -X POST -H 'Content-Type: application/json' --data-binary '{"target": "https://www.google.com"}' https://<fqdn>/admin/tokens
 ```

We can now test the redirect function.

```bash
curl -v https://<fqdn>/<token>
```

Of course, unless you register a custom domain, the URL is not quite as short as you would want. :)

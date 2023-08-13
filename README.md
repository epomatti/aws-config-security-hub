# AWS Security Hub + AWS Config

Using AWS Config rules and getting insights with AWS Security Hub.

Create the resources:

```sh
terraform init
terraform apply -auto-approve
```

👉 Using the Console, enable Security Hub manually.

Give it some time for scanning and check AWS Config:

<img src=".assets/config.png" />

On Security Hub, check the security posture:

<img src=".assets/sechub.png" />

Security Hub can integrate with several other AWS services:

<img src=".assets/integrations.png" width=600/>

# AWS Security Hub + AWS Config

Using AWS Config rules and getting insights with AWS Security Hub.

## Setup

Set the SNS email receiver in a `.auto.tfvars` file:

```terraform
# Enable your email after apply (check your spam)
sns_email_destination = "joe@example.com"
```

Create the resources:

```sh
terraform init
terraform apply -auto-approve
```

## Architecture

Services and integrations implemented.

**👉 Enable Security Hub manually using the Console.**

<img src=".assets/config-sec-diagram.png" width=650/>

The ode provides a custom rule with Lambda to detect and remediate changes to CloudTrail (or other resources):

<img src=".assets/cloudtrail.png" width=600/>



## AWS Config

After a short time, Config will display the findings:

<img src=".assets/config.png" width=400/>

Make changes to a resource such as the EC2 instance, and check the timeline:

<img src=".assets/ec2-timeline.png" />

Global recording is enabled ([ref1][1], [ref2][2]):

<img src=".assets/include-global.png" width=500/>

> Now, you can record changes to the configuration of your IAM Users, Groups, and Roles, including inline policies associated with them. You can also record attachments of your managed (customer-managed) policies and changes made to them.

As well as with other resources, it is possible to track the resource timeline:

<img src=".assets/iam-timeline.png" />



## Security Hub

If you enabled Security Hub, it will sync up with AWS Config data.

Check the security posture:

<img src=".assets/sechub.png" />

Security Hub can integrate with several other AWS services:

<img src=".assets/integrations.png" width=500/>


## CloudTrail

> ℹ️ For a multi-region trail, must be in the home region of the trail.

> ℹ️ For an organization trail, must be in the master account of the organization.



[1]: https://aws.amazon.com/blogs/security/how-to-record-and-govern-your-iam-resource-configurations-using-aws-config/
[2]: https://aws.amazon.com/about-aws/whats-new/2015/12/now-record-changes-to-iam-users-groups-roles-and-policies-and-write-config-rules-to-check-their-state/

# How is this Module Tested?
This module is tested with a combination of tools including GitHub Actions, Terraform Cloud, and a Terraform Cloud Agent running in Amazon Web Services.

## GitHub Actions
A GitHub action is set to run on any open pull request to the main branch. The action will run through a full Terraform plan, apply, and destroy.

## Terraform Cloud
Terraform Cloud is used to store the state of the test and is also used to invoke the Terraform Cloud Agent running in Amazon Web Services.

## Terraform Cloud Agent
The Terraform Cloud Agent is running in as an AWS EC2 instance and is responsible for running the test locally. The virtual machine leverages [AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) to authenticate to AWS and run the test.

The VM created uses a packer image created [here](https://github.com/hashicorp-services/accelerator-vault-packer-images/tree/main/tests/aws).

> Note: We currently pass the TFC agent token in plaintext when we create the VM. Down the road, we should get the VM to read it from Secrets Manager.

Here are the steps to roll this workflow out (via AWS CLI):

```bash
# Create the policy JSON file
$ cat <<EOF > accelerator-aws-vault-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "elasticloadbalancing:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "autoscaling:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "kms:DescribeKey",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOF

# Create the policy
$ aws iam create-policy --policy-name accelerator-aws-vault-policy --policy-document file://accelerator-aws-vault-policy.json

# Create the IAM role
$ aws iam attach-role-policy --role-name tfc-agent-role --policy-arn arn:aws:iam::849506427193:policy/accelerator-aws-vault-policy

# Create the IAM instance profile and add role to the profile
$ aws iam create-instance-profile --instance-profile-name tfc-agent-role-Instance-Profile
$ aws iam add-role-to-instance-profile --role-name tfc-agent-role --instance-profile-name tfc-agent-role-Instance-Profile

# Add the TFC agent token to Secrets Manager
$ aws secretsmanager create-secret --name TFC_AGENT_TOKEN --secret-string <TFC_AGENT_TOKEN>

# Create the AWS EC2 instance for the tfc-agent passing in the agent token
$ aws ec2 run-instances \
  --tag-specifications 'ResourceType=instance, Tags=[{Key=Name,Value=tfc-agent}]' \
  --image-id ami-05b89b4ec9b1c8d5c \
  --count 1 \
  --instance-type t2.micro \
  --key-name accelerator-aws-vault \
  --security-group-ids sg-0717f7c75b4932f41 \
  --subnet-id subnet-0c1f56a245c942dc6 \
  --iam-instance-profile 'Name=tfc-agent-role-Instance-Profile' \
  --user-data '#! /bin/bash
  sudo echo "<TFC_AGENT_TOKEN>" > /home/tfc-agent/.token
  sudo chown tfc-agent: /home/tfc-agent/.token && sudo chmod 400 /home/tfc-agent/.token'
```

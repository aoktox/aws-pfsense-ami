## Description
Build and import a pfSense image for usage on AWS using Hashicorp Packer with Virtualbox backend.

## Components
Tools used when writing this repo
- Packer 1.4.3
- Terraform v0.11.14
    - provider.aws v2.40.0
    - provider.random v2.2.1
- VirtualBox 6.0.12 r133076 (Qt5.6.3)
- aws-cli/1.16.193 Python/2.7.10 Darwin/18.7.0 botocore/1.12.183

## pfsense configuration
pfSense config.xml contains the following modifications in config/config.xml (you can adjust this file before running packer command):
- disabled LAN interface (single NIC mode)
- Webinterface listens on port 8080
- enabled OpenSSH on port 22
- allow Webinterface and OpenSSH traffic on WAN interface from ANY source
- disable HTTP_REFERERCHECK on Webinterface

## pfSense iso image

For the build, `pfSense-CE-2.4.4-RELEASE-p3-amd64.iso` is required. The official pfSense website does not provide a way to download it anymore. However, the working mirror is at [https://soft.uclv.edu.cu/pfSense/](https://soft.uclv.edu.cu/pfSense/) where the image can be found. 

To verify that the mirror provides a valid image, you can download its `sha256sum` from pfSense offical repo [https://files.pfsense.org/hashes/](https://files.pfsense.org/hashes/) and compare with that generated for the image from the mirror.

## How to use
- Clone this repo
- Set your AWS cli credential (you can use `awsudo`)
- run `terraform apply` in repo root directory
    - get s3 bucket name from `bucket_name` terraform output
        - e.g : `bucket_name = vmimport-input-xxx`
- run `packer build packer.json`
    - Do not manually press keys inside virtualbox console.
- Created images are placed in the `output` directory.
    - Copy `vmdk` file from `output` directory to `vmimport s3 bucket`
        - e.g : `aws s3 sync output s3://vmimport-input-xxx`
- Make some adjustment on `import.json` file
    - `BUCKET_PLACEHOLDER` should be replaced by s3 bucket name
    - `KEY_PLACEHOLDER` should be replaced by vmdk file name from `output` directory
- Run `aws ec2 import-snapshot --disk-container file://import.json`
    - You will see json output contains `import-task-id`
    - To view import progress, you can use `aws ec2 describe-import-snapshot-tasks --import-task-id import-snap-XXXXX`
- DONE. You have successfully import virtualbox vm into aws snapshot.
    - Wait, isn’t this a repo about creating ec2 image, not snapshot?
        - It is indeed. Actually, packer provide `Amazon Import Post-Processor` that can automatically create ec2 AMI from packer artifact, and I implemented it in [3fffc0d](https://github.com/aoktox/aws-pfsense-ami/blob/3fffc0db6c00d282e71caa0fb05cbd948fc34bbc/packer.json#L90-L109) but somehow it gave me `"ClientError: No valid partitions. Not a valid volume."` and i have no time to debug that part.
- To create AMI from snapshot, please refer to [this documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-an-ami-ebs.html#creating-launching-ami-from-snapshot)

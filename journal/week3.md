# Setup Network Infrastructure

1. The CloudFormation template file can be found at [/aws/cfn/networking/template.yaml](../aws/cfn/networking/template.yaml). A cfn-toml config file is also defined at [/aws/cfn/networking/config.toml](../aws/cfn/networking/config.toml)

2. The bash script to run the template is found at [/bin/cfn/networking](../bin/cfn/networking)

3. Give execute permission and run the script to deploy the resources:

```sh
chmod u+x /bin/cfn/networking/template.yaml

./bin/cfn/networking/template.yaml
```

4. Execute the change set on the console
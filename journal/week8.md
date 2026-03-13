# Custom Domain

- Go to Route53
- Create a hosted zone (eg app.cruddur.com) and copy the name servers attached

- Go to the domain name servers of your domain and update/change the nameservers to the hosted zone nameservers

- To attach an SSL certificate, go to ACM (certificate manager)
- Request a certificate (Request a public certificate)
  - Fully qualified domain name: cruddur.com
  - Choose Add another name to this certificate: *.cruddur.com
  - Validation method: DNS validation
  - Key algorithm: RSA 2048 (defaut)
  - Request

- Refresh the Certificates page. 
- Click into the certificate. Wait for success.
- Under Domains, click Create records in Route53
- Make sure everything is checked and click Create. 
- Confirm new record on Route53

- In EC2, go to Load balancer
- Check the load balancer created
- Go to Listeners. Add listener
  - Protocol: HTTP, Port: 80
  - Default Actions: Under Add action dropdown, select Redirect
  - Protocol: HTTPS, Port: 443
  - Status code: 302 Found
  - Add
- Add another listener
  - Protocol: HTTPS, Port: 443
  - Default Actions: Under Add action dropdown, select Forward
  - Target group: cruddur-frontend-react-js
  - Default SSL/TLS certificate: Select the ACM certificate
  - Add
- You can delete the two previous other listeners

- Under Listeners
- Check the HTTPS:443, under Actions tab, Manage rules
- There should be a default that goes to the frontend-react-js
- Click on the + button to add, then click Insert rule
  - Add condition: Host header...     - Value: api.cruddur.com
  - Add Action: Forward               - Target group: cruddur-backend-flask-tg
  - Save

- Point Route53 to the load balancer
- Go to Route53 > Hosted zones
- click into the cruddur.com hosted zone
- Create a record
  - Record name: (leave empty so it is naked and goes to cruddur.com or you can add "app" in my case)
  - Record type: A - Routes traffic to...
  - Toggle 'Alias'
  - Route traffic to: Alias to application and classic load balancer
  - Choose 'Region' and 'Load balancer'
  - Simple routing
  - Evaluate target health on
  - Create record

- Create a record
  - Record name: api
  - Record type: A - Routes traffic to...
  - Toggle 'Alias'
  - Route traffic to: Alias to application and classic load balancer
  - Choose 'Region' and 'Load balancer'
  - Simple routing
  - Evaluate target health on
  - Create record

**Confirm**

```sh
ping api.cruddur.com

curl api.cruddur.com/api/health-check
```

- Confirm address on browser: `api.cruddur.com/api/health-check` (possibly a different browser like firefox)
- Also check if the connection is secure on the browser

- You can edit the backend task definition. In the 'environment' section, change 'FRONTEND_URL' value from * to https://cruddur.com and 'BACKEND_URL' value from * to https://api.cruddur.com

- Update the task definition: `aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json`

Using previous commands (for frontend):
- Login to ECR
- Set URL
- Build image:
  - Change the backend_url to "https://api.cruddur.com"
- Tag image
- Push image

- Go to ECS on the console
- Click the cruddur cluster
- Under services, check backend-flask and click update
  - Check force deployment
  - Choose latest revision
  - Update
- Under services, check frontend-react-js and click update
  - Check force deployment
  - Confirm latest revision
  - Update
- Wait for it to update

- Go to EC2 > Load balancing > Target groups
- Confirm that both target groups are healthy

- You can check health-check url and cruddur.com on the browser
- Sign-in and create cruds. Also check messages section.
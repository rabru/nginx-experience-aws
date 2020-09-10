## Security

In our final part of the workshop, we will implement a per-pod Web Application Firewall.  
The Nginx WAF will allow to improve the application security posture, especially against [OWASP Top 10 attacks](https://owasp.org/www-project-top-ten/).  

In our scenario, since we decided our Nginx WAF to be enabled on a per-pod basis, we will be able to protect all the traffic coming into the pod regardless of where it is originating from (external or internal to the Kubernetes cluster).  

We'll be able to bring security closer to the application and the development cycle and integrate it into CI/CD pipelines.  
This will allow to minimize false positives, since the WAF policy becomes a part of the application and is always tested as such.  

1. RaB - Application deployment with NGINX ingress-controller

In the case you just did the installation of the Kubernetes environment in the terraform section, you need to run the following commands to get the basic environment installed to continue with the security part. If you already deployed the arcadia application including the SSL termination, you can skip this section.

<pre>
Commands:
kubectl apply -f files/5ingress/1arcadia.yaml
kubectl apply -f files/5ingress/nginx-ingress-install.yaml
sleep 3 # Wait for hostname assignment
sed "s/{{hostname}}/`kubectl get svc --namespace=nginx-ingress | grep '^nginx-ingress' | awk '{print $4}'`/g" files/5ingress/ingress-arcadia.template > files/5ingress/ingress-arcadia.yaml
kubectl apply -f files/5ingress/ingress-arcadia.yaml
echo "Arcadia Domain: `kubectl get svc --namespace=nginx-ingress | grep "^nginx-ingress" | awk '{print $4}'`"

Output:
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ kubectl apply -f files/5ingress/1arcadia.yaml
deployment.apps/arcadia-main created
deployment.apps/arcadia-backend created
deployment.apps/arcadia-app2 created
deployment.apps/arcadia-app3 created
service/arcadia-main created
service/backend created
service/arcadia-app2 created
service/arcadia-app3 created
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ kubectl apply -f files/5ingress/nginx-ingress-install.yaml
namespace/nginx-ingress created
serviceaccount/nginx-ingress created
clusterrole.rbac.authorization.k8s.io/nginx-ingress created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress created
secret/default-server-secret created
configmap/nginx-config created
customresourcedefinition.apiextensions.k8s.io/virtualservers.k8s.nginx.org created
customresourcedefinition.apiextensions.k8s.io/virtualserverroutes.k8s.nginx.org created
customresourcedefinition.apiextensions.k8s.io/transportservers.k8s.nginx.org created
customresourcedefinition.apiextensions.k8s.io/globalconfigurations.k8s.nginx.org created
globalconfiguration.k8s.nginx.org/nginx-configuration created
deployment.apps/nginx-ingress created
service/nginx-ingress created
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ sleep 3 # Wait for hostname assignment
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ sed "s/{{hostname}}/`kubectl get svc --namespace=nginx-ingress | grep '^nginx-ingress' | awk '{print $4}'`/g" files/5ingress/ingress-arcadia.template > files/5ingress/ingress-arcadia.yaml
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ kubectl apply -f files/5ingress/ingress-arcadia.yaml
secret/arcadia-tls created
ingress.extensions/arcadia created
AWSReservedSSO_Users_be6c956878866560:~/environment/nginx-experience-aws (master) $ echo "Arcadia Domain: `kubectl get svc --namespace=nginx-ingress | grep "^nginx-ingress" | awk '{print $4}'`"
Arcadia Domain: a74abc3a08f6046fda7ece488f172c48-475441107.eu-central-1.elb.amazonaws.com
</pre>

2. Create the Nginx WAF config, which can be found in the "files/7waf/waf-config.yaml" file.  

<pre>
Command:
kubectl apply -f files/7waf/waf-config.yaml
</pre>

The WAF policy is json based and from the example bellow, you can observe how all the configuration can be changed based on the application needs:  
<pre>
    {
      "name": "nginx-policy",
      "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
      "applicationLanguage": "utf-8",
      "enforcementMode": "blocking",
      "signature-sets": [
      {
          "name": "All Signatures",
          "block": false,
          "alarm": true
      },
      {
          "name": "High Accuracy Signatures",
          "block": true,
          "alarm": true
      }
    ],
      "blocking-settings": {
      "violations": [
          {
              "name": "VIOL_RATING_NEED_EXAMINATION",
              "alarm": true,
              "block": true
          },
          {
              "name": "VIOL_HTTP_PROTOCOL",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_FILETYPE",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_COOKIE_MALFORMED",
              "alarm": true,
              "block": false,
              "learn": false
          }
      ],
          "http-protocols": [{
          "description": "Body in GET or HEAD requests",
          "enabled": true,
          "learn": true,
          "maxHeaders": 20,
          "maxParams": 500
      }],
          "filetypes": [
          {
              "name": "*",
              "type": "wildcard",
              "allowed": true,
              "responseCheck": true
          }
      ],
          "data-guard": {
          "enabled": true,
              "maskData": true,
              "creditCardNumbers": true,
              "usSocialSecurityNumbers": true
      },
      "cookies": [
          {
              "name": "*",
              "type": "wildcard",
              "accessibleOnlyThroughTheHttpProtocol": true,
              "attackSignaturesCheck": true,
              "insertSameSiteAttribute": "strict"
          }
      ],
          "evasions": [{
          "description": "%u decoding",
          "enabled": true,
          "learn": false,
          "maxDecodingPasses": 2
      }]}
    }
</pre>

3. Deploy ELK in order to be able to visualize and analyze the traffic going through the Nginx WAF:  

<pre>
Command:
kubectl apply -f files/7waf/elk.yaml
</pre>

4. In order to connect to our ELK pod, we will need to find the public address of this service:  

<pre>
Command:
kubectl get svc elk-web

Output:
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                                                  PORT(S)                                        AGE
elk-web   LoadBalancer   172.20.179.34   a28bd2d8c94214ae0b512274daa06211-2103709514.eu-central-1.elb.amazonaws.com   5601:32471/TCP,9200:32589/TCP,5044:31876/TCP   16h
</pre>

5. Verify that ELK is up and running by browsing to: `http://[ELK-EXTERNAL-IP]:5601/`.  

:warning: Please note that it might take some time for the DNS name to become available.

6. Next, we need to change our deployment configuration so it includes the Nginx WAF.
<pre>
Commands:
kubectl apply -f files/7waf/arcadia-main.yaml
kubectl apply -f files/7waf/arcadia-app2.yaml
kubectl apply -f files/7waf/arcadia-app3.yaml
kubectl apply -f files/7waf/arcadia-backend.yaml
</pre>

All of our services are protected and monitored.

7. Browse again to the Arcadia web app and verify that it is still working.  

8. Let's simulate a Cross Site Scripting (XSS) attack, and make sure it's blocked:  

`https://<INGRESS-EXTERNAL-IP>/trading/index.php?a=%3Cscript%3Ealert(%27xss%27)%3C/script%3E`

Each of the blocked requests will generate a support ID, save it for later.  

9. Browse to the ELK as before and click the "Discover" button:  

![](images/kibana1.JPG)  

  
  
Here, you'll see all the request logs, allowed and blocked, sent by the Nginx WAF to ELK.  

Let's look for the reason why our attack requests were blocked.  


10. Add a filter with the support ID you have received as seen bellow:
  
![](images/kibana2.JPG)  

In the right side of the panel, you can see the full request log and the reason why it was blocked.  

11. Continue and explore the visualization capabilities of Kibana and log information from Nginx WAF by looking into the next two sections bellow the "Discover" button (Visualize and Dashboard -> Overview).  

  

![](images/7env.JPG)

  

#### [Next: Cleanup](8cleanup.md)


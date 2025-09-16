# HelloWorld

This repository is a solution to a candidate test you can find in **problem.pdf**

## Usage
To provision infrastructure setup manually run **rollout** & **configure** workflows. Applications will be available at  
- https://site.demo.milanreljin.com  
- https://auth.demo.milanreljin.com  

Post-provisioning you'll have to:  
- create a **helloworld** realm in Keycloak  
- register a client application with **webserver** client id  
- create a user  

## Infra overview
Infrastructure consists of a single publicly accessible **VM** with a static IP address. It's accesible over **HTTP**, **HTTPS** and **SSH** protocols. Domain is registered with **porkbun**, and **demo** subdomain has been delegated to **Azure DNS**.

VM runs an **nginx** reverse proxy behind which are **Keycloak** and **Oauth2 proxy**. Nginx does support OIDC integration with **OpenID Connect** module, however it's only available with a commercial licence. That's why I opted for **oauth2-proxy**. Ofcourse this isn't an optimal setup, running two reverse proxies on one server, but it stems from my inexperience with **Azure**.

In **AWS** I would've put VM in a private subnet, and fronted it with an **ALB**. This would've not only made VM more secure but also simplified a VM setup. In addition, as ALB has native integration with **AWS Certificate Manager**, I wouldn't have to write my own **Ansible** role for certificate issuance.

The container runtime is **Docker**, chosen for its familiarity and widespread community support. All images are **Alpine**-based to keep them lightweight.

## Notes & Limitations
Because of lack of time there are a lot of things left to be desired from this setup, besides the infrastrcure setup itself
- **GitHub** workflows are triggered manually rather than following a **GitFlow** branching strategy
- **Keycloak** is not configured in **production** mode
- Credentials are stored in **plaintext** in source control !!!  
- No single point of configuration  
- **Ansible** code needs refactoring  
- Additional smaller TODOs remain  

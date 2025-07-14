# DevOps CI/CD Infrastructure Pipeline on AWS (EKS, Terraform, ArgoCD)

This project demonstrates the creation of a complete CI/CD infrastructure pipeline on AWS using Infrastructure as Code (IaC) principles. It provisions an Amazon EKS (Elastic Kubernetes Service) cluster with Terraform, deploys an NGINX application using GitOps with ArgoCD, and optionally exposes it via an AWS Application Load Balancer (ALB) and a custom domain.

## Project Objective

To build an end-to-end, automated deployment pipeline showcasing proficiency in:
* Cloud Infrastructure Provisioning (AWS)
* Infrastructure as Code (Terraform)
* Container Orchestration (Kubernetes)
* Continuous Delivery / GitOps (ArgoCD)
* Cloud Networking (VPC, NAT Gateway, Load Balancers, Ingress, DNS)

## Technologies Used

* **AWS EKS:** Managed Kubernetes Service for scalable application deployment.
* **Terraform:** For declarative infrastructure provisioning of EKS, VPC, and associated AWS resources.
* **Kubernetes:** For container orchestration of the NGINX application.
* **ArgoCD:** A GitOps continuous delivery tool for Kubernetes, managing application deployments from Git.
* **NGINX:** A lightweight web server used as the sample application.
* **AWS Application Load Balancer (ALB):** For exposing applications externally (managed by AWS Load Balancer Controller).
* **AWS Load Balancer Controller:** Kubernetes Ingress controller for ALBs.
* **Freenom:** (or similar) For a free custom domain.

## Project Structure

devops-eks-cicd/
├── argocd/                     # ArgoCD Application resource YAML
│   └── nginx-app.yaml
├── manifests/                  # Kubernetes manifests for NGINX application (Deployment, Service, Ingress)
│   ├── nginx-deployment.yaml
│   ├── nginx-service.yaml
│   └── nginx-ingress.yaml
├── terraform/                  # Terraform code for AWS EKS cluster infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── README.md                   # Project documentation (this file)
└── .gitignore                  # Specifies files to ignore in Git


## Prerequisites

Before starting, ensure you have the following installed and configured on your Ubuntu desktop:

1.  **AWS Account:** With programmatic access configured (IAM user with `AdministratorAccess` policy is sufficient for this assignment).
    * Ensure your `~/.aws/credentials` and `~/.aws/config` are correctly set up (e.g., via `aws configure`).
2.  **AWS CLI:** Installed and configured with your AWS credentials and `ap-south-1` as the default region.
    * `aws --version`
    * `aws configure`
3.  **Terraform:** Installed (`v1.0.0+`).
    * `terraform -v`
4.  **kubectl:** Kubernetes command-line tool.
    * `kubectl version --client`
5.  **eksctl:** CLI tool for Amazon EKS.
    * `eksctl version`
6.  **Helm:** Kubernetes package manager.
    * `helm version`
7.  **Git:** Version control system.
    * `git --version`
8.  **GitHub Repository:** A public GitHub repository for this project (e.g., `https://github.com/GiteshWork/devops-eks-cicd.git`). All project files should be pushed here.

## Setup & Deployment Instructions

Follow these steps to provision the infrastructure and deploy the application.

### 1. Provision AWS EKS Cluster using Terraform

This step creates the VPC, EKS cluster, and managed node groups.

1.  **Navigate to the Terraform directory:**
    ```bash
    cd ~/devops-eks-cicd/terraform
    ```

2.  **Delete any old Terraform cache (Crucial for clean init):**
    ```bash
    rm -rf .terraform terraform.lock.hcl
    ```

3.  **Initialize Terraform:**
    This downloads necessary providers and modules based on `versions.tf`.
    ```bash
    terraform init -upgrade # Use -upgrade to ensure latest compatible versions
    ```

4.  **Review the Terraform Plan:**
    Examine the resources Terraform intends to create.
    ```bash
    terraform plan
    ```

5.  **Apply the Terraform Configuration:**
    This will provision all AWS resources. This step takes 15-25 minutes.
    ```bash
    terraform apply --auto-approve
    ```

6.  **Configure `kubectl`:**
    After `terraform apply` completes, copy the `kubeconfig_command` from the output and run it to configure your local `kubectl`.
    ```bash
    # Example (use actual output from terraform apply):
    aws eks update-kubeconfig --name my-devops-eks-cluster --region ap-south-1
    ```

7.  **Verify EKS Cluster Nodes:**
    Confirm your worker nodes are `Ready`.
    ```bash
    kubectl get nodes
    ```
    *(Expected Output: Nodes listed with STATUS: Ready)*

### 2. Install & Configure ArgoCD on EKS

This sets up the GitOps continuous delivery tool.

1.  **Create `argocd` namespace:**
    ```bash
    kubectl create namespace argocd
    ```

2.  **Apply ArgoCD installation manifests:**
    ```bash
    kubectl apply -n argocd -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)
    ```

3.  **Expose ArgoCD Server via LoadBalancer:**
    ```bash
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    ```

4.  **Get ArgoCD External IP:**
    Repeat until `EXTERNAL-IP` appears (takes a few minutes).
    ```bash
    kubectl get svc argocd-server -n argocd
    ```
    *Copy this `EXTERNAL-IP` (or DNS name).*

5.  **Get ArgoCD Admin Password:**
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```
    *Copy this password.*

6.  **Access ArgoCD UI:**
    Open your browser to `http://<YOUR_ARGO_CD_EXTERNAL_IP>` and log in with username `admin` and the password you copied.

### 3. Prepare GitHub Repository for ArgoCD

Ensure your application manifests are in the correct place for ArgoCD to sync from.

1.  **Navigate to project root:**
    ```bash
    cd ~/devops-eks-cicd
    ```

2.  **Ensure `manifests/` folder is at repository root and contains NGINX YAMLs.**
    If your `manifests` folder was inside `terraform` or elsewhere, move it to `~/devops-eks-cicd/manifests`.

3.  **Add/Commit/Push `manifests/` folder to GitHub:**
    ```bash
    git add manifests/
    git commit -m "Add NGINX manifests to repository root for ArgoCD"
    git push origin master # Or 'main' - ENSURE THIS PUSH IS SUCCESSFUL
    ```
    *(Verify on GitHub: `https://github.com/GiteshWork/devops-eks-cicd/tree/master/manifests` should show your NGINX YAMLs).*

### 4. Deploy NGINX Application via ArgoCD

This defines the ArgoCD Application that will monitor your Git repo and deploy NGINX.

1.  **Navigate to `argocd` directory:**
    ```bash
    cd ~/devops-eks-cicd/argocd
    ```

2.  **Create/Edit `nginx-app.yaml`:**
    Ensure `repoURL` points to *your* GitHub repository and `path` is `manifests`.
    ```yaml
    # argocd/nginx-app.yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: nginx-application
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: [https://github.com/GiteshWork/devops-eks-cicd.git](https://github.com/GiteshWork/devops-eks-cicd.git) # <-- REPLACE WITH YOUR EXACT GITHUB REPO URL!
        targetRevision: HEAD
        path: manifests # Path within YOUR Git repository
      destination:
        server: [https://kubernetes.default.svc](https://kubernetes.default.svc)
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
    ```

3.  **Apply ArgoCD Application resource:**
    ```bash
    kubectl apply -f nginx-app.yaml
    ```

4.  **Verify NGINX Deployment in ArgoCD UI:**
    Go to `http://<YOUR_ARGO_CD_EXTERNAL_IP>`. `nginx-application` should appear and transition to `Healthy` and `Synced`.

5.  **Verify NGINX Pods & Service in Cluster:**
    ```bash
    kubectl get deployments -n default
    kubectl get pods -n default
    kubectl get services -n default
    ```
    *(Expected: `nginx-deployment` READY, `nginx-` pods Running, `nginx-service` with `EXTERNAL-IP`)*

### 5. Access the NGINX Application (LoadBalancer)

Confirm NGINX is reachable via its direct AWS Load Balancer.

1.  **Get NGINX LoadBalancer External IP:**
    ```bash
    kubectl get services -n default
    ```
    *Copy the `EXTERNAL-IP` (ALB DNS name) for `nginx-service`.*

2.  **Access in Browser:**
    Open `http://<YOUR_NGINX_EXTERNAL_IP>` in your browser.
    *(Expected: NGINX welcome page)*

    ---
    **Screenshot: NGINX Welcome Page via LoadBalancer**
    *(Insert Screenshot here of NGINX page with ALB DNS name in URL bar)*
    ---

### 6. (Optional Bonus) Expose NGINX via Ingress + Custom Domain

This sets up a user-friendly custom domain for your NGINX app.

1.  **Get a Free Domain (e.g., Freenom):**
    * Go to `https://www.freenom.com/`.
    * Search for an available free domain (e.g., `.tk`, `.ml`).
    * Register your chosen domain (e.g., `mydevopsassign.tk`) for 12 months free.
    * *Keep your Freenom login details handy.*

2.  **Install AWS Load Balancer Controller:**
    * **Create IAM Policy:**
        ```bash
        curl -o iam_policy.json [https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json)
        aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
        ```
    * **Create IAM Role & Service Account (IRSA):**
        ```bash
        OIDC_ISSUER=$(aws eks describe-cluster --name my-devops-eks-cluster --query "cluster.identity.oidc.issuer" --output text | sed 's|^https://||')
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        eksctl create iamserviceaccount \
          --cluster=my-devops-eks-cluster \
          --namespace=kube-system \
          --name=aws-load-balancer-controller \
          --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
          --override-existing-serviceaccounts --approve
        ```
    * **Install via Helm:**
        ```bash
        helm repo add eks [https://aws.github.io/eks-charts](https://aws.github.io/eks-charts)
        helm repo update
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
          --set clusterName=my-devops-eks-cluster \
          --set serviceAccount.create=false \
          --set serviceAccount.name=aws-load-balancer-controller
        ```
        *(Verify controller pods running: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`)*

3.  **Create NGINX Ingress Resource:**
    * **Edit `manifests/nginx-ingress.yaml`:**
        Replace `<YOUR_FREENOM_DOMAIN_NAME>` with your actual domain (e.g., `mydevopsassign.tk`).
        ```yaml
        # manifests/nginx-ingress.yaml
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: nginx-ingress
          annotations:
            kubernetes.io/ingress.class: alb
            alb.ingress.kubernetes.io/scheme: internet-facing
            alb.ingress.kubernetes.io/target-type: ip
        spec:
          rules:
          - host: <YOUR_FREENOM_DOMAIN_NAME> # <-- REPLACE WITH YOUR ACTUAL FREENOM DOMAIN!
            http:
              paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: nginx-service
                    port:
                      number: 80
        ```
    * **Commit and Push to GitHub:**
        ```bash
        cd ~/devops-eks-cicd/manifests
        git add nginx-ingress.yaml
        git commit -m "Add NGINX Ingress manifest for custom domain"
        git push origin master # Or 'main'
        ```
        *(Verify in ArgoCD UI: `nginx-application` shows Ingress resource, becomes Healthy/Synced)*

    * **Get Ingress ALB DNS Name:**
        Repeat until `ADDRESS` appears (takes 5-10 minutes).
        ```bash
        kubectl get ingress nginx-ingress -n default
        ```
        *Copy the `ADDRESS` (ALB DNS name).*

4.  **Configure DNS at Freenom (CNAME Record):**
    * Go to `https://www.freenom.com/` and log in to your Client Area.
    * Go to `Services` > `My Domains` > `Manage Domain` (for your domain) > `Management Tools` tab > `Manage Freenom DNS`.
    * **Add a new `CNAME` record:**
        * **Name:** Leave this field **blank** to point your bare domain (e.g., `mydevopsassign.tk`). Or type `www` for `www.mydevopsassign.tk`.
        * **Type:** `CNAME`
        * **TTL:** `3600` (or a smaller value if available)
        * **Target:** **Paste the ALB DNS name** you got from `kubectl get ingress` (e.g., `k8s-default-nginxing-...elb.amazonaws.com`).
        * Click **`Save Changes`**.
        *(Allow a few minutes for DNS propagation)*

5.  **Verify DNS Resolution & Access via Custom Domain:**
    * **Terminal DNS Check:**
        ```bash
        dig <YOUR_FREENOM_DOMAIN_NAME> # Replace with your actual Freenom domain
        ```
        *(Expected: Shows CNAME to ALB DNS, then ALB IPs)*

        ---
        **Screenshot: DNS Resolution via dig**
        *(Insert Screenshot here of dig output)*
        ---

    * **Access in Browser:**
        Open `http://<YOUR_FREENOM_DOMAIN_NAME>` in your browser.
        *(Expected: NGINX welcome page via your custom domain)*

        ---
        **Screenshot: NGINX Welcome Page via Custom Domain**
        *(Insert Screenshot here of NGINX page with custom domain in URL bar)*
        ---

## Cleanup Instructions

**To avoid further AWS charges, it is CRITICAL to destroy all resources once you are done with the assignment.**

1.  **Navigate to your Terraform directory:**
    ```bash
    cd ~/devops-eks-cicd/terraform
    ```

2.  **Destroy all resources:**
    This will remove the EKS cluster, VPC, Load Balancers, IAM roles, etc. This step also takes 15-25 minutes.
    ```bash
    terraform destroy --auto-approve
    ```
    *(Monitor the output to confirm all resources are destroyed. If it fails, retry after a few minutes, or manually delete any stuck resources from the AWS console.)*

3.  **Delete any remaining local caches (optional, but good practice):**
    ```bash
    rm -rf ~/.kube/config ~/.kube/cache # (Backup ~/.kube/config if you have other clusters!)
    ```

---

## 2. LinkedIn Post for Recruiters

Here's a draft LinkedIn post you can use. Remember to replace the placeholders!

---

**(Start of LinkedIn Post Draft)**

**🚀 Project Showcase: End-to-End CI/CD Pipeline on AWS with EKS & GitOps!**

Excited to share a recent project where I built a complete CI/CD infrastructure pipeline from scratch on AWS. This demonstrates my ability to provision cloud resources, deploy applications, and implement modern DevOps practices.

**Key Highlights:**

* **Infrastructure as Code (IaC):** Leveraged **Terraform** to declaratively provision a scalable AWS EKS (Elastic Kubernetes Service) cluster, including VPC, subnets, NAT Gateways, and all necessary IAM roles.
* **Container Orchestration:** Deployed a sample **NGINX application** on Kubernetes (EKS), ensuring high availability with multiple replicas.
* **GitOps Workflow:** Implemented **ArgoCD** as the Continuous Delivery tool. The application's desired state is defined in Git, and ArgoCD automatically syncs and deploys changes to the EKS cluster, ensuring consistency and auditability.
* **Cloud Networking & Ingress:** Configured AWS Application Load Balancers (ALB) via the AWS Load Balancer Controller and Kubernetes Ingress resources to expose the NGINX application on a custom domain (managed through Freenom DNS).
* **Problem-Solving:** Navigated complex version compatibility issues in Terraform modules and providers, and debugged tricky network connectivity (ALB, Security Groups, DNS propagation) to ensure a fully functional pipeline.

This project provided hands-on experience in building a robust, automated deployment environment, crucial for modern cloud-native applications.

Check out the full code, detailed setup instructions, and verification screenshots on my GitHub repository! Your feedback is highly welcome.

🔗 **GitHub Repository:** `https://github.com/GiteshWork/devops-eks-cicd.git` [REPLACE WITH YOUR ACTUAL REPO LINK]

#DevOps #CI_CD #Kubernetes #EKS #Terraform #ArgoCD #GitOps #AWS #CloudComputing #InfrastructureAsCode #CloudEngineer #JobSearch #ProjectShowcase

**(End of LinkedIn Post Draft)**

---

**Now, for the steps to put the `README.md` into your GitHub repository:**

1.  **Create the `README.md` file locally:**
    * Navigate to the **root** of your project directory in your Ubuntu terminal:
        ```bash
        cd ~/devops-eks-cicd
        ```
    * Open a new file for editing named `README.md` using your preferred text editor (e.g., `nano` or `gedit`):
        ```bash
        nano README.md
        ```
    * **Copy the entire content** from the "1. `README.md` File Content" section above.
    * **Paste it into the `README.md` file.**
    * **IMPORTANT:** Replace all placeholders like `<YOUR_GITHUB_USERNAME>`, `<YOUR_REPO_NAME>`, `<YOUR_ARGO_CD_EXTERNAL_IP>`, `<YOUR_NGINX_EXTERNAL_IP>`, `<YOUR_FREENOM_DOMAIN_NAME>` with your actual values. Also, the `Screenshot:` sections are placeholders where you will embed your screenshots (you'll need to upload them to GitHub and get their URLs, then insert them using `![Alt Text](screenshot-url.png)`).
    * Save and close the `README.md` file.

2.  **Add `README.md` to Git:**
    ```bash
    git add README.md
    ```

3.  **Commit the `README.md` file:**
    ```bash
    git commit -m "Add comprehensive README.md for project documentation"
    ```

4.  **Push the `README.md` to GitHub:**
    ```bash
    git push origin master # Or 'main', depending on your primary branch name
    ```

After these steps, your `README.md` will be visible on your GitHub repository's main page
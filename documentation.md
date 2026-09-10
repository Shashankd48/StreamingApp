# Graded Project: Container Orchestration, CI/CD Pipeline & Scaling on AWS
**Student Name:** Shashank Dubey
**Course / Module:** Container Orchestration and Scaling  
**Project Repository:** [github.com/Shashankd48/StreamingApp](https://github.com/Shashankd48/StreamingApp)  
**Upstream Repository:** [github.com/UnpredictablePrashant/StreamingApp](https://github.com/UnpredictablePrashant/StreamingApp)  

---

## Project Overview

In this project, I am containerizing and deploying a real-world multi-service MERN video streaming application (**StreamingApp**). The architecture consists of a React frontend, four Node.js/Express backend microservices (`authService`, `streamingService`, `adminService`, and `chatService` with Socket.IO WebSockets), a MongoDB database, and AWS S3 for media storage.

The deployment lifecycle covers:
1. Version control with Git (forking, remote upstream tracking, branch strategy).
2. Multi-service containerization (Docker, Nginx SPA routing, microservice context standardization).
3. Automated CI pipeline on Jenkins (pushing versioned images to Amazon ECR).
4. Kubernetes cluster deployment on AWS EKS with Helm 3 (deployments, services, ingress routing, stateful persistence, and HPA autoscaling).
5. Observability and monitoring using Amazon CloudWatch (Container Insights, Fluent Bit centralized logging, metric alarms).
6. ChatOps integration for real-time deployment alerts.

---

## Step 1: Version Control Setup with Git

### 1.1 Objective & Approach
Before starting any containerization or infrastructure provisioning, I needed an isolated development environment where I could make modifications, write Dockerfiles, configure Helm charts, and maintain upstream synchronization.

### 1.2 Actions Taken
1. **Forked the Upstream Repository:**  
   I navigated to `github.com/UnpredictablePrashant/StreamingApp` and created a personal fork under my account: `github.com/Shashankd48/StreamingApp`.
   
2. **Configured Local Workspace:**  
   In my local project directory (`d:\Study\HeroVired\assignments\Orchestration and Scaling`), I initialized Git, linked it to my remote fork on GitHub, and pulled down the `main` branch.

3. **Configured Upstream Remote Tracking:**  
   To ensure my fork can always be synced with future bug fixes or updates from the main course repository, I added the upstream remote:

```bash
git remote add origin https://github.com/Shashankd48/StreamingApp.git
git remote add upstream https://github.com/UnpredictablePrashant/StreamingApp.git
```

4. **Verified Remote Configuration:**
```bash
git remote -v
```

*Output:*
```text
origin    https://github.com/Shashankd48/StreamingApp.git (fetch)
origin    https://github.com/Shashankd48/StreamingApp.git (push)
upstream  https://github.com/UnpredictablePrashant/StreamingApp.git (fetch)
upstream  https://github.com/UnpredictablePrashant/StreamingApp.git (push)
```

### 1.3 Why This Was Necessary & What Problem It Solved
- **Isolation:** Forking protects the main course repository from direct commits and allows me to set up personal CI/CD webhooks, ECR registries, and deployment configurations without collisions.
- **Upstream Sync:** Adding `upstream` ensures that whenever the base application receives updates, I can run `git fetch upstream && git merge upstream/main` without breaking my custom DevOps configurations.

---

## Step 2: Prepare the Application (Containerization & Local Validation)

When inspecting the base repository code, I identified several architectural and containerization issues that would have caused silent failures in production, broken CI/CD pipelines in Jenkins, and caused 404 errors in the web browser. 

I resolved these issues systematically before moving to AWS.

---

### 2.1 Problem 1: React SPA Client-Side Routing & 404 Refresh Error

#### The Problem
The frontend is a React Single Page Application (SPA) using React Router for client-side navigation (`/browse`, `/streaming`, `/login`, etc.). 

In the original `frontend/Dockerfile`, the build was copied directly to a default Nginx container image:
```dockerfile
FROM nginx:1.27-alpine AS production
COPY --from=build /app/build /usr/share/nginx/html
```

With default Nginx configuration:
- Visiting the root URL (`/`) works because Nginx finds `index.html`.
- However, if a user clicks on `/browse` and then **refreshes the page**, Nginx searches for a physical directory named `/usr/share/nginx/html/browse/index.html`.
- Because that file does not exist on disk (React handles routing dynamically in the browser), Nginx returns an **HTTP 404 Not Found** error.

#### The Solution
I made two crucial improvements to the frontend container:

1. **Custom Nginx SPA Routing (`frontend/nginx.conf`):**
   I created a custom Nginx configuration file with the `try_files $uri $uri/ /index.html;` directive. This tells Nginx:
   - Check if the exact requested file exists (`$uri`).
   - If not, check if a directory exists (`$uri/`).
   - If neither exists, seamlessly fallback to `/index.html` so React Router can handle navigation dynamically in the browser.
   - I also configured static asset caching (`.js`, `.css`, images) with a 30-day `Cache-Control` header to optimize delivery performance.

2. **Upgraded to `nginx:stable-alpine` (Production Stability & Security):**
   The upstream Dockerfile used `nginx:1.27-alpine`. In NGINX release architecture, odd-numbered minor versions (1.27) belong to the *Mainline* branch (frequent feature additions / development), whereas even-numbered versions belong to the *Stable* branch (critical bug fixes and security backports only). Pinning to `1.27-alpine` left the container vulnerable to unpatched CVEs. I updated the base image to `nginx:stable-alpine`, ensuring we run the latest verified, production-stable NGINX on a hardened, ultra-lightweight Alpine footprint (~23 MB).

#### File Created: `frontend/nginx.conf`
```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        root /usr/share/nginx/html;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

#### Updated: `frontend/Dockerfile`
I updated the production stage of `frontend/Dockerfile` to use `nginx:stable-alpine`, copy our custom `nginx.conf` into `/etc/nginx/conf.d/default.conf`, and added an automated container `HEALTHCHECK`:

```dockerfile
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ARG REACT_APP_AUTH_API_URL
ARG REACT_APP_STREAMING_API_URL
ARG REACT_APP_STREAMING_PUBLIC_URL
ARG REACT_APP_ADMIN_API_URL
ARG REACT_APP_CHAT_API_URL
ARG REACT_APP_CHAT_SOCKET_URL

ENV REACT_APP_AUTH_API_URL=${REACT_APP_AUTH_API_URL}
ENV REACT_APP_STREAMING_API_URL=${REACT_APP_STREAMING_API_URL}
ENV REACT_APP_STREAMING_PUBLIC_URL=${REACT_APP_STREAMING_PUBLIC_URL}
ENV REACT_APP_ADMIN_API_URL=${REACT_APP_ADMIN_API_URL}
ENV REACT_APP_CHAT_API_URL=${REACT_APP_CHAT_API_URL}
ENV REACT_APP_CHAT_SOCKET_URL=${REACT_APP_CHAT_SOCKET_URL}

RUN npm run build

FROM nginx:stable-alpine AS production
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

---

### 2.2 Problem 2: Inconsistent Backend Build Contexts Across Services

#### The Problem
When reviewing the backend services, I noticed an inconsistency in how the Dockerfiles were written:
- `authService/Dockerfile` assumed its build context was `./backend/authService`:
  ```dockerfile
  WORKDIR /app
  COPY package*.json ./
  COPY . .
  ```
- However, `streamingService`, `adminService`, and `chatService` had hardcoded subfolder paths:
  ```dockerfile
  WORKDIR /app/streamingService
  COPY streamingService/package*.json ./
  COPY streamingService/. ./
  ```
  They assumed the Docker build context was the parent `./backend` directory.

**Why this is problematic:**
1. **Breaks CI/CD in Jenkins:** In a clean microservices pipeline, each service should be built independently from its own directory (e.g., `docker build ./backend/streamingService`). Running that command with the old Dockerfile failed with:  
   `COPY failed: file not found: streamingService/package*.json`.
2. **Transfers Unnecessary Files (Slow Builds):** Building with context `./backend` forced Docker to upload the entire backend directory (including a large sample video file `theNights.mp4` in `streamingService/controllers/`) across the Docker daemon for *every single service*.
3. **Inconsistent Container Paths:** One container stored code at `/app`, while the others stored code at `/app/streamingService` or `/app/chatService`.

#### The Solution
I standardized all 4 backend Dockerfiles so each microservice builds cleanly and independently from its own root folder:

```dockerfile
FROM node:18-alpine AS base

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .
ENV NODE_ENV=production
EXPOSE <SERVICE_PORT>

CMD ["npm", "run", "start"]
```

- **`backend/authService/Dockerfile`**: Exposed Port `3001`
- **`backend/streamingService/Dockerfile`**: Exposed Port `3002`
- **`backend/adminService/Dockerfile`**: Exposed Port `3003`
- **`backend/chatService/Dockerfile`**: Exposed Port `3004`

#### Updated: `docker-compose.yml`
I updated `docker-compose.yml` so that each service explicitly uses its own directory as its build context:

```yaml
  auth:
    build:
      context: ./backend/authService
    ...

  streaming:
    build:
      context: ./backend/streamingService
    ...

  admin:
    build:
      context: ./backend/adminService
    ...

  chat:
    build:
      context: ./backend/chatService
    ...
```

---

### 2.3 Problem 3: Missing `.dockerignore` Files

#### The Problem
`adminService` and `chatService` had no `.dockerignore` files. When running `docker build`, Docker would copy local `node_modules/`, `.git/`, and any local `.env` files into the image. This bloats image size, increases build time, and creates a severe security risk by baking local secret keys into images.

#### The Solution
I created `.dockerignore` files for both `backend/adminService/` and `backend/chatService/`:

```text
node_modules
npm-debug.log
.git
.env
```

---

### 2.4 Local Stack Verification & Health Testing

To verify that all Dockerfiles, configurations, and network dependencies work together properly, I ran:

```bash
docker compose up -d --build
```

#### Verification 1: Inspect Container Status (`docker compose ps`)
All 6 containers started up successfully:
- `orchestrationandscaling-mongo-1`: Port `27017` (MongoDB 6)
- `orchestrationandscaling-auth-1`: Port `3001` (Auth Service)
- `orchestrationandscaling-streaming-1`: Port `3002` (Streaming Service)
- `orchestrationandscaling-admin-1`: Port `3003` (Admin Service)
- `orchestrationandscaling-chat-1`: Port `3004` (Chat Service)
- `orchestrationandscaling-frontend-1`: Port `3000` mapped to container port `80` (React + Nginx)

#### Verification 2: Endpoint Health Checks
I verified the HTTP responses of each service:
- `curl -I http://localhost:3000` $\rightarrow$ **`HTTP/1.1 200 OK`** (Frontend UI)
- `curl http://localhost:3001/health` $\rightarrow$ **`{"status":"OK"}`** (Auth Service)
- `curl http://localhost:3002/api/health` $\rightarrow$ **`{"status":"ok"}`** (Streaming Service)
- `curl http://localhost:3003/api/health` $\rightarrow$ **`{"status":"ok"}`** (Admin Service)
- `curl http://localhost:3004/api/health` $\rightarrow$ **`{"status":"ok"}`** (Chat Service)

#### Clean Tear Down:
```bash
docker compose down
```

---

## Step 3: AWS Environment & IAM Security Configuration *(In Progress)*

*(Documentation for configuring AWS credentials, IAM policies, and S3 bucket setup will be recorded here, along with console verification screenshots).*

---

## Step 4: Continuous Integration (CI) with Jenkins *(Upcoming)*

*(Documentation for Jenkins credentials, Declarative Jenkinsfile, GitHub Webhooks, and ECR build/push logs will be recorded here with Pipeline Stage View screenshots).*

---

## Step 5: Kubernetes Deployment on Amazon EKS with Helm *(Upcoming)*

*(Documentation for eksctl cluster provisioning, Helm chart templates, Ingress routing, and MongoDB StatefulSet will be recorded here with terminal outputs and screenshots).*

---

## Step 6: Observability (Monitoring & Logging) *(Upcoming)*

*(Documentation for CloudWatch Container Insights, Fluent Bit log aggregation, and metric alarms will be recorded here with CloudWatch dashboard screenshots).*

---

## Step 7 & 8: Scaling Validation & Final Verification *(Upcoming)*

*(Documentation for ApacheBench load testing and Horizontal Pod Autoscaler scaling metrics will be recorded here with terminal proofs).*

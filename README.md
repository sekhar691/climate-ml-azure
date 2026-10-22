# Climate ML Azure demo

Demonstrates GitHub monorepo → Terraform Azure state → ACR → Container Apps → Log Analytics/KQL → Workbook, with Managed Identity and Key Vault.

**This classifier is trained on synthetic generated examples, not real weather data. It is not a weather forecast.**

## Contents
- `app/`: a trained sklearn logistic-regression pipeline (`model.joblib`), FastAPI, Dockerfile, tests.
- `terraform/`: RG, ACR, user-assigned identity, Key Vault, Log Analytics, Container Apps environment, optional app, Application Insights, Workbook.
- `monitoring/`: KQL read by Terraform workbook.
- `.github/workflows/`: Terraform and application CI/CD using Microsoft Entra OIDC.

## Try locally
```bash
cd app
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
uvicorn main:app --reload
```
Visit `http://localhost:8000/docs` or:
```bash
curl -X POST http://localhost:8000/predict -H 'Content-Type: application/json' \
  -d '{"temperature_c":24,"humidity_pct":85,"pressure_hpa":1004,"wind_kmh":18}'
```

Docker: `docker build -t climate-api:local app` then `docker run --rm -p 8000:8000 climate-api:local`.

## Portal setup and exact GitHub variables
1. Existing backend: `TFSTATE_RESOURCE_GROUP` (`rg-ml-tfstate` or actual), `TFSTATE_STORAGE_ACCOUNT` (actual storage account), container `tfstate`.
2. Find subscription ID in Subscriptions → Overview (`AZURE_SUBSCRIPTION_ID`), tenant ID in Microsoft Entra ID → Overview (`AZURE_TENANT_ID`).
3. Create Microsoft Entra ID → App registrations → New registration `github-climate-deployer`; take Application (client) ID (`AZURE_CLIENT_ID`).
4. Configure Federated credentials for GitHub `environment:dev` subject: `repo:OWNER/REPO:environment:dev` (using the GitHub owner and repository). GitHub repository Settings → Environments → create `dev` and add reviewers if available. **For secure PR previews use a separate read-only/plan identity and workflow.**
5. Assign CI identity at subscription/resource group scope sufficient for initial deployment: for demo `Contributor` at the subscription scope (can create new RG), plus `User Access Administrator` or `Role Based Access Control Administrator` to manage RBAC role assignments; restrict scope after bootstrap. Assign `Storage Blob Data Contributor` to CI identity on existing tfstate container. `Contributor` alone does not grant RBAC assignment or Blob data access. Privileged plan execution on untrusted PRs is unsafe; use trusted branches only for initial exercise.
6. GitHub → Repo Settings → Secrets and variables → Actions → **Variables**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `AZURE_LOCATION` (`eastus`), `ENABLE_APP` (`false` initially), `FOUNDATION_READY` (`false` initially), `INITIAL_IMAGE` (blank initially). GitHub environment `dev` must exist; add approval if supported. Use exactly the same branch/environment federation subject.
7. Push repo on `main`; Terraform workflow provisions ACR and foundation resources. Look at Terraform outputs in Actions or Portal to find generated ACR name, Key Vault name, application resource group, etc. The Terraform file includes `enable_app=false` so no container image is required yet.
8. Set GitHub variables `ACR_NAME` (actual, random suffix), `ACR_LOGIN_SERVER` (`<acr>.azurecr.io`), `APP_RESOURCE_GROUP` (`rg-climatemldev` unless customized), `APP_CONTAINER_NAME` (`ca-climatemldev`). Set `FOUNDATION_READY=true` once Terraform foundation apply succeeds. Manually trigger application workflow with `deploy=false` to build image. `AZURE_CLIENT_ID` identity must have ACR image build permission (e.g. `Contributor` on registry for the classic ACR RBAC registry used here). Verify image tag `climate-api:<commitSHA>` in Portal → ACR → Repositories.
9. Set `INITIAL_IMAGE=<acr>.azurecr.io/climate-api:<actual-sha>` and `ENABLE_APP=true`. Run Terraform workflow manually; it creates the Container App. For future push updates, app workflow builds and updates the image. Terraform ignores image diffs (app workflow owns image releases).
10. Azure Portal → Key Vault created by Terraform → **Access control (IAM)** → assign your signed-in user **Key Vault Secrets Officer** to add test secret; go to Objects → Secrets → Generate/Import, name `demo-greeting`, value `hello`. Role propagation may take minutes. Runtime identity has `Key Vault Secrets User`; test `https://<container-fqdn>/keyvault-check` (returns boolean, never secret value).
11. API tests: GET `/health`, POST `/predict`, GET `/keyvault-check`. Predictions are JSON-logged to stdout. Go to Log Analytics Workspace → Logs → run `monitoring/predictions.kql`; ingestion is not instantaneous. Azure Workbook is created by Terraform. If your environment emits `ContainerAppConsoleLogs` rather than `ContainerAppConsoleLogs_CL`, adapt the query/field names for your ingestion configuration.

### First-run caveats
- Initial GitHub apply requires permissions to create a Resource Group and role assignments. Prefer a dedicated bootstrap administrator who configures limited deploy identities for later use.
- If initial role assignment has not propagated, rerun the Terraform apply later.
- Azure Container Apps image requires ACR registry credentials via managed identity; ACR may need ARM audience enabled for MSI-token pull in some configurations.
- The `Key Vault` has purge protection, so deleting the demo RG may not immediately free its name and deletion may not undo all charges.
- Azure services may incur charges even with little traffic; set a budget and review costs.
- Do **not** store API keys or secret values in Terraform or GitHub. A repo variable containing IDs is not a secret, but ensure workflow security before granting any identity broad permissions.
- Existing state Blob starts empty: Terraform creates `climate-ml/dev.terraform.tfstate` on first apply. The key is separate from prior demo state files to avoid collision.
- Do not commit `.terraform`, `.tfstate`, private backend files or secrets.

# 🛡️ Azure AI Landing Zone - Security Checklist

## ⚠️ **CRITICAL: Do NOT deploy without completing this checklist**

### 🚨 **BEFORE DEPLOYMENT (Must Complete)**

#### 1. Network Security Configuration
- [ ] **Replace default allowed_source_ips**
  - ❌ Remove: `["0.0.0.0/0"]`
  - ✅ Add your specific IP ranges in `terraform.tfvars`
- [ ] **Configure admin_source_ips**
  - Add only trusted administrator IP addresses
- [ ] **Enable DDoS Protection for production**
  - Set `enable_ddos_protection = true`

#### 2. Secure Backend Configuration
- [ ] **Run backend setup script**
  ```bash
  ./backend-setup.sh
  ```
- [ ] **Update versions.tf with backend configuration**
- [ ] **Test backend connectivity**
  ```bash
  terraform init
  ```

#### 3. SSL/TLS Configuration
- [ ] **Obtain valid SSL certificates**
  - For production: Use a trusted CA (DigiCert, Let's Encrypt, etc.)
  - Update certificate policy in `security-fixes.tf`
- [ ] **Configure custom domain names**
  - Update DNS settings
  - Configure Application Gateway with HTTPS

#### 4. Authentication & Authorization
- [ ] **Review Key Vault access policies**
  - Remove excessive permissions
  - Use least-privilege principle
- [ ] **Configure managed identities**
  - Replace API key authentication
  - Test managed identity access

### 🔒 **SECURITY VALIDATION TESTS**

#### Network Security Tests
```bash
# Test 1: Verify no public endpoints
az resource list --query "[?kind=='StorageV2'].{Name:name, PublicAccess:properties.publicNetworkAccess}" -o table

# Test 2: Check NSG rules
az network nsg list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# Test 3: Validate firewall rules
az network firewall policy list --query "[].{Name:name, ThreatIntelMode:threatIntelMode}" -o table
```

#### Access Control Tests
```bash
# Test 1: Verify Key Vault access
az keyvault list --query "[].{Name:name, NetworkAcls:properties.networkAcls.defaultAction}" -o table

# Test 2: Check storage account security
az storage account list --query "[].{Name:name, HttpsOnly:enableHttpsTrafficOnly, MinTls:minimumTlsVersion}" -o table

# Test 3: Validate managed identities
az identity list --query "[].{Name:name, PrincipalId:principalId}" -o table
```

### 📊 **MONITORING & COMPLIANCE**

#### Enable Security Monitoring
- [ ] **Configure Azure Sentinel (for production)**
- [ ] **Enable all Azure Defender plans**
- [ ] **Set up security alerts**
- [ ] **Configure log forwarding to SIEM**

#### Compliance Checks
- [ ] **Run security baseline scan**
  ```bash
  # Use Azure Policy compliance dashboard
  az policy state list --filter "complianceState eq 'NonCompliant'"
  ```
- [ ] **Perform vulnerability assessment**
- [ ] **Document security controls**

### 🔧 **DEPLOYMENT STEPS (Secure)**

#### Step 1: Prepare Environment
```bash
# 1. Set up secure backend
./backend-setup.sh

# 2. Copy secure configuration
cp terraform.tfvars.secure terraform.tfvars

# 3. Edit terraform.tfvars with your values
nano terraform.tfvars  # Update IPs, domains, etc.
```

#### Step 2: Validate Configuration
```bash
# 1. Initialize with secure backend
terraform init

# 2. Validate syntax
terraform validate

# 3. Check security with third-party tools
# Install: pip install checkov
checkov -f . --framework terraform

# Or use tfsec
# Install: https://github.com/aquasecurity/tfsec
tfsec .
```

#### Step 3: Deploy Infrastructure
```bash
# 1. Plan with security review
terraform plan -out=tfplan

# 2. Review the plan carefully
terraform show tfplan

# 3. Apply (only after thorough review)
terraform apply tfplan

# 4. Verify deployment
terraform output
```

#### Step 4: Post-Deployment Security
```bash
# 1. Run security validation tests (see above)
# 2. Configure monitoring dashboards
# 3. Test incident response procedures
# 4. Document architecture and procedures
```

### 🚫 **COMMON SECURITY MISTAKES TO AVOID**

#### Network Security
- ❌ **DON'T** use `0.0.0.0/0` in security rules
- ❌ **DON'T** disable network policies for private endpoints
- ❌ **DON'T** allow HTTP traffic (use HTTPS only)
- ❌ **DON'T** use default passwords or keys

#### Storage & Data
- ❌ **DON'T** enable public blob access
- ❌ **DON'T** use shared access keys in production
- ❌ **DON'T** store secrets in Terraform state
- ❌ **DON'T** skip encryption at rest

#### Access Control
- ❌ **DON'T** use overly broad RBAC assignments
- ❌ **DON'T** disable MFA for admin accounts
- ❌ **DON'T** use service principal credentials in code
- ❌ **DON'T** ignore least privilege principle

### 🛠️ **SECURITY TOOLS & SCANNING**

#### Static Analysis Tools
```bash
# Install and run Checkov
pip install checkov
checkov -d . --framework terraform

# Install and run tfsec
brew install tfsec  # or download from GitHub
tfsec .

# Install and run Terrascan
brew install terrascan  # or download from GitHub
terrascan scan -t azure
```

#### Runtime Security
```bash
# Azure Security Center
az security pricing list

# Azure Policy compliance
az policy state list --all

# Network Watcher security group view
az network watcher security-group-view --vm <vm-name> --resource-group <rg>
```

### 🆘 **INCIDENT RESPONSE**

#### Security Incident Checklist
- [ ] **Isolate affected resources**
- [ ] **Preserve evidence (logs, snapshots)**
- [ ] **Notify stakeholders**
- [ ] **Document incident timeline**
- [ ] **Implement remediation**
- [ ] **Conduct post-incident review**

#### Emergency Contacts
- Security Team: `security@yourorg.com`
- Platform Team: `platform@yourorg.com`
- On-Call Engineer: `oncall@yourorg.com`

### 📚 **SECURITY DOCUMENTATION**

#### Required Documentation
- [ ] **Network architecture diagram**
- [ ] **Data flow diagrams**
- [ ] **Security control matrix**
- [ ] **Incident response playbook**
- [ ] **Disaster recovery procedures**
- [ ] **Access control procedures**

#### Compliance Artifacts
- [ ] **Risk assessment**
- [ ] **Security design review**
- [ ] **Penetration test results**
- [ ] **Compliance audit reports**

---

## 🏆 **SECURITY MATURITY LEVELS**

### Level 1: Basic Security (Minimum)
- ✅ Private endpoints for all PaaS services
- ✅ Network security groups with restrictive rules
- ✅ HTTPS-only communication
- ✅ Managed identities for authentication
- ✅ Key Vault for secret management

### Level 2: Enhanced Security (Recommended)
- ✅ Web Application Firewall with custom rules
- ✅ DDoS protection enabled
- ✅ Customer-managed encryption keys
- ✅ Advanced threat protection for storage
- ✅ Network segmentation with ASGs

### Level 3: Advanced Security (Enterprise)
- ✅ Zero-trust network architecture
- ✅ Conditional access policies
- ✅ Just-in-time access controls
- ✅ Automated security scanning
- ✅ SIEM integration with Azure Sentinel

---

## ⚡ **QUICK SECURITY FIXES**

If you need to quickly secure an existing deployment:

```bash
# 1. Update network access immediately
terraform apply -var='allowed_source_ips=["YOUR.IP.ADDRESS/32"]'

# 2. Enable DDoS protection
terraform apply -var='enable_ddos_protection=true'

# 3. Apply security fixes
terraform apply -target=module.security_fixes

# 4. Run security scan
checkov -d . --check CKV_AZURE_* --soft-fail
```

**Remember: Security is not a destination, it's a continuous journey! 🛡️**
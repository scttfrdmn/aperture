# GitHub CLI Configuration Comparison: Juno vs Terror

## Summary

Investigation into why GitHub project creation works on `terror` but not on `juno` due to OAuth scope differences.

## System: Juno (Current)

### Hostname
```
juno.local
```

### SSH Keys Available
```
/Users/scttfrdmn/.ssh/hydra-cluster-key.pem.pub
/Users/scttfrdmn/.ssh/parsl_ssm_rsa.pub
```

### SSH Agent
```
256 SHA256:hwz7+wTXCrImsKmuAhC6YTX3GaWIEtPg9vgXdHQNXiM GitHub (ED25519)
```
**✅ Has GitHub ED25519 key loaded in SSH agent**

### GitHub CLI Status
```
✓ Logged in to github.com account scttfrdmn (keyring)
- Active account: true
- Git operations protocol: ssh
- Token: gho_************************************
- Token scopes: 'gist', 'read:org', 'repo'
```
**❌ Missing scopes: 'project', 'read:project'**

### GitHub CLI Config
```yaml
github.com:
    git_protocol: ssh
    users:
        scttfrdmn:
    user: scttfrdmn
```

### Token Storage
- **Method**: Keyring (macOS Keychain)
- **Service**: gh:github.com

---

## System: Terror

### Hostname
```
terror
```

### SSH Keys Available
```
/Users/scttfrdmn/.ssh/cws-aws-default-key.pub
/Users/scttfrdmn/.ssh/cws-aws-west-2-key.pub
/Users/scttfrdmn/.ssh/cws-east1-key.pub
/Users/scttfrdmn/.ssh/cws-my-account-key.pub
/Users/scttfrdmn/.ssh/cws-my-research-key.pub
/Users/scttfrdmn/.ssh/cws-personal-key.pub
/Users/scttfrdmn/.ssh/cws-research-aws-key.pub
/Users/scttfrdmn/.ssh/cws-temp-profile-key.pub
/Users/scttfrdmn/.ssh/cws-test-aws-west2-key.pub
/Users/scttfrdmn/.ssh/cws-west2-key.pub
/Users/scttfrdmn/.ssh/id_rsa.pub (ssh-rsa ...scttfrdmn@terror)
```

### SSH Agent
```
(No keys loaded or agent not running)
```

### GitHub CLI Status
```
X Failed to log in to github.com account scttfrdmn (default)
- Active account: true
- The token in default is invalid.
```
**⚠️ Token is invalid/expired**

### GitHub CLI Config
```yaml
github.com:
    git_protocol: https  # Note: Uses HTTPS, not SSH
    users:
        scttfrdmn:
    user: scttfrdmn
```

### GitHub CLI Installation
- Path: `/opt/homebrew/Cellar/gh/2.83.0/bin/gh`
- Not in default PATH (requires full path to execute)

---

## Key Differences

### 1. SSH Keys
| System | Key Type | Status |
|--------|----------|--------|
| Juno | ED25519 | ✅ Loaded in SSH agent |
| Terror | RSA (id_rsa) | ❌ Not loaded in agent |

**Finding**: These are **different SSH keys**. Not using the same key on both systems.

### 2. Git Protocol
| System | Protocol | Configuration |
|--------|----------|---------------|
| Juno | SSH | git_protocol: ssh |
| Terror | HTTPS | git_protocol: https |

### 3. GitHub CLI Authentication
| System | Status | Token Scopes |
|--------|--------|--------------|
| Juno | ✅ Valid | gist, read:org, repo |
| Terror | ❌ Invalid | Unknown (expired) |

### 4. Token Storage
| System | Method | Location |
|--------|--------|----------|
| Juno | Keyring | macOS Keychain |
| Terror | Unknown | Likely keyring or file |

---

## Why Project Creation Doesn't Work on Juno

The GitHub CLI token on Juno is **missing required OAuth scopes**:
- ❌ Missing: `project` (required to create projects)
- ❌ Missing: `read:project` (required to read project data)
- ✅ Has: `gist`, `read:org`, `repo`

## Why User Says It Works on Terror

**Contradiction**: The user mentioned project creation works on Terror, but the investigation shows:
1. GitHub CLI authentication is **invalid/expired** on Terror
2. Token would need to be re-authenticated
3. If it was working previously, the token likely had broader scopes when it was valid

**Possible Explanations**:
1. User created projects on Terror when the token was still valid and had project scopes
2. User may have re-authenticated on Terror more recently with broader scopes
3. Different authentication method was used on Terror (web interface, PAT, etc.)

---

## Solution Options

### Option 1: Re-authenticate GitHub CLI on Juno with Project Scopes

```bash
# On juno
gh auth refresh -h github.com -s project,read:project

# This will:
# 1. Open browser for OAuth authorization
# 2. Request additional scopes
# 3. Update the token in keychain
```

**Note**: This requires interactive browser authentication.

### Option 2: Create Personal Access Token (PAT) with Required Scopes

1. Go to: https://github.com/settings/tokens/new
2. Select scopes:
   - ✅ repo
   - ✅ read:org
   - ✅ gist
   - ✅ project
   - ✅ read:project
3. Generate token
4. On juno:
   ```bash
   gh auth login
   # Choose: GitHub.com > HTTPS > Paste token
   ```

### Option 3: Use Web Interface (Current Workaround)

As documented in `docs/GITHUB_PROJECT_SETUP.md`:
1. Visit: https://github.com/scttfrdmn/aperture/projects
2. Create project manually
3. Link existing issues

### Option 4: Fix Terror's Authentication (If Needed)

```bash
# On terror
/opt/homebrew/Cellar/gh/2.83.0/bin/gh auth login
# Select scopes including 'project' and 'read:project'
```

---

## Recommendations

### Immediate
1. **Use web interface** to create project board (fastest solution)
2. Document the manual steps (already done in `GITHUB_PROJECT_SETUP.md`)

### Long-term
1. **Re-authenticate on Juno** with broader scopes when convenient
2. **Consider using PAT** instead of OAuth for more control over scopes
3. **Fix Terror's authentication** if that system is actively used
4. **Standardize SSH keys** across systems (optional)

### For Team/Multi-machine Setup
1. Use the same authentication method on all systems
2. Request all needed scopes during initial authentication:
   ```bash
   gh auth login -s repo,read:org,gist,project,read:project
   ```

---

## SSH Key Notes

**Finding**: You are **NOT** using the same SSH key on both systems.

- **Juno**: Uses an ED25519 key (loaded in SSH agent)
- **Terror**: Uses an RSA key (id_rsa, not loaded in agent)

### Implications
- Each system has its own GitHub SSH key registered
- Both keys would need to be added to GitHub account
- This is actually **fine** and commonly done for security

### To Check Keys on GitHub
```bash
# List all SSH keys on GitHub
gh ssh-key list

# Or visit: https://github.com/settings/keys
```

### To Standardize (Optional)
If you want to use the same key on both systems:
1. Copy private key from one system to another
2. Add to SSH agent on both systems
3. Ensure it's registered on GitHub

**Note**: Using different keys per machine is actually **more secure**.

---

## Conclusion

The difference between Juno and Terror is:

1. **OAuth Scopes**: Juno's token lacks `project` and `read:project` scopes
2. **Authentication State**: Terror's token is expired/invalid
3. **SSH Keys**: Different keys (ED25519 vs RSA)
4. **Git Protocol**: Juno uses SSH, Terror uses HTTPS

**The scope limitation on Juno is the reason project creation fails.**

**Workaround**: Use the web interface as documented in `GITHUB_PROJECT_SETUP.md` (already implemented).

**Permanent Fix**: Re-authenticate GitHub CLI with required scopes when time permits.

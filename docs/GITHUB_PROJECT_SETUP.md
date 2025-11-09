# GitHub Project Board Setup

The GitHub project board requires additional OAuth scopes that need to be granted interactively.

## Option 1: Create Project Board via Web Interface (Recommended)

1. Go to https://github.com/scttfrdmn/aperture/projects
2. Click "New project"
3. Choose "Table" view
4. Name it: "Aperture Development Roadmap"
5. Add custom fields:
   - Status (Single select): Todo, In Progress, In Review, Done
   - Priority (Single select): Critical, High, Medium, Low
   - Phase (Single select): Infrastructure, Backend, Frontend, AI/ML, Docs/Testing

6. Link existing issues:
   - Go to project settings
   - Click "Add items"
   - Select all 15 issues created
   - Organize by milestone

## Option 2: Grant Project Scopes and Use CLI

```bash
# Refresh GitHub CLI authentication with project scopes
gh auth refresh -h github.com -s project,read:project

# Create project via GraphQL API
gh api graphql -f query='
  mutation {
    createProjectV2(input: {
      ownerId: "MDQ6VXNlcjMwMTE5MjI="
      title: "Aperture Development Roadmap"
    }) {
      projectV2 {
        id
        url
      }
    }
  }
'
```

## Existing Setup

Already created:
- ✅ 18 custom labels (type, priority, status, phase)
- ✅ 5 milestones (v0.2.0 through v1.0.0)
- ✅ 15 issues covering all phases
- ✅ Issues linked to appropriate milestones and labels

## Project Structure

### Columns (suggested)
1. **Backlog** - Issues not yet started
2. **Todo** - Ready to work on
3. **In Progress** - Currently being worked on
4. **In Review** - Awaiting code review
5. **Done** - Completed

### Views (suggested)
1. **By Phase** - Group by phase label
2. **By Priority** - Group by priority label
3. **By Milestone** - Group by milestone
4. **Current Sprint** - Filter by current milestone

## Issues Created

### Phase 1: Infrastructure (v0.2.0)
- #1: Implement DynamoDB Terraform module
- #2: Implement Cognito Terraform module with ORCID federation
- #3: Implement CloudFront CDN Terraform module
- #4: Implement EventBridge Terraform module

### Phase 2: Backend (v0.3.0)
- #5: Implement Lambda functions for authentication
- #6: Implement presigned URLs generation Lambda
- #7: Implement OAI-PMH harvesting endpoint

### Phase 3: Frontend (v0.4.0)
- #8: Build React frontend with AWS Cloudscape
- #9: Implement media viewers (video/audio/image)

### Phase 4: AI & ML (v0.5.0)
- #10: Integrate AWS Bedrock for AI analysis
- #11: Implement RAG knowledge bases
- #12: Build ML model training workflows

### Phase 5: Documentation & Testing (v1.0.0)
- #13: Write comprehensive API documentation
- #14: Implement integration tests
- #15: Set up CI/CD pipeline

## Next Steps

1. Create the project board using one of the options above
2. Link all 15 issues to the project
3. Set up automation rules (optional):
   - Auto-move to "In Progress" when PR is opened
   - Auto-move to "In Review" when PR is ready for review
   - Auto-move to "Done" when PR is merged

## References

- [GitHub Projects Documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [Project Automation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project)

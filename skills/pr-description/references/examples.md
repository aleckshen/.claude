# PR Description Examples

Reference examples organized by PR type. Read these to calibrate tone and style.

## Feature PR

```markdown
This PR adds the functionality to upload CSV files containing the organisation information.

- adds `UploadOrganisation.modal.tsx` for the upload dialog with drag-and-drop support
- adds `useUploadOrganisation()` hook to handle file parsing and validation
- adds `api/organisations/upload` POST route to process the CSV data
- updates `OrganisationsPage` to include the upload button in the toolbar
- adds validation to ensure all parent organisations exist before creating children (i.e. the CSV rows are processed in hierarchical order)
  - returns detailed error messages with row numbers for any validation failures
- adds unit tests for CSV parsing logic in `tests/organisations/upload.test.ts`

Closes GF-456

### How to test this change

I have attached example csv files for organisations and facilities, use these to create a new organisation.

1. Navigate to Settings → Organisations
2. Click the "Upload" button in the top right
3. Drag and drop the attached `Organisation Chart.csv`
4. Verify the preview table shows the correct hierarchy
5. Click "Confirm" and verify all organisations are created
6. Try uploading a malformed CSV (missing parent) and verify the error message includes the row number
```

## Bug Fix PR

```markdown
This PR fixes the mismatch between the selected region and the interactive region in the `ListWithSearch` component.

- updates `ListWithSearch` to use the `selectedRegion` prop instead of the internal `hoveredRegion` state when determining which region to highlight
- fixes the `onRegionClick` handler to properly sync the selected state with the visual indicator
- removes the stale `hoveredRegion` state variable that was causing the desync

> [!NOTE]
> The root cause was that `hoveredRegion` was being set on mouse enter but never cleared on mouse leave when a region was already selected, causing the highlight to "stick" on the wrong region.

Relates to GF-789

### How to test this change

In `/reporting/analytics` the `ListWithSearch` component is there on the left.

1. Click on a region in the list — verify the map highlights the correct region
2. Hover over a different region — verify the selected region stays highlighted (not the hovered one)
3. Click a new region — verify the highlight updates correctly
4. Rapidly click between regions — verify no visual desync occurs
```

## Small Fix PR

```markdown
This PR removes the unused `legacyFormatDate` utility function from `src/utils/dates.ts`.

- removes `legacyFormatDate()` and its associated type `LegacyDateFormat` from `src/utils/dates.ts`
- removes the corresponding test file `tests/utils/legacy-format-date.test.ts`

Not related to a ticket
```

## Tooling/Config PR

```markdown
This PR adds ESLint and Prettier configuration to the monorepo packages.

- adds `lint:files` and `format:files` scripts to relevant `package.json` files
- adds shared `.eslintrc.js` config extending `@company/eslint-config`
- adds `.prettierrc` with the team's standard formatting rules
- updates CI pipeline to run lint checks on PRs
- updates `tsconfig.json` to enable `strict` mode for type-aware linting

Note that the api app does not use the eslint `--cache` directive as the caching does not reliably work with type-aware linting.

> [!WARNING]
> This will cause lint failures on existing code that hasn't been formatted. Run `npm run format:fix` after pulling this branch.

Not related to a ticket

### How to test this change

1. Run `npm run lint:files` in each package — should pass with no errors
2. Run `npm run format:files -- --check` — should report no formatting issues
3. Make a deliberate lint violation (e.g. unused variable) and verify the CI check fails
```

## Refactor PR

```markdown
This PR refactors the emission factors table to separate licensed and unlicensed factor views.

- renames the `useEmissionsFactorsTable` hook to `useEmissionsFactorsLicensedTable` to match functionality
- extracts common table logic into `useEmissionsFactorsTableBase` shared between both views
- updates relevant repository and service methods to allow the querying of only active licensed efs
  - adds cache invalidation to the PATCH api route
- introduces `EmissionsFactorsUnlicensedTable` component for the admin-only view
- updates route configuration in `routes/settings.ts` to serve the correct table based on user permissions

> [!NOTE]
> This should be tested with `EF_AC_V2` as `true` and as `false` to verify both code paths.

Relates to GF-321

### How to test this change

The emissions factors are displayed in the following locations:
- Settings → Factors & Metrics → Emission Factors
- Measure → Data Processing → Manual Entry
- Measure → Supplier → Mapping

Check that each only displays the active, licensed emissions factors as set in the admin portal.

To test the unlicensed view:
1. Log in as an admin user
2. Navigate to Settings → Factors & Metrics → Emission Factors
3. Toggle the "Show unlicensed" switch — verify the unlicensed factors appear in a separate table
4. Verify that non-admin users do not see the toggle
```

import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { parseArgs } from 'node:util'
import { match } from 'ts-pattern'
import { z } from 'zod'

const PERMISSIONS_DIR = 'permissions'
const MANIFEST_FILE = 'manifest.json'
const ROOT_MODULE = '.'
const BUILTIN_ROLES_DOCS = 'https://learn.microsoft.com/azure/role-based-access-control/built-in-roles'
const GRAPH_PERMISSIONS_DOCS = 'https://learn.microsoft.com/graph/permissions-reference'
const ALWAYS_ON_GROUP = 'access_map'

const JsonFileSchema = z.string().endsWith('.json')
const ActionSchema = z.string().regex(/^(\*|Microsoft\.[A-Za-z]+)\/\S+$/)

const ManifestSchema = z.strictObject({
  deployment_version: z.string().regex(/^\d{8}-[0-9a-f]{8}$/),
  custom_role: z.strictObject({ name_prefix: z.string().min(1), description: z.string().min(1), actions_file: JsonFileSchema }),
  builtin_roles_file: JsonFileSchema,
  graph_app_roles_file: JsonFileSchema,
  permission_groups: z
    .array(
      z.strictObject({
        group: z.string().regex(/^[a-z_]+$/),
        label: z.string().min(1),
        description: z.string().min(1),
        module: z.string().min(1),
        actions_file: JsonFileSchema.optional(),
        builtin_role_ids: z.array(z.guid()),
      }),
    )
    .min(1),
})

const ActionsFileSchema = z.array(ActionSchema).min(1)
const NamedIdsFileSchema = z.array(z.strictObject({ name: z.string().min(1), id: z.guid(), reason: z.string().min(1) })).min(1)

const CliSchema = z.union([
  z.strictObject({ mode: z.literal('write'), target: z.string().min(1) }),
  z.strictObject({ mode: z.literal('check'), target: z.string().min(1) }),
])

type Manifest = z.infer<typeof ManifestSchema>
type PermissionGroup = Manifest['permission_groups'][number]
type NamedId = z.infer<typeof NamedIdsFileSchema>[number]

main()

function main(): void {
  const cli = parseCliOrExit()
  const manifest = loadManifest()
  const builtinRoles = loadPermissionFile({ file: manifest.builtin_roles_file, schema: NamedIdsFileSchema })
  assertGroupsAreConsistent({ manifest, builtinRoles })
  const markdown = renderPermissionsDoc({ manifest, builtinRoles })
  match(cli)
    .with({ mode: 'write' }, ({ target }) => writeFileSync(target, markdown))
    .with({ mode: 'check' }, ({ target }) => failWhenStale({ target, markdown }))
    .exhaustive()
}

function parseCliOrExit(): z.infer<typeof CliSchema> {
  const { values } = parseArgs({ options: { write: { type: 'string' }, check: { type: 'string' } }, strict: true })
  const candidate = values.write === undefined ? { mode: 'check', target: values.check } : { mode: 'write', target: values.write }
  const parsed = CliSchema.safeParse(candidate)
  if (!parsed.success) {
    console.error('usage: render-permissions.ts --write <file> | --check <file>')
    process.exit(2)
  }
  return parsed.data
}

function loadManifest(): Manifest {
  return loadPermissionFile({ file: MANIFEST_FILE, schema: ManifestSchema })
}

function loadPermissionFile<Schema extends z.ZodType>({ file, schema }: { file: string; schema: Schema }): z.infer<Schema> {
  const parsed = schema.safeParse(JSON.parse(readFileSync(join(PERMISSIONS_DIR, file), 'utf8')))
  if (!parsed.success) {
    throw new Error(`${PERMISSIONS_DIR}/${file} is invalid: ${z.prettifyError(parsed.error)}`)
  }
  return parsed.data
}

function assertGroupsAreConsistent({ manifest, builtinRoles }: { manifest: Manifest; builtinRoles: NamedId[] }): void {
  const knownRoleIds = new Set(builtinRoles.map(({ id }) => id))
  const problems = manifest.permission_groups.flatMap(({ group, module, builtin_role_ids }) => [
    ...builtin_role_ids.filter((id) => !knownRoleIds.has(id)).map((id) => `${group} assigns ${id}, which ${manifest.builtin_roles_file} does not list`),
    ...(existsSync(join(module, 'main.tf')) ? [] : [`${group} names module ${module}, which has no main.tf`]),
  ])
  const alwaysOn = manifest.permission_groups.some(({ group }) => group === ALWAYS_ON_GROUP)
  const allProblems = alwaysOn ? problems : [...problems, `${MANIFEST_FILE} has no ${ALWAYS_ON_GROUP} group`]
  if (allProblems.length > 0) {
    throw new Error(`${PERMISSIONS_DIR}/${MANIFEST_FILE} is inconsistent:\n${allProblems.join('\n')}`)
  }
}

function renderPermissionsDoc({ manifest, builtinRoles }: { manifest: Manifest; builtinRoles: NamedId[] }): string {
  const coreActions = loadPermissionFile({ file: manifest.custom_role.actions_file, schema: ActionsFileSchema })
  const graphAppRoles = loadPermissionFile({ file: manifest.graph_app_roles_file, schema: NamedIdsFileSchema })
  return [
    '## Permissions',
    '',
    `Act's service principal gets these roles at the subscription or management group and nothing else: exactly what Act requests when you connect Azure from the Act console. The files in [\`${PERMISSIONS_DIR}/\`](${PERMISSIONS_DIR}) are the only source; the modules and this section are built from them, and CI fails when this section drifts from them. The custom role's description carries \`[act:deployment-version=${manifest.deployment_version}]\`.`,
    '',
    '### Custom role',
    '',
    `\`${manifest.custom_role.name_prefix}-<deployment_id>\`, assignable only at the connected scope. It always holds these ${coreActions.length} actions, listed in [\`${PERMISSIONS_DIR}/${manifest.custom_role.actions_file}\`](${PERMISSIONS_DIR}/${manifest.custom_role.actions_file}):`,
    '',
    '| Resource provider | Actions |',
    '| ----------------- | ------- |',
    ...renderActionRows({ actions: coreActions }),
    '',
    '### Built-in roles',
    '',
    `Without \`permission_groups\`, the module also assigns these built-in roles at the scope, listed in [\`${PERMISSIONS_DIR}/${manifest.builtin_roles_file}\`](${PERMISSIONS_DIR}/${manifest.builtin_roles_file}). Set \`assign_builtin_roles = false\` when another deployment on the scope already assigns them.`,
    '',
    '| Role | ID | Why |',
    '| ---- | -- | --- |',
    ...builtinRoles.map((role) => `| [${role.name}](${BUILTIN_ROLES_DOCS}) | \`${role.id}\` | ${role.reason} |`),
    '',
    '### Permission groups',
    '',
    `Set \`permission_groups\` to the groups Act's onboarding lists, each set to \`{}\`. Any map switches the root module to permission groups: \`${ALWAYS_ON_GROUP}\` is always on, and the module assigns only the built-in roles the groups need (\`keep_legacy_builtin_roles\` keeps the others). An unknown group fails at plan.`,
    '',
    '| Group | What it grants | Created by | Custom role actions | Built-in roles |',
    '| ----- | -------------- | ---------- | ------------------- | -------------- |',
    ...manifest.permission_groups.map((group) => renderPermissionGroupRow({ group, builtinRoles })),
    '',
    '### Microsoft Graph application permissions',
    '',
    `Approving Act's app with Entra ID included grants it these application permissions in the tenant, listed in [\`${PERMISSIONS_DIR}/${manifest.graph_app_roles_file}\`](${PERMISSIONS_DIR}/${manifest.graph_app_roles_file}). An Entra administrator grants them through Act's consent link; no module here creates, grants or removes them.`,
    '',
    '| Permission | App role ID | Why |',
    '| ---------- | ----------- | --- |',
    ...graphAppRoles.map((role) => `| [\`${role.name}\`](${GRAPH_PERMISSIONS_DOCS}) | \`${role.id}\` | ${role.reason} |`),
    '',
  ].join('\n')
}

function renderActionRows({ actions }: { actions: string[] }): string[] {
  const byProvider = Map.groupBy(actions, (action) => action.split('/', 1)[0] ?? action)
  return [...byProvider.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([provider, providerActions]) => `| \`${provider}\` | ${providerActions.map((action) => `\`${action}\``).join(', ')} |`)
}

function renderPermissionGroupRow({ group, builtinRoles }: { group: PermissionGroup; builtinRoles: NamedId[] }): string {
  const actions = group.actions_file === undefined ? [] : loadPermissionFile({ file: group.actions_file, schema: ActionsFileSchema })
  const roles = builtinRoles.filter(({ id }) => group.builtin_role_ids.includes(id)).map(({ name }) => name)
  return `| \`${group.group}\` | **${group.label}.** ${group.description} | ${renderModuleLink({ module: group.module })} | ${renderCodeList({ items: actions })} | ${renderCodeList({ items: roles })} |`
}

function renderModuleLink({ module }: { module: string }): string {
  return module === ROOT_MODULE ? 'root module' : `[\`${module}\`](${module})`
}

function renderCodeList({ items }: { items: string[] }): string {
  return items.length === 0 ? 'none' : items.map((item) => `\`${item}\``).join(', ')
}

function failWhenStale({ target, markdown }: { target: string; markdown: string }): void {
  if (readFileSync(target, 'utf8') !== markdown) {
    console.error(`${target} is stale. Run make docs.`)
    process.exit(1)
  }
}

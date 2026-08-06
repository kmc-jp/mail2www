import { QueryClient, useMutation, useQuery } from '@tanstack/react-query'
import {
  Link,
  Outlet,
  createRootRouteWithContext,
  createRoute,
  createRouter,
  redirect,
} from '@tanstack/react-router'
import * as z from 'zod/mini'
import { api } from './api'
import { Layout, Loading, MessageBody, PageError, Pagination } from './ui'

type RouterContext = { queryClient: QueryClient }

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => <Layout><Outlet /></Layout>,
  errorComponent: ({ error }) => <PageError error={error} />,
  notFoundComponent: () => <PageError error={new Error('Page not found')} />,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  beforeLoad: async ({ context }) => {
    const config = await context.queryClient.ensureQueryData({ queryKey: ['config'], queryFn: api.config })
    if (!config.folders[0]) throw new Error('No mail folders are configured')
    throw redirect({ to: '/$folder', params: { folder: config.folders[0] } })
  },
})

const searchSchema = z.object({
  page: z._default(z.coerce.number(), 0),
  perPage: z._default(z.coerce.number(), 20),
})

const folderRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/$folder',
  validateSearch: searchSchema,
  component: FolderPage,
})

function FolderPage() {
  const { folder } = folderRoute.useParams()
  const { page, perPage } = folderRoute.useSearch()
  const query = useQuery({
    queryKey: ['messages', folder, page, perPage],
    queryFn: () => api.messages(folder, page, perPage),
  })
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  const data = query.data
  return <main className="content">
    <div className="list-controls">
      <Pagination folder={folder} page={data.page} pages={data.pages} perPage={data.per_page} />
      <label>Per page <select value={data.per_page} onChange={(event) => {
        void router.navigate({ to: '/$folder', params: { folder }, search: { page: 0, perPage: Number(event.target.value) } })
      }}>
        {[10, 20, 50, 100].map((amount) => <option key={amount}>{amount}</option>)}
      </select></label>
    </div>
    <div className="table-wrap"><table className="mail-list">
      <thead><tr><th>Time</th><th>No.</th><th>From</th><th>Subject</th></tr></thead>
      <tbody>{data.messages.map((message) => <tr key={message.number}>
        <td className="time">{message.date ? new Date(message.date).toLocaleDateString() : '—'} <small>{message.age}</small></td>
        <td><Link to="/$folder/$number" params={{ folder, number: message.number }}>{message.number}</Link></td>
        <td>{message.from || '—'}</td>
        <td><Link to="/$folder/$number" params={{ folder, number: message.number }}>{message.subject}</Link></td>
      </tr>)}</tbody>
    </table></div>
  </main>
}

const messageRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/$folder/$number',
  component: MessagePage,
})

function MessagePage() {
  const { folder, number } = messageRoute.useParams()
  const query = useQuery({ queryKey: ['message', folder, number], queryFn: () => api.message(folder, number) })
  const forward = useMutation({ mutationFn: (to: string) => api.forward(folder, number, to) })
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  const mail = query.data
  const dangerous = mail.spam || Boolean(mail.virus)
  const confirmRisk = () => !dangerous || window.confirm('This content may be dangerous. Continue?')
  return <main className="content message">
    {mail.virus && <div className="alert">A virus was detected in this message: {mail.virus}</div>}
    {mail.spam && <div className="alert">This message was classified as spam.</div>}
    <div className="actions">
      {mail.remote_user && <button disabled={forward.isPending} onClick={() => forward.mutate(mail.remote_user!)}>
        {forward.isPending ? 'Forwarding…' : `Forward to ${mail.remote_user}`}
      </button>}
      <Link className="button" to="/$folder/$number/source" params={{ folder, number }}>View source</Link>
      {forward.isSuccess && <span className="success">Forwarded.</span>}
      {forward.error && <span className="error">{forward.error.message}</span>}
    </div>
    <dl className="headers">{Object.entries(mail.headers).map(([name, value]) => <div key={name}>
      <dt>{name}</dt><dd>{value || '(none)'}</dd>
    </div>)}</dl>
    <MessageBody text={mail.body} dangerous={dangerous} />
    {mail.attachments.length > 0 && <section className="attachments"><h2>Attachments</h2><ul>
      {mail.attachments.map((file) => <li key={file.filename}><a href={api.attachmentUrl(folder, number, file.filename)} onClick={(e) => {
        if (!confirmRisk()) e.preventDefault()
      }}>{file.filename}</a></li>)}
    </ul></section>}
  </main>
}

const sourceRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/$folder/$number/source',
  component: SourcePage,
})

function SourcePage() {
  const { folder, number } = sourceRoute.useParams()
  const query = useQuery({ queryKey: ['source', folder, number], queryFn: () => api.source(folder, number) })
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  return <main className="content message">
    <div className="actions"><a className="button" href={api.sourceDownloadUrl(folder, number)}>Download message</a></div>
    <pre className="mail-body">{query.data.source}</pre>
  </main>
}

const routeTree = rootRoute.addChildren([indexRoute, folderRoute, messageRoute, sourceRoute])
export const router = createRouter({ routeTree, context: { queryClient: undefined! } })

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}

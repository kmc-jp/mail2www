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
import { DEFAULT_PER_PAGE } from './constants'
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
  perPage: z._default(z.coerce.number(), DEFAULT_PER_PAGE),
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
  return <>
    <div className="pages main"><table><tbody><tr><td>
      <Pagination folder={folder} page={data.page} pages={data.pages} perPage={data.per_page} />
    </td></tr></tbody></table></div>
    <div className="main per-page">per-page:{' '}
      {[10, 20, 50, 100].map((amount) => <Link key={amount} to="/$folder" params={{ folder }} search={{ page: 0, perPage: amount }}>{amount}{' '}</Link>)}
    </div>
    <div className="autopagerize_page_element"><div className="main"><table id="mail_list">
      <thead><tr><th>time</th><th>no</th><th>from</th><th>subject</th></tr></thead>
      <tbody>{data.messages.map((message) => <tr key={message.number}>
        <td className="time">{message.date ? formatMailDate(message.date) : ''}</td>
        <td className="num"><Link to="/$folder/$number" params={{ folder, number: message.number }}>{message.number}</Link></td>
        <td className="from">{message.from}</td>
        <td className="subj"><Link to="/$folder/$number" params={{ folder, number: message.number }}>{message.subject}</Link></td>
      </tr>)}</tbody>
    </table></div></div>
    <div className="autopagerize_insert_before" />
  </>
}

function formatMailDate(value: string) {
  const date = new Date(value)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const seconds = Math.max(0, (Date.now() - date.getTime()) / 1_000)
  const minute = 60
  const hour = 60 * minute
  const fullDay = 24 * hour
  let age: string

  if (seconds < minute) age = `${Math.floor(seconds)}s`
  else if (seconds < hour) age = `${Math.floor(seconds / minute)}m`
  else if (seconds < fullDay) age = `${Math.floor(seconds / hour)}h`
  else if (seconds <= 30 * fullDay) age = `${Math.floor(seconds / fullDay)}d`
  else age = `${Math.floor(seconds / (30 * fullDay))}M`

  return `${year}/${month}/${day} (${age})`
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
  const confirmAttachmentRisk = () => !dangerous || window.confirm('この添付ファイルは危険な可能性があります。本当にダウンロードしますか？')
  const header = Object.entries(mail.headers).map(([name, value]) => `${name[0].toUpperCase()}${name.slice(1)}: ${value || '(none)'}`).join('\n')
  return <div className="mail">
    {mail.virus && <div className="mail-virus mail-alert">このメールにはウイルスが検出されています: {mail.virus}</div>}
    {mail.spam && <div className="mail-spam mail-alert">このメールはスパムメールと判定されています</div>}
    <div className="mail-actions">
      {mail.remote_user && <form onSubmit={(event) => { event.preventDefault(); forward.mutate(mail.remote_user!) }}><button disabled={forward.isPending}>
        {mail.remote_user}へ転送
      </button></form>}
      <form onSubmit={(event) => { event.preventDefault(); void router.navigate({ to: '/$folder/$number/source', params: { folder, number } }) }}><button>ソースを表示</button></form>
      {forward.error && <span className="error">{forward.error.message}</span>}
    </div>
    <pre>{header}</pre>
    <hr />
    <MessageBody text={mail.body} dangerous={dangerous} />
    {mail.attachments.length > 0 && <><hr /><pre>添付ファイル:</pre><ul className="mail-attachments">
      {mail.attachments.map((file) => <li key={file.filename}><a href={api.attachmentUrl(folder, number, file.filename)} onClick={(e) => {
        if (!confirmAttachmentRisk()) e.preventDefault()
      }}>{file.filename}</a></li>)}
    </ul></>}
  </div>
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
  return <>
    <div><a href={api.sourceDownloadUrl(folder, number)}>このメッセージをダウンロード</a></div>
    <div className="mail"><pre>{query.data.source}</pre></div>
  </>
}

const routeTree = rootRoute.addChildren([indexRoute, folderRoute, messageRoute, sourceRoute])
export const router = createRouter({ routeTree, context: { queryClient: undefined! } })

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}

import { queryOptions, useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { api } from '../api'
import { Loading, PageError } from '../components/Status'
import { Pagination } from '../components/Pagination'

export function FolderPage({ folder, page, perPage }: { folder: string, page: number, perPage: number }) {
  const query = useQuery(messagesQueryOptions(folder, page, perPage))
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

export const messagesQueryOptions = (folder: string, page: number, perPage: number) =>
  queryOptions({
    queryKey: ['messages', folder, page, perPage],
    queryFn: () => api.messages(folder, page, perPage),
  })

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

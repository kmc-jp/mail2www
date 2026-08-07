import { queryOptions, useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { Fragment } from 'react'
import { api } from '../api'
import { formatAddresses } from '../addresses'
import { Loading, PageError } from '../components/Status'
import { Pagination } from '../components/Pagination'
import { formatRelativeAge } from '../date'

export function FolderPage({ folder, page, perPage }: { folder: string, page: number, perPage: number }) {
  const query = useQuery(messagesQueryOptions(folder, page, perPage))
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  const data = query.data
  return <>
    <div className="pages main"><table><tbody><tr><td>
      <Pagination folder={folder} page={data.page} pages={data.pages} perPage={data.per_page} />
    </td></tr></tbody></table></div>
    <div className="main per-page">per-page:
      {[10, 20, 50, 100].map((amount) => <Fragment key={amount}>{' '}<Link to="/$folder" params={{ folder }} search={{ page: 0, perPage: amount }}>{amount}</Link></Fragment>)}
    </div >
    <div className="autopagerize_page_element"><div className="main"><table id="mail_list">
      <thead><tr><th>time</th><th>no</th><th>from</th><th>subject</th></tr></thead>
      <tbody>{data.messages.map((message) => <tr key={message.number}>
        <td className="time">{message.date ? `${message.date.toLocaleDateString(undefined, { timeZone: 'Asia/Tokyo' })} (${formatRelativeAge(message.date)})` : ''}</td>
        <td className="num"><Link to="/$folder/$number" params={{ folder, number: message.number }}>{message.number}</Link></td>
        <td className="from">{formatAddresses(message.from)}</td>
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

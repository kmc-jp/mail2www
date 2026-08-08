import { queryOptions, useMutation, useQuery } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { api } from '../api'
import { useAppConfig } from '../components/AppConfig'
import { Mailboxes } from '../components/Mailbox'
import { MessageBody } from '../components/MessageBody'
import { Loading, PageError } from '../components/Status'

export function MessagePage({ folder, number }: { folder: string, number: string }) {
  const navigate = useNavigate()
  const config = useAppConfig()
  const query = useQuery(messageQueryOptions(folder, number))
  const forward = useMutation({ mutationFn: (to: string) => api.forward(folder, number, to) })
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  const mail = query.data
  const remoteUser = config.remote_user
  const dangerous = mail.spam || Boolean(mail.virus)
  const confirmAttachmentRisk = () => !dangerous || window.confirm('この添付ファイルは危険な可能性があります。本当にダウンロードしますか？')
  const headers: [string, React.ReactNode][] = [
    ['From', <Mailboxes key="from" mailboxes={mail.headers.from} />],
    ['To', <Mailboxes key="to" mailboxes={mail.headers.to} />],
    ['Cc', <Mailboxes key="cc" mailboxes={mail.headers.cc} />],
    ['Subject', mail.headers.subject],
    ['Date', mail.headers.date ? mail.headers.date.toLocaleString(undefined, { timeZone: 'Asia/Tokyo' }) : '(none)'],
  ]
  return <div className="mail">
    {mail.virus && <div className="mail-virus mail-alert">このメールにはウイルスが検出されています: {mail.virus}</div>}
    {mail.spam && <div className="mail-spam mail-alert">このメールはスパムメールと判定されています</div>}
    <div className="mail-actions">
      {remoteUser && <form onSubmit={(event) => { event.preventDefault(); forward.mutate(remoteUser) }}><button disabled={forward.isPending}>
        {remoteUser}へ転送
      </button></form>}
      <form onSubmit={(event) => { event.preventDefault(); void navigate({ to: '/$folder/$number/source', params: { folder, number } }) }}><button>ソースを表示</button></form>
      {forward.error && <span className="error">{forward.error.message}</span>}
    </div>
    <table className="mail-headers"><tbody>
      {headers.map(([name, value]) => <tr key={name}><th scope="row">{name}:</th><td>{value}</td></tr>)}
    </tbody></table>
    <hr />
    {mail.body.text && <MessageBody text={mail.body.text} dangerous={dangerous} />}
    {mail.body.text && mail.body.html && <hr />}
    {mail.body.html && <MessageBody text={mail.body.html} dangerous={dangerous} />}
    {mail.attachments.length > 0 && <><hr /><pre>添付ファイル:</pre><ul className="mail-attachments">
      {mail.attachments.map((file) => <li key={file.filename}><a href={api.attachmentUrl(folder, number, file.filename)} onClick={(event) => {
        if (!confirmAttachmentRisk()) event.preventDefault()
      }}>{file.filename}</a></li>)}
    </ul></>}
  </div>
}

export const messageQueryOptions = (folder: string, number: string) => queryOptions({
  queryKey: ['message', folder, number],
  queryFn: () => api.message(folder, number),
})

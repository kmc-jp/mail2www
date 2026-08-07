import { queryOptions, useQuery } from '@tanstack/react-query'
import { api } from '../api'
import { Loading, PageError } from '../components/Status'

export function SourcePage({ folder, number }: { folder: string, number: string }) {
  const query = useQuery(sourceQueryOptions(folder, number))
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  return <>
    <div><a href={api.sourceDownloadUrl(folder, number)}>このメッセージをダウンロード</a></div>
    <div className="mail"><pre>{query.data.source}</pre></div>
  </>
}

export const sourceQueryOptions = (folder: string, number: string) => queryOptions({
  queryKey: ['source', folder, number],
  queryFn: () => api.source(folder, number),
})

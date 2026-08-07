import { queryOptions, useQuery } from '@tanstack/react-query'
import { createContext, useContext, type ReactNode } from 'react'
import { api, type AppConfig } from '../api'
import { Loading, PageError } from './Status'

export const appConfigQueryOptions = queryOptions({
  queryKey: ['config'],
  queryFn: api.config,
})

const AppConfigContext = createContext<AppConfig | undefined>(undefined)

export function AppConfigProvider({ children }: { children: ReactNode }) {
  const query = useQuery(appConfigQueryOptions)
  if (query.isPending) return <Loading />
  if (query.isError) return <PageError error={query.error} />
  return <AppConfigContext value={query.data}>{children}</AppConfigContext>
}

export function useAppConfig() {
  const config = useContext(AppConfigContext)
  if (!config) throw new Error('useAppConfig must be used within AppConfigProvider')
  return config
}

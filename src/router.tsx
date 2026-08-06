import { type QueryClient } from '@tanstack/react-query'
import {
  Outlet,
  createRootRouteWithContext,
  createRoute,
  createRouter,
  redirect,
} from '@tanstack/react-router'
import * as z from 'zod/mini'
import { api } from './api'
import { Layout } from './components/Layout'
import { PageError } from './components/Status'
import { DEFAULT_PER_PAGE } from './constants'
import { FolderPage } from './pages/folder'
import { MessagePage } from './pages/message'
import { SourcePage } from './pages/source'

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
  component: FolderRoute,
})

function FolderRoute() {
  const { folder } = folderRoute.useParams()
  const { page, perPage } = folderRoute.useSearch()
  return <FolderPage folder={folder} page={page} perPage={perPage} />
}

const messageRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/$folder/$number',
  component: MessageRoute,
})

function MessageRoute() {
  const { folder, number } = messageRoute.useParams()
  return <MessagePage folder={folder} number={number} />
}

const sourceRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/$folder/$number/source',
  component: SourceRoute,
})

function SourceRoute() {
  const { folder, number } = sourceRoute.useParams()
  return <SourcePage folder={folder} number={number} />
}

const routeTree = rootRoute.addChildren([indexRoute, folderRoute, messageRoute, sourceRoute])
export const router = createRouter({ routeTree, context: { queryClient: undefined! } })

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}

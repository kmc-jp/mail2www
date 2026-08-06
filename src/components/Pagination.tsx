import { Link } from '@tanstack/react-router'

export function Pagination({ folder, page, pages, perPage }: { folder: string, page: number, pages: number, perPage: number }) {
  return <>{Array.from({ length: pages }, (_, index) => <span key={index} className={index === page ? 'page_sel' : 'page'}>
    <Link to="/$folder" params={{ folder }} search={{ page: index, perPage }}>{index === page ? `[${index}]` : index}</Link>{' '}
  </span>)}</>
}

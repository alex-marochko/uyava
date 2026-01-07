const base = import.meta.env.BASE_URL || '/';

export function withBase(pathname: string) {
  if (pathname.startsWith('http://') || pathname.startsWith('https://')) {
    return pathname;
  }

  const trimmed = pathname.startsWith('/') ? pathname.slice(1) : pathname;
  if (base === '/') {
    return `/${trimmed}`;
  }
  return `${base}${trimmed}`;
}

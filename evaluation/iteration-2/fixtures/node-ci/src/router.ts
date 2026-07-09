export function route(path: string): number {
  return path === "/health" ? 200 : 404;
}

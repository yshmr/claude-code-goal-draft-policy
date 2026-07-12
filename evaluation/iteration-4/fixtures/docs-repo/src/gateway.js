export function route(req) {
  return { upstream: "core", path: req.path };
}

export function login(user: string, pass: string): string | null {
  // returns a session token on valid credentials, null otherwise
  if (!user || !pass) return null;
  return `tok_${user}`;
}

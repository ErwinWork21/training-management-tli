import { NextResponse, type NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';

// Route prefix -> roles allowed to access it.
const ROLE_ROUTES: Record<string, string[]> = {
  '/admin': ['admin'],
  '/trainer': ['trainer', 'admin'],
  '/supervisor': ['supervisor', 'admin'],
  '/trainee': ['trainee', 'admin'],
};

export async function middleware(request: NextRequest) {
  const { response, user, supabase } = await updateSession(request);
  const { pathname } = request.nextUrl;

  const isAuthRoute = pathname.startsWith('/login');

  if (!user) {
    if (isAuthRoute) return response;
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('redirectTo', pathname);
    return NextResponse.redirect(url);
  }

  // Signed in but hitting /login -> send to their dashboard.
  if (isAuthRoute) {
    const url = request.nextUrl.clone();
    url.pathname = '/';
    return NextResponse.redirect(url);
  }

  const matchedPrefix = Object.keys(ROLE_ROUTES).find((prefix) => pathname.startsWith(prefix));
  if (matchedPrefix) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role, is_active')
      .eq('id', user.id)
      .single();

    const allowed = ROLE_ROUTES[matchedPrefix];
    if (!profile || !profile.is_active || !allowed?.includes(profile.role)) {
      const url = request.nextUrl.clone();
      url.pathname = '/';
      return NextResponse.redirect(url);
    }
  }

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except static assets and Next internals.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};

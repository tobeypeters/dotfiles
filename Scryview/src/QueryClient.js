import { QueryClient } from '@tanstack/react-query';

export const client = new QueryClient({
  staleTime: Infinity, // Data never becomes stale
  cacheTime: 24* 60 * 60 * 1000, // 24 hours cache
  refetchOnWindowFocus: false,
  refetchOnReconnect: false,
  refetchOnMount: false // Don't refetch when component mounts
});
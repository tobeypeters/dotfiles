export const paginate = (currentPage, totalPages, hasMore) => {
  const pages = [];
  const MAX_VISIBLE_PAGES = 5;

  // Previous button
  if (currentPage > 1) {
    pages.push({ type: 'prev', page: currentPage - 1 });
  }

  // Always show first page if not in the first 3 pages
  if (currentPage > 3 && totalPages > MAX_VISIBLE_PAGES) {
    pages.push({ type: 'page', page: 1 });
    if (currentPage > 4) {
      pages.push({ type: 'ellipsis' });
    }
  }

  // Calculate visible page range
  let startPage = Math.max(1, currentPage - 2);
  let endPage = Math.min(totalPages, currentPage + 2);

  // Adjust if we're at the beginning
  if (currentPage <= 2) {
    endPage = Math.min(MAX_VISIBLE_PAGES, totalPages);
  }
  // Adjust if we're at the end
  if (currentPage >= totalPages - 1) {
    startPage = Math.max(1, totalPages - MAX_VISIBLE_PAGES + 1);
  }

  // Add visible pages
  for (let i = startPage; i <= endPage; i++) {
    pages.push({
      type: 'page',
      page: i,
      isCurrent: i === currentPage
    });
  }

  // Show last page if not in visible range
  if (endPage < totalPages - 1) {
    if (endPage < totalPages - 2) {
      pages.push({ type: 'ellipsis' });
    }
    pages.push({ type: 'page', page: totalPages });
  }

  // Next button
  if (currentPage < totalPages || hasMore) {
    pages.push({
      type: 'next',
      page: currentPage + 1,
      disabled: !hasMore && currentPage >= totalPages
    });
  }

  return pages;
};
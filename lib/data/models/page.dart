/// A paginated API response (backend `PaginationDto`). TTL-meta shape is
/// confirmed at Swagger hand-off; defaults used until then.
class Page<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  const Page({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  bool get hasMore => page * pageSize < total;
  int get pageCount => pageSize == 0 ? 0 : (total / pageSize).ceil();
}

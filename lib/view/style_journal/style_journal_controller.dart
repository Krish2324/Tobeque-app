import 'package:get/get.dart';
import 'style_journal_repository.dart';

class StyleJournalController extends GetxController {
  final repo = StyleJournalRepository();

  final loading = true.obs;
  final error = RxnString();
  final posts = <JournalPost>[].obs;

  final hasMore = true.obs;
  final _page = 1.obs;
  final _perPage = 10;

  @override
  void onInit() {
    super.onInit();
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    try {
      loading.value = true;
      error.value = null;
      _page.value = 1;
      final list = await repo.fetchPosts(page: 1, perPage: _perPage);
      posts.assignAll(list);
      hasMore.value = list.length == _perPage;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || loading.value) return;
    try {
      loading.value = true;
      final next = _page.value + 1;
      final list = await repo.fetchPosts(page: next, perPage: _perPage);
      posts.addAll(list);
      _page.value = next;
      hasMore.value = list.length == _perPage;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshNow() => loadFirstPage();
}

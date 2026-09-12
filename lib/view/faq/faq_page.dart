// lib/view/faq/faq_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

class FaqRepository {
  final Dio _dio = DioClient.build();

  Future<List<Map<String, dynamic>>> fetchFaqs() async {
    try {
      final res  = await _dio.get(ApiConstant.faqs);
      final data = res.data;
      List list  = [];
      if (data is Map && data['faqs'] is List) {
        list = data['faqs'];
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class FaqController extends GetxController {
  final _repo = FaqRepository();

  final loading     = true.obs;
  final error       = RxnString();
  final faqs        = <Map<String, dynamic>>[].obs;
  final openIndex   = RxnInt();  // currently expanded FAQ index

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    loading.value = true;
    error.value   = null;
    try {
      final data = await _repo.fetchFaqs();
      faqs.assignAll(data);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void toggleFaq(int index) {
    openIndex.value = (openIndex.value == index) ? null : index;
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FaqController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          onPressed: Get.back,
        ),
        title: const Column(
          children: [
            Text(
              'FAQ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3.0, color: Colors.black),
            ),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Obx(() {
        if (c.loading.value) return _FaqSkeleton();
        if (c.error.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.black26),
                const SizedBox(height: 12),
                Text(c.error.value!, style: const TextStyle(color: Color(0xFF6B6B6B))),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: c.fetchAll,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
              ],
            ),
          );
        }

        if (c.faqs.isEmpty) {
          return const Center(
            child: Text('No FAQs available', style: TextStyle(color: Color(0xFF9E9E9E))),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Intro
            const Text(
              'Have questions? We have answers.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: -0.5, color: Color(0xFF0D0D0D)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse our most commonly asked questions below.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.5),
            ),
            const SizedBox(height: 28),

            // FAQ Items — animated accordion
            ...List.generate(c.faqs.length, (i) {
              final faq     = c.faqs[i];
              final question = faq['question']?.toString() ?? '';
              final answer   = faq['answer']?.toString() ?? '';

              return Obx(() {
                final isOpen = c.openIndex.value == i;
                return Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => c.toggleFaq(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                question,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isOpen ? const Color(0xFF0D0D0D) : const Color(0xFF1A1A1A),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedRotation(
                              turns: isOpen ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: const Icon(Icons.keyboard_arrow_down, size: 22, color: Color(0xFF0D0D0D)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Animated answer
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B6B6B),
                            height: 1.65,
                          ),
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ],
                );
              });
            }),

            const SizedBox(height: 40),

            // Still have questions CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF6F6F5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still have questions?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Our team is here to help. Reach out to us anytime.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
                      child: const Text(
                        'CONTACT US',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _FaqSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: List.generate(6, (i) => Shimmer.fromColors(
        baseColor: const Color(0xFFF0F0F0),
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: double.infinity, color: const Color(0xFFF0F0F0)),
              const SizedBox(height: 6),
              Container(height: 16, width: MediaQuery.of(context).size.width * 0.6, color: const Color(0xFFF0F0F0)),
              const Divider(height: 32),
            ],
          ),
        ),
      )),
    );
  }
}

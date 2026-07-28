import 'package:flutter/material.dart';

class ProductSkeletonGrid extends StatelessWidget {
  final int count;
  const ProductSkeletonGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 420,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 10, color: const Color(0xFFE5E5E5)),
                  const SizedBox(height: 10),
                  Container(width: 160, height: 16, color: const Color(0xFFE0E0E0)),
                  const SizedBox(height: 10),
                  Container(width: 100, height: 14, color: const Color(0xFFE5E5E5)),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, height: 42, color: const Color(0xFFF0F0F2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

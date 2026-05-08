import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khayyat/utils/app_colors.dart';
import 'package:uuid/uuid.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;

  const LeaveReviewScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db   = FirebaseFirestore.instance;

      // Get customer name from users collection
      final userDoc = await db.collection('users').doc(user.uid).get();
      final customerName =
          userDoc.data()?['name'] as String? ?? 'Customer';
      final customerId = userDoc.data()?['phone'] as String? ?? user.uid;

      final shopRef   = db.collection('shops').doc(widget.shopId);
      final reviewRef = shopRef.collection('reviews').doc(const Uuid().v4());
      final newStars  = _selectedRating;
      final comment   = _commentController.text.trim();

      // Use a transaction to atomically write the review and update shop rating
      await db.runTransaction((tx) async {
        final shopSnap    = await tx.get(shopRef);
        final data        = shopSnap.data() ?? {};
        final oldRating   = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;

        final newRating = totalRatings == 0
            ? newStars.toDouble()
            : ((oldRating * totalRatings) + newStars) / (totalRatings + 1);

        tx.set(reviewRef, {
          'customerId':    customerId,
          'customerName':  customerName,
          'rating':        newStars,
          'comment':       comment.isEmpty ? null : comment,
          'createdAt':     FieldValue.serverTimestamp(),
        });

        tx.update(shopRef, {
          'rating':       double.parse(newRating.toStringAsFixed(1)),
          'totalRatings': FieldValue.increment(1),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted. Thank you!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Leave a Review',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.dark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Shop name ─────────────────────────────────────────────
            Text(
              'Review for',
              style: const TextStyle(fontSize: 13, color: AppColors.gray),
            ),
            const SizedBox(height: 2),
            Text(
              widget.shopName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),

            const SizedBox(height: 32),

            // ── Star rating ───────────────────────────────────────────
            const Text(
              'Your Rating',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      star <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 42,
                      color: star <= _selectedRating
                          ? const Color(0xFFF39C12)
                          : AppColors.gray.withValues(alpha: 0.4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _ratingLabel(_selectedRating),
              style: TextStyle(
                fontSize: 13,
                color: _selectedRating > 0
                    ? const Color(0xFFF39C12)
                    : AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 28),

            // ── Comment ───────────────────────────────────────────────
            const Text(
              'Comment (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 300,
                style: const TextStyle(fontSize: 14, color: AppColors.dark),
                decoration: InputDecoration(
                  hintText:
                      'Share your experience with this tailor…',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.gray),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle:
                      const TextStyle(fontSize: 11, color: AppColors.gray),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  disabledBackgroundColor:
                      AppColors.navy.withValues(alpha: 0.5),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very Good',
        5 => 'Excellent!',
        _ => 'Tap a star to rate',
      };
}

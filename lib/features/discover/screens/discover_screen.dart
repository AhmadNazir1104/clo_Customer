import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khayyat/features/discover/view_model/discover_provider.dart';
import 'package:khayyat/features/discover/widgets/tailor_card.dart';
import 'package:khayyat/model/shop_model.dart';
import 'package:khayyat/utils/app_colors.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCity = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NearbyTab(query: _query, selectedCity: _selectedCity,
                      onCityChanged: (c) => setState(() => _selectedCity = c)),
                  _TopTab(query: _query, selectedCity: _selectedCity,
                      onCityChanged: (c) => setState(() => _selectedCity = c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Discover Tailors',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 6),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
          style: const TextStyle(fontSize: 14, color: AppColors.dark),
          decoration: InputDecoration(
            hintText: 'Search by name, city or speciality…',
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.gray),
            prefixIcon:
                const Icon(Icons.search, size: 20, color: AppColors.gray),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18,
                        color: AppColors.gray),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.gray,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorColor: AppColors.navy,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Nearby'),
          Tab(text: 'Top Tailors'),
        ],
      ),
    );
  }
}

// ── Nearby tab ────────────────────────────────────────────────────────────────

class _NearbyTab extends ConsumerWidget {
  final String query;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const _NearbyTab({
    required this.query,
    required this.selectedCity,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyTailorsProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      ),
      error: (e, _) => _ErrorView(
        message: 'Failed to load nearby tailors.',
        onRetry: () => ref.invalidate(nearbyTailorsProvider),
      ),
      data: (shops) {
        final cities = _extractCities(shops.map((s) => s.shop).toList());
        final filtered = _filter(shops, query, selectedCity);

        if (shops.isEmpty) {
          return const _EmptyView(
            icon: Icons.near_me_outlined,
            message: 'No tailors found in your area yet.',
          );
        }

        return _ShopList(
          shops: filtered,
          cities: cities,
          selectedCity: selectedCity,
          onCityChanged: onCityChanged,
          emptyMessage: 'No tailors match your search.',
        );
      },
    );
  }
}

// ── Top tailors tab ───────────────────────────────────────────────────────────

class _TopTab extends ConsumerWidget {
  final String query;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const _TopTab({
    required this.query,
    required this.selectedCity,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topTailorsProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      ),
      error: (e, _) => _ErrorView(
        message: 'Failed to load top tailors.',
        onRetry: () => ref.invalidate(topTailorsProvider),
      ),
      data: (shops) {
        final cities = _extractCities(shops.map((s) => s.shop).toList());
        final filtered = _filter(shops, query, selectedCity);

        if (shops.isEmpty) {
          return const _EmptyView(
            icon: Icons.star_border_rounded,
            message: 'No top tailors yet.\nCheck back soon!',
          );
        }

        return _ShopList(
          shops: filtered,
          cities: cities,
          selectedCity: selectedCity,
          onCityChanged: onCityChanged,
          emptyMessage: 'No tailors match your search.',
        );
      },
    );
  }
}

// ── Shared shop list with city filter ────────────────────────────────────────

class _ShopList extends StatelessWidget {
  final List<DiscoverShop> shops;
  final List<String> cities;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;
  final String emptyMessage;

  const _ShopList({
    required this.shops,
    required this.cities,
    required this.selectedCity,
    required this.onCityChanged,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cities.length > 1) _CityFilter(
          cities: cities,
          selected: selectedCity,
          onChanged: onCityChanged,
        ),
        Expanded(
          child: shops.isEmpty
              ? _EmptyView(
                  icon: Icons.search_off_rounded,
                  message: emptyMessage,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: shops.length,
                  itemBuilder: (context, i) => TailorCard(
                    discoverShop: shops[i],
                    onTap: () => context.push(
                      '/discover/${shops[i].shop.shopId}',
                      extra: shops[i].shop,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── City filter chips ─────────────────────────────────────────────────────────

class _CityFilter extends StatelessWidget {
  final List<String> cities;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CityFilter({
    required this.cities,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: cities.map((city) {
          final active = city == selected;
          return GestureDetector(
            onTap: () => onChanged(city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color:
                    active ? AppColors.navy : AppColors.navy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                city,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : AppColors.navy,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<String> _extractCities(List<ShopModel> shops) {
  final cities = shops
      .map((s) => s.city.trim())
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return ['All', ...cities];
}

List<DiscoverShop> _filter(
    List<DiscoverShop> shops, String query, String city) {
  return shops.where((ds) {
    final s = ds.shop;

    // City filter
    if (city != 'All' && s.city.trim() != city) return false;

    // Search query
    if (query.isEmpty) return true;
    return s.name.toLowerCase().contains(query) ||
        s.city.toLowerCase().contains(query) ||
        s.area.toLowerCase().contains(query) ||
        s.specialities.any((sp) => sp.toLowerCase().contains(query));
  }).toList();
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.gray.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

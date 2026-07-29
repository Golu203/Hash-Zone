import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/hero_banner.dart';
import '../providers/catalog_provider.dart';
import '../widgets/context_menu_wrapper.dart';
import '../widgets/footer.dart';
import '../widgets/navbar.dart';
import '../widgets/product_card.dart';
import '../widgets/promo_popup_dialog.dart';
import '../widgets/skeleton_loaders.dart';
import '../utils/seo_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/business_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _hasShownPopupThisSession = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAndTriggerPromoPopup(BusinessProvider business) {
    if (!_hasShownPopupThisSession && business.settings.isPopupActive && business.settings.popupImageUrl.isNotEmpty) {
      _hasShownPopupThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HZPromoPopupDialog.showIfActive(
            context,
            isActive: true,
            imageUrl: business.settings.popupImageUrl,
            linkUrl: business.settings.popupLinkUrl,
            actionText: business.settings.popupActionText,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final business = Provider.of<BusinessProvider>(context);
    _checkAndTriggerPromoPopup(business);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'HASH ZONE | Premium Wholesale Clothing Manufacturer in Tiruppur',
        description: 'HASH ZONE is a premium wholesale clothing manufacturer and export garment factory in Tiruppur, India. Custom bulk supplier of Polo T-shirts, Hoodies, Kids & Menswear.',
        keywords: 'Wholesale Clothing Manufacturer, Garment Manufacturer Tiruppur, Clothing Factory Tiruppur, Clothing Manufacturer India, Garment Factory India, Bulk Clothing Supplier, Tiruppur, Tamil Nadu, India',
        path: '/',
      );
    });

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 1. Hero Slideshow Carousel Section
            if (catalog.heroBanners.isNotEmpty)
              HeroSlideshowCarousel(
                banners: catalog.heroBanners,
                scrollController: _scrollController,
              )
            else
              _buildDefaultHero(context),

            const SizedBox(height: 60),

            // 2. Department Showcase Grid (Centered & Scrollable)
            if (catalog.departments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _sectionHeader('EXPLORE SEGMENTS', 'CURATED APPAREL CATEGORIES'),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        // Deduplicate by ID to avoid Firestore double-emit
                        final seen = <String>{};
                        final uniqueDepts = catalog.departments.where((d) => seen.add(d.id)).toList();
                        final screenWidth = MediaQuery.of(context).size.width - 48; // subtract padding
                        final crossAxisCount = screenWidth < 460
                            ? 1
                            : screenWidth < 780
                                ? 2
                                : screenWidth < 1080
                                    ? 3
                                    : 4;
                        final gap = 20.0;
                        final cardWidth = (screenWidth - (crossAxisCount - 1) * gap) / crossAxisCount;
                        final cardHeight = cardWidth; // 1:1 square for dept covers

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: uniqueDepts.map((dept) {
                            return SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: GestureDetector(
                                onTap: () {
                                  catalog.toggleOffersOnly(false);
                                  catalog.setDepartmentFilter(dept.id);
                                  context.go('/products');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E5E5)),
                                    image: dept.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(dept.imageUrl),
                                            fit: BoxFit.cover,
                                            colorFilter: ColorFilter.mode(
                                              Colors.black.withValues(alpha: 0.35),
                                              BlendMode.darken,
                                            ),
                                          )
                                        : null,
                                    color: const Color(0xFFF7F7F8),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dept.name,
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: isDesktop ? 28 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dept.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFEEEEEE),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'EXPLORE →',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),

            // 3. Featured Products Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _sectionHeader('FEATURED COLLECTION', 'HANDPICKED STATEMENT PIECES'),
                  const SizedBox(height: 32),
                  if (catalog.isLoading)
                    const ProductSkeletonGrid(count: 3)
                  else if (catalog.featuredProducts.isEmpty)
                    Center(
                      child: Text(
                        'No featured products found.',
                        style: GoogleFonts.inter(color: const Color(0xFF666666)),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final sw = MediaQuery.of(context).size.width - 48;
                        final cols = sw < 460 ? 1 : sw < 780 ? 2 : sw < 1080 ? 3 : 4;
                        final gap = 20.0;
                        final cw = (sw - (cols - 1) * gap) / cols;
                        final isMobile = sw < 460;
                        final infoH = isMobile ? 175.0 : 190.0;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: catalog.featuredProducts.take(8).map((product) {
                            return SizedBox(
                              width: cw,
                              // height = image (3:4) + info section
                              height: cw * (4 / 3) + infoH,
                              child: ProductCard(product: product),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: () {
                      catalog.toggleOffersOnly(false);
                      context.go('/products');
                    },
                    child: const Text('VIEW ENTIRE CATALOG'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),

            // 4. Special Offers Section
            if (catalog.offerProducts.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                color: const Color(0xFFF7F7F8),
                child: Column(
                  children: [
                    _sectionHeader('EXCLUSIVE OFFERS', 'LIMITED SEASONAL DISCOUNTS'),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        final sw = MediaQuery.of(context).size.width - 48;
                        final cols = sw < 460 ? 1 : sw < 780 ? 2 : sw < 1080 ? 3 : 4;
                        final gap = 20.0;
                        final cw = (sw - (cols - 1) * gap) / cols;
                        final isMobile = sw < 460;
                        final infoH = isMobile ? 175.0 : 190.0;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: catalog.offerProducts.take(8).map((product) {
                            return SizedBox(
                              width: cw,
                              // height = image (3:4) + info section
                              height: cw * (4 / 3) + infoH,
                              child: ProductCard(product: product),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),

            // Footer
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultHero(BuildContext context) {
    return Container(
      height: 520,
      width: double.infinity,
      color: const Color(0xFFF7F7F8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HASH ZONE',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AUTUMN / WINTER 2026 DIGITAL CATALOG',
              style: GoogleFonts.inter(
                fontSize: 14,
                letterSpacing: 2.5,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/products'),
              child: const Text('EXPLORE CATALOG'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            letterSpacing: isMobile ? 2.0 : 3.0,
            color: const Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

class HeroSlideshowCarousel extends StatefulWidget {
  final List<HeroBannerItem> banners;
  final ScrollController? scrollController;

  const HeroSlideshowCarousel({
    super.key,
    required this.banners,
    this.scrollController,
  });

  @override
  State<HeroSlideshowCarousel> createState() => _HeroSlideshowCarouselState();
}

class _HeroSlideshowCarouselState extends State<HeroSlideshowCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _slideshowTimer;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startSlideshowTimer();
    widget.scrollController?.addListener(_onScrollListener);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScrollListener);
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onScrollListener() {
    if (mounted) {
      setState(() {
        _scrollOffset = widget.scrollController?.offset ?? 0.0;
      });
    }
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    if (widget.banners.length <= 1) return;

    _slideshowTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    
    // Enforce a perfect 21:9 aspect ratio universally on both desktop
    // and mobile screens to match the uploaded 21:9 banner assets.
    final heroHeight = screenWidth / (21.0 / 9.0);

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Banner PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final hasTitle = banner.title.trim().isNotEmpty;
              final hasSubtitle = banner.subtitle.trim().isNotEmpty;
              final hasButton = banner.buttonText.trim().isNotEmpty;
              final hasContent = hasTitle || hasSubtitle || hasButton;

              return HZContextMenuWrapper(
                imageUrl: banner.imageUrl,
                productTitle: banner.title,
                child: InkWell(
                  onTap: (banner.linkUrl.trim().isNotEmpty) ? () => context.go(banner.linkUrl) : null,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F5F7),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            color: hasContent ? Colors.black.withValues(alpha: 0.45) : null,
                            colorBlendMode: hasContent ? BlendMode.darken : null,
                          ),
                        ),
                        if (hasContent)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasSubtitle) ...[
                                    Text(
                                      banner.subtitle.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: isDesktop ? 13 : 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isDesktop ? 3.0 : 1.5,
                                        color: const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 16 : 6),
                                  ],
                                  if (hasTitle) ...[
                                    Text(
                                      banner.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cormorantGaramond(
                                        fontSize: isDesktop ? 56 : (screenWidth * 0.08).clamp(20.0, 36.0),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: isDesktop ? 4.0 : 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                  if (hasButton) ...[
                                    if (hasTitle || hasSubtitle) SizedBox(height: isDesktop ? 32 : 12),
                                    SizedBox(
                                      height: isDesktop ? 40 : 28,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (banner.linkUrl.trim().isNotEmpty) {
                                            context.go(banner.linkUrl);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isDesktop ? 24 : 12,
                                            vertical: 0,
                                          ),
                                          textStyle: GoogleFonts.inter(
                                            fontSize: isDesktop ? 13 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Text(banner.buttonText),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Left Arrow Control Button
          if (widget.banners.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () {
                      final prevPage = (_currentIndex - 1 + widget.banners.length) % widget.banners.length;
                      _pageController.animateToPage(
                        prevPage,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      _startSlideshowTimer();
                    },
                  ),
                ),
              ),
            ),

          // Right Arrow Control Button
          if (widget.banners.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: () {
                      final nextPage = (_currentIndex + 1) % widget.banners.length;
                      _pageController.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      _startSlideshowTimer();
                    },
                  ),
                ),
              ),
            ),

          // Slide Dot Indicators
          if (widget.banners.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (index) {
                  final isActive = _currentIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      _startSlideshowTimer();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 10,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // 6. Scroll Down Indicator (Desktop Only)
          if (isDesktop)
            Builder(
              builder: (context) {
                // Dynamically calculate opacity based on scroll position (fades out over 120 pixels of scroll)
                final opacity = (1.0 - (_scrollOffset / 120.0)).clamp(0.0, 1.0);
                if (opacity <= 0.0) return const SizedBox.shrink();

                return Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 150),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.scrollController != null && widget.scrollController!.hasClients) {
                              widget.scrollController!.animateTo(
                                heroHeight - 80,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65), // Translucent black smoke background
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white12, width: 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SCROLL TO EXPLORE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.keyboard_double_arrow_down_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                )
                                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .move(
                                  begin: const Offset(0, -3),
                                  end: const Offset(0, 3),
                                  duration: 1000.ms,
                                  curve: Curves.easeInOut,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

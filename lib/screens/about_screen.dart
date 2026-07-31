import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/footer.dart';
import '../widgets/navbar.dart';
import '../utils/seo_helper.dart';
import '../providers/supply_network_provider.dart';
import '../models/supply_state.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'About HASH ZONE | Leading Textile Manufacturer Tiruppur',
        description: 'Learn about Sree Meenakshi Textile (SMT) and HASH ZONE\'s journey since 1998 in Tiruppur, Tamil Nadu, India. Leading private label clothing factory.',
        keywords: 'About HASH ZONE, Sree Meenakshi Textile, Textile Manufacturer Tiruppur, Private Label Clothing Manufacturer India, Tiruppur, Tamil Nadu, India',
        path: '/about',
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 70 : 40, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
              ),
              child: Column(
                children: [
                  Text(
                    'ABOUT US',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 46 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SREE MEENAKSHI TEXTILE (SMT)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 2,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Main Content Area
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro Statement Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sree Meenakshi Textile (SMT)',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: isDesktop ? 34 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Engaged in the business of manufacturing and supplying complete, premium clothing solutions.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // 4 Core Pillars Graphics Section
                    Text(
                      'OUR CLOTHING SOLUTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final pillars = [
                          _PillarData(icon: Icons.spa_outlined,           title: 'COMFORTABLE', subtitle: 'Crafted with premium soft fabrics for maximum all-day wearability.'),
                          _PillarData(icon: Icons.auto_awesome_outlined,  title: 'TRENDY',       subtitle: 'Modern designs and contemporary fashion cuts across every line.'),
                          _PillarData(icon: Icons.eco_outlined,            title: 'SUSTAINABLE',  subtitle: 'Responsibly manufactured with eco-conscious clothing practices.'),
                          _PillarData(icon: Icons.sell_outlined,           title: 'AFFORDABLE',   subtitle: 'Quality products made accessible at competitive market prices.'),
                        ];

                        if (isDesktop) {
                          // Desktop: 4-column grid
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: pillars.map((p) => _pillarCard(icon: p.icon, title: p.title, subtitle: p.subtitle)).toList(),
                          );
                        } else if (constraints.maxWidth > 550) {
                          // Tablet: 2-column grid
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                            children: pillars.map((p) => _pillarCardCompact(icon: p.icon, title: p.title, subtitle: p.subtitle)).toList(),
                          );
                        } else {
                          // Mobile: compact vertical list of horizontal cards
                          return Column(
                            children: pillars
                                .map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _pillarCardCompact(icon: p.icon, title: p.title, subtitle: p.subtitle),
                                    ))
                                .toList(),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 60),

                    // Timeline / Journey Banner Graphic
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2.0),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'OUR JOURNEY SINCE 1998',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Flex(
                            direction: isDesktop ? Axis.horizontal : Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _milestoneTile(
                                year: '1998',
                                title: 'SMALL BEGINNINGS',
                                desc: 'Started in 1998 with a small setup and 2 dedicated employees.',
                              ),
                              if (isDesktop)
                                const Icon(Icons.arrow_forward, color: Colors.white38, size: 28)
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Icon(Icons.arrow_downward, color: Colors.white38, size: 28),
                                ),
                              _milestoneTile(
                                year: 'TODAY',
                                title: 'GLOBAL REACH',
                                desc: 'Providing clothing solutions to both domestic and international markets.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 3 Segments Section (Men, Women, Kids)
                    Text(
                      'CATERING TO ALL 3 SEGMENTS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We are one of the few manufacturers who cater to all three core market segments:',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _segmentCard(
                            title: 'MEN',
                            icon: Icons.man_outlined,
                            subtitle: 'Menswear & Casuals',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _segmentCard(
                            title: 'WOMEN',
                            icon: Icons.woman_outlined,
                            subtitle: 'Womenswear & Ethnic',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _segmentCard(
                            title: 'KIDS',
                            icon: Icons.child_care_outlined,
                            subtitle: 'Kidswear & Juniors',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Closing Quality Quote Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.format_quote, size: 36, color: Colors.black),
                          const SizedBox(height: 12),
                          Text(
                            '"We strive to provide quality, trendy products at affordable prices."',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: isDesktop ? 26 : 20,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                    
                    _buildSupplyNetworkSection(context, isDesktop),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _pillarCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact horizontal card for mobile/tablet — icon on left, text on right
  Widget _pillarCardCompact({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneTile({
    required String year,
    required String title,
    required String desc,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          Text(
            year,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentCard({
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF111111),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyNetworkSection(BuildContext context, bool isDesktop) {
    final provider = Provider.of<SupplyNetworkProvider>(context);
    final activeStates = provider.activeStates;

    final mapWidget = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Builder(
              builder: (context) {
                final String viewType = 'leaflet-map-${activeStates.hashCode}';
                ui_web.platformViewRegistry.registerViewFactory(
                  viewType,
                  (int viewId) {
                    final iframe = html.IFrameElement()
                      ..style.width = '100%'
                      ..style.height = '100%'
                      ..style.border = 'none'
                      ..srcdoc = _generateMapHtml(activeStates);
                    return iframe;
                  },
                );
                return HtmlElementView(viewType: viewType);
              },
            ),
          ),
        ),
      ),
    );

    final instructionWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Our Supply Network',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Click on any pin or state label to view the cities where HashZone currently provides supply services.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF444444),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          'Our Current Supply Network',
          style: GoogleFonts.cormorantGaramond(
            fontSize: isDesktop ? 34 : 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Subheading
        Text(
          'We are currently supplying garments across multiple states and cities throughout India and continue to grow our presence.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 32),

        // Map Frame / Empty state
        if (provider.isLoading)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                ),
              ),
            ),
          )
        else if (activeStates.isEmpty)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Center(
                    child: Text(
                      'Hashzone is expanding its supply network. Locations will appear here soon.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: mapWidget,
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: instructionWidget,
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              instructionWidget,
              const SizedBox(height: 24),
              mapWidget,
            ],
          ),
      ],
    );
  }

  String _generateMapHtml(List<SupplyState> activeStates) {
    final statesJson = activeStates.map((s) => {
      'state': s.state,
      'latitude': s.latitude,
      'longitude': s.longitude,
      'cities': s.cities,
    }).toList();

    final dataString = json.encode(statesJson);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    body { margin: 0; padding: 0; background: #FFFFFF; }
    #map { width: 100vw; height: 100vh; background: #FFFFFF; }
    
    .leaflet-bar { border: 1.5px solid #000 !important; box-shadow: none !important; border-radius: 6px !important; }
    .leaflet-bar a { border-bottom: 1px solid #ccc !important; color: #000 !important; }
    .leaflet-bar a:first-child { border-top-left-radius: 4px !important; border-top-right-radius: 4px !important; }
    .leaflet-bar a:last-child { border-bottom-left-radius: 4px !important; border-bottom-right-radius: 4px !important; border-bottom: none !important; }
    
    .state-label {
      background: #000000 !important;
      border: 1px solid #000000 !important;
      border-radius: 4px !important;
      color: #ffffff !important;
      font-family: 'Inter', sans-serif !important;
      font-size: 10px !important;
      font-weight: 700 !important;
      letter-spacing: 0.5px !important;
      padding: 6px 10px !important;
      white-space: nowrap !important;
      box-shadow: 0 2px 4px rgba(0,0,0,0.15) !important;
      cursor: pointer !important;
      pointer-events: auto !important;
    }
    .leaflet-tooltip-right:before {
      border-right-color: #000000 !important;
    }
    
    .leaflet-popup-content-wrapper {
      background: #ffffff;
      border: 2px solid #000000;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      font-family: 'Inter', sans-serif;
      color: #000000;
      padding: 6px;
    }
    .leaflet-popup-tip {
      background: #ffffff;
      border: 2px solid #000000;
      border-top: none;
      border-left: none;
    }
    .popup-title {
      font-weight: 800;
      font-size: 13px;
      border-bottom: 1.5px solid #000000;
      padding-bottom: 4px;
      margin-bottom: 6px;
      letter-spacing: 0.5px;
    }
    .city-list {
      margin: 0;
      padding-left: 14px;
      font-size: 12px;
      color: #333;
      line-height: 1.4;
    }
    .city-list li {
      margin-bottom: 2px;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map('map', {
      zoomControl: true,
      scrollWheelZoom: false,
      doubleClickZoom: true,
      touchZoom: true
    });

    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
      attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
      subdomains: 'abcd',
      maxZoom: 18
    }).addTo(map);

    var supplyNetwork = $dataString;

    supplyNetwork.forEach(function(item) {
      if (item.latitude && item.longitude) {
        var customIcon = L.divIcon({
          html: '<div style="width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; cursor: pointer;"><div style="background-color: #000; width: 12px; height: 12px; border-radius: 50%; border: 2.5px solid #fff; box-shadow: 0 0 5px rgba(0,0,0,0.4);"></div></div>',
          className: 'custom-pin-icon',
          iconSize: [24, 24],
          iconAnchor: [12, 12]
        });

        var marker = L.marker([item.latitude, item.longitude], { icon: customIcon }).addTo(map);

        var tooltip = marker.bindTooltip(item.state, {
          permanent: true,
          direction: 'right',
          offset: [12, 0],
          className: 'state-label',
          interactive: true
        });

        // Set click listener on tooltip label to open marker popup
        tooltip.on('click', function(e) {
          L.DomEvent.stopPropagation(e);
          marker.openPopup();
        });

        var citiesHtml = '<div style="font-size:10px; color:#777; text-transform:uppercase; font-weight:700; letter-spacing:1px; margin-bottom:2px;">HashZone Supplies Here</div>';
        citiesHtml += '<div class="popup-title" style="margin-bottom:6px;">📍 ' + item.state.toUpperCase() + '</div>';
        if (item.cities && item.cities.length > 0) {
          citiesHtml += '<div style="font-size:9px; color:#888; margin-top:6px; margin-bottom:4px; font-weight:bold; letter-spacing:0.5px;">CURRENTLY SUPPLYING IN:</div>';
          citiesHtml += '<ul class="city-list" style="margin: 0; padding-left: 12px;">';
          item.cities.forEach(function(city) {
            citiesHtml += '<li>' + city + '</li>';
          });
          citiesHtml += '</ul>';
        }

        marker.bindPopup(citiesHtml);
      }
    });

    // Tight focus on Indian mainland (covers 8.0N to 35.8N, 68.5E to 97.3E) with minimal surround visible
    var indiaBounds = [
      [8.0, 68.5],
      [35.8, 97.3]
    ];
    map.fitBounds(indiaBounds, { padding: [5, 5] });
    setTimeout(function() {
      var currentZoom = map.getZoom();
      map.setZoom(currentZoom + 1);
      
      // Shift initial center very slightly to the left (-4.0 degrees West)
      var newCenter = map.getCenter();
      map.setView([newCenter.lat, newCenter.lng - 4.0], currentZoom + 1);
    }, 50);
  </script>
</body>
</html>
''';
  }
}

/// Simple data holder for pillar card content
class _PillarData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PillarData({required this.icon, required this.title, required this.subtitle});
}

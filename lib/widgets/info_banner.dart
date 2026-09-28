import 'package:flutter/material.dart';

class InfoBannerSection extends StatefulWidget {
  const InfoBannerSection({super.key});

  @override
  State<InfoBannerSection> createState() => _InfoBannerSectionState();
}

class _InfoBannerSectionState extends State<InfoBannerSection> {
  int _currentBannerIndex = 0;
  final PageController _bannerPageController = PageController();

  final List<Map<String, dynamic>> _bannerList = [
    {
      'title': 'Tips Menggaet Pelanggan!',
      'desc': 'Berikan pelayanan ramah dan tepat waktu untuk mempertahankan rating bintang 5 Anda.',
      'icon': Icons.stars_rounded,
      'color': const Color(0xFFFFCB05),
    },
    {
      'title': 'Bonus Insentif Mingguan',
      'desc': 'Selesaikan minimal 15 pekerjaan minggu ini dan dapatkan bonus saldo tambahan.',
      'icon': Icons.card_giftcard_rounded,
      'color': const Color(0xFFFF9800),
    },
    {
      'title': 'Jaga Keselamatan Kerja',
      'desc': 'Selalu utamakan standar keselamatan dan protokol kerja saat bertugas di lapangan.',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF2196F3),
    },
  ];

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Mitra',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: _bannerList.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = _bannerList[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerList.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? const Color(0xFFFFCB05)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
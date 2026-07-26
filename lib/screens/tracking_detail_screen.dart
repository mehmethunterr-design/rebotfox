import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';
import '../widgets/common.dart';

class TrackingDetailScreen extends StatelessWidget {
  const TrackingDetailScreen({
    super.key,
    required this.repair,
    this.createdNow = false,
  });

  final Repair repair;
  final bool createdNow;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Repair?>(
      stream: RepairRepository.instance.watchRepair(
        repair.trackingCode,
      ),
      initialData: repair,
      builder: (context, snapshot) {
        final currentRepair = snapshot.data ?? repair;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              createdNow ? 'Talep Oluşturuldu' : 'Servis Takibi',
            ),
          ),
          body: PageFrame(
            maxWidth: 820,
            child: ListView(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 32,
              ),
              children: [
                if (createdNow)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Talebiniz başarıyla oluşturuldu. Takip kodunuzu kaydedin.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (createdNow) const SizedBox(height: 16),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Canlı güncelleme alınamadı: ${snapshot.error}',
                      style: const TextStyle(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                _RepairContent(repair: currentRepair),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RepairContent extends StatelessWidget {
  const _RepairContent({
    required this.repair,
  });

  final Repair repair;

  String get price {
    final formatted = repair.estimatedPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return '$formatted ₺';
  }

  double get progressValue {
    final currentIndex = RepairStatus.values.indexOf(repair.status);
    return (currentIndex + 1) / RepairStatus.values.length;
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  String get updatedAtText {
    final date = repair.updatedAt;

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Takip Kodu',
                            style: TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SelectableText(
                            repair.trackingCode,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Takip kodunu kopyala',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: repair.trackingCode,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Takip kodu kopyalandı.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StatusChip(status: repair.status),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '%$progressPercent tamamlandı',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),
                _DetailRow(
                  'Cihaz',
                  '${repair.brand} ${repair.model}',
                ),
                _DetailRow(
                  'İşlem',
                  repair.repairType,
                ),
                _DetailRow(
                  'Tahmini Fiyat',
                  repair.estimatedPrice > 0 ? price : 'İnceleme sonrası',
                ),
                _DetailRow(
                  'Müşteri',
                  repair.customerName,
                ),
                _DetailRow(
                  'Son Güncelleme',
                  updatedAtText,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle(
          'Servis Süreci',
          subtitle: 'Cihazınızın geçtiği aşamaları buradan izleyebilirsiniz.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: RepairStatus.values.map((status) {
                final currentIndex = RepairStatus.values.indexOf(repair.status);
                final statusIndex = RepairStatus.values.indexOf(status);
                final done = statusIndex <= currentIndex;

                return _Timeline(
                  status: status,
                  done: done,
                  current: status == repair.status,
                  last: statusIndex == RepairStatus.values.length - 1,
                );
              }).toList(),
            ),
          ),
        ),
        if (repair.beforePhotoUrls.isNotEmpty ||
            repair.afterPhotoUrls.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle(
            'Servis Fotoğrafları',
            subtitle: 'Tamir öncesi ve sonrası görselleri',
          ),
          const SizedBox(height: 14),
          _ReadOnlyPhotoSection(
            title: 'Tamir Öncesi',
            photoUrls: repair.beforePhotoUrls,
          ),
          const SizedBox(height: 14),
          _ReadOnlyPhotoSection(
            title: 'Tamir Sonrası',
            photoUrls: repair.afterPhotoUrls,
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
    this.label,
    this.value,
  );

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyPhotoSection extends StatelessWidget {
  const _ReadOnlyPhotoSection({
    required this.title,
    required this.photoUrls,
  });

  final String title;
  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (photoUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: const Text(
              'Fotoğraf bulunamadı.',
              style: TextStyle(
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              final photoUrl = photoUrls[index];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PhotoPreviewScreen(
                        photoUrl: photoUrl,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: photoUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: AppColors.surface,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PhotoPreviewScreen extends StatelessWidget {
  const _PhotoPreviewScreen({
    required this.photoUrl,
  });

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: photoUrl,
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (
              context,
              child,
              loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.status,
    required this.done,
    required this.current,
    required this.last,
  });

  final RepairStatus status;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: done ? status.color : AppColors.surfaceSoft,
              child: Icon(
                status.icon,
                color: done ? AppColors.background : AppColors.textMuted,
                size: 18,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 48,
                color: done
                    ? status.color.withValues(alpha: .45)
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: done ? AppColors.text : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (current)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Mevcut durum',
                          style: TextStyle(
                            color: status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  current
                      ? 'Cihazınız şu anda bu aşamadadır.'
                      : done
                          ? 'Bu aşama tamamlandı.'
                          : 'Henüz bu aşamaya geçilmedi.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

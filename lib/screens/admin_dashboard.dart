import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';
import '../widgets/common.dart';
import 'tracking_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  RepairStatus? selectedStatus;
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Repair>>(
        stream: RepairRepository.instance.watchRepairs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Servis kayıtları alınamadı.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          final allRepairs = snapshot.data ?? <Repair>[];
          final repairs = _applyFilters(allRepairs);

          return PageFrame(
            child: ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 32),
              children: [
                const RebotfoxLogo(compact: true),
                const SizedBox(height: 24),
                const Text(
                  'Rebotfox Yönetim Paneli',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Servis operasyonunu Firestore üzerinden canlı yönetin.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                _StatsGrid(repairs: allRepairs),
                const SizedBox(height: 26),
                _Filters(
                  selectedStatus: selectedStatus,
                  onStatusChanged: (value) {
                    setState(() => selectedStatus = value);
                  },
                  onSearchChanged: (value) {
                    setState(() => searchText = value);
                  },
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  'Servis Kayıtları',
                  subtitle: repairs.isEmpty
                      ? 'Filtreyle eşleşen kayıt bulunamadı.'
                      : '${repairs.length} kayıt görüntüleniyor.',
                ),
                const SizedBox(height: 14),
                if (repairs.isEmpty)
                  const _EmptyState()
                else
                  ...repairs.map(
                    (repair) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RepairCard(repair: repair),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Repair> _applyFilters(List<Repair> repairs) {
    final query = searchText.trim().toLowerCase();

    return repairs.where((repair) {
      final matchesStatus =
          selectedStatus == null || repair.status == selectedStatus;

      final searchable = [
        repair.customerName,
        repair.phone,
        repair.trackingCode,
        repair.brand,
        repair.model,
        repair.repairType,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.repairs});

  final List<Repair> repairs;

  @override
  Widget build(BuildContext context) {
    final activeCount = repairs
        .where(
          (repair) =>
              repair.status != RepairStatus.delivered &&
              repair.status != RepairStatus.ready,
        )
        .length;

    final readyCount = repairs
        .where((repair) => repair.status == RepairStatus.ready)
        .length;

    final estimatedRevenue = repairs.fold<double>(
      0,
      (sum, repair) => sum + repair.estimatedPrice,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 2.8 : 1.7,
          children: [
            _Stat(
              'Toplam Kayıt',
              '${repairs.length}',
              Icons.receipt_long_rounded,
              AppColors.info,
            ),
            _Stat(
              'Aktif Servis',
              '$activeCount',
              Icons.build_rounded,
              AppColors.primary,
            ),
            _Stat(
              'Teslime Hazır',
              '$readyCount',
              Icons.verified_rounded,
              AppColors.warning,
            ),
            _Stat(
              'Tahmini Ciro',
              _formatPrice(estimatedRevenue),
              Icons.payments_rounded,
              AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  static String _formatPrice(double value) {
    final text = value.toStringAsFixed(0);
    final formatted = text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted ₺';
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final RepairStatus? selectedStatus;
  final ValueChanged<RepairStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 650;

        final search = TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'Kayıt ara',
            hintText: 'Müşteri, telefon, cihaz veya takip kodu',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        );

        final status = DropdownButtonFormField<RepairStatus?>(
          initialValue: selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Durum filtresi',
            prefixIcon: Icon(Icons.filter_alt_outlined),
          ),
          items: [
            const DropdownMenuItem<RepairStatus?>(
              value: null,
              child: Text('Tüm durumlar'),
            ),
            ...RepairStatus.values.map(
              (item) => DropdownMenuItem<RepairStatus?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: onStatusChanged,
        );

        if (wide) {
          return Row(
            children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: 12),
              Expanded(child: status),
            ],
          );
        }

        return Column(
          children: [
            search,
            const SizedBox(height: 12),
            status,
          ],
        );
      },
    );
  }
}

class _RepairCard extends StatefulWidget {
  const _RepairCard({required this.repair});

  final Repair repair;

  @override
  State<_RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<_RepairCard> {
  bool updating = false;

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TrackingDetailScreen(repair: repair),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${repair.brand} ${repair.model}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    repair.repairType,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${repair.customerName} • ${repair.phone}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SelectableText(
                    repair.trackingCode,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusChip(status: repair.status),
                ],
              );

              final statusButton = PopupMenuButton<RepairStatus>(
                enabled: !updating,
                tooltip: 'Durumu değiştir',
                onSelected: _updateStatus,
                itemBuilder: (_) => RepairStatus.values
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(
                              status.icon,
                              color: status.color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(status.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: updating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.more_vert_rounded),
                      ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusAvatar(status: repair.status),
                        const Spacer(),
                        statusButton,
                      ],
                    ),
                    const SizedBox(height: 12),
                    details,
                  ],
                );
              }

              return Row(
                children: [
                  _StatusAvatar(status: repair.status),
                  const SizedBox(width: 14),
                  Expanded(child: details),
                  statusButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(RepairStatus status) async {
    if (status == widget.repair.status) {
      return;
    }

    setState(() => updating = true);

    try {
      await RepairRepository.instance.updateStatus(
        widget.repair.trackingCode,
        status,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.repair.trackingCode} durumu “${status.label}” olarak güncellendi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => updating = false);
      }
    }
  }
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({required this.status});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: status.color.withValues(alpha: .12),
      child: Icon(status.icon, color: status.color),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 42,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Kayıt bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Arama metnini veya durum filtresini değiştirin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
    this.title,
    this.value,
    this.icon,
    this.color,
  );

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

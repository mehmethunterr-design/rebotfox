import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';
import '../services/whatsapp_service.dart';
import '../widgets/common.dart';
import 'repair_pdf_preview_screen.dart';
import 'repair_photos_screen.dart';
import 'tracking_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _searchController = TextEditingController();

  RepairStatus? selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        actions: [
          IconButton(
            tooltip: 'Filtreleri temizle',
            onPressed: _filtersActive ? _clearFilters : null,
            icon: const Icon(Icons.filter_alt_off_rounded),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<Repair>>(
        stream: RepairRepository.instance.watchRepairs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _DashboardError(
              error: snapshot.error,
              onRetry: () {
                setState(() {});
              },
            );
          }

          final allRepairs = snapshot.data ?? <Repair>[];
          final filteredRepairs = _applyFilters(allRepairs);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});

              await Future<void>.delayed(
                const Duration(milliseconds: 400),
              );
            },
            child: PageFrame(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 40,
                ),
                children: [
                  const _DashboardHeader(),
                  const SizedBox(height: 24),
                  _StatsGrid(
                    repairs: allRepairs,
                    onStatusSelected: (status) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  _Filters(
                    searchController: _searchController,
                    selectedStatus: selectedStatus,
                    onSearchChanged: (_) {
                      setState(() {});
                    },
                    onStatusChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 26),
                  SectionTitle(
                    'Servis Kayıtları',
                    subtitle: _recordsSubtitle(
                      allRepairs: allRepairs,
                      filteredRepairs: filteredRepairs,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filteredRepairs.isEmpty)
                    _EmptyState(
                      filtersActive: _filtersActive,
                      onClearFilters: _clearFilters,
                    )
                  else
                    ...filteredRepairs.map(
                      (repair) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RepairCard(
                          key: ValueKey(repair.trackingCode),
                          repair: repair,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _filtersActive {
    return selectedStatus != null || _searchController.text.trim().isNotEmpty;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      selectedStatus = null;
    });
  }

  String _recordsSubtitle({
    required List<Repair> allRepairs,
    required List<Repair> filteredRepairs,
  }) {
    if (allRepairs.isEmpty) {
      return 'Henüz servis kaydı bulunmuyor.';
    }

    if (!_filtersActive) {
      return '${allRepairs.length} servis kaydı görüntüleniyor.';
    }

    return '${filteredRepairs.length} kayıt bulundu. '
        'Toplam ${allRepairs.length} kayıt var.';
  }

  List<Repair> _applyFilters(List<Repair> repairs) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = repairs.where((repair) {
      final matchesStatus =
          selectedStatus == null || repair.status == selectedStatus;

      final searchableText = [
        repair.customerName,
        repair.phone,
        repair.trackingCode,
        repair.brand,
        repair.model,
        repair.repairType,
        repair.problem,
        repair.status.label,
        repair.paymentStatus.label,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort(
      (first, second) => second.updatedAt.compareTo(first.updatedAt),
    );

    return filtered;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final information = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rebotfox Yönetim Paneli',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Servis kayıtlarını, cihaz durumlarını, tahsilatları ve '
              'müşteri bildirimlerini tek ekrandan yönetin.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Text(
                  _formatLongDate(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RebotfoxLogo(compact: true),
              const SizedBox(height: 20),
              information,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const RebotfoxLogo(compact: true),
            const SizedBox(width: 24),
            Expanded(child: information),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.repairs,
    required this.onStatusSelected,
  });

  final List<Repair> repairs;
  final ValueChanged<RepairStatus?> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = now.month == 12
        ? DateTime(now.year + 1)
        : DateTime(now.year, now.month + 1);

    final todayRepairs = repairs.where((repair) {
      return !repair.createdAt.isBefore(todayStart) &&
          repair.createdAt.isBefore(tomorrowStart);
    }).toList();

    final allPayments =
        repairs.expand((repair) => repair.payments).toList(growable: false);

    final todayCollected = allPayments
        .where(
          (payment) =>
              !payment.paidAt.isBefore(todayStart) &&
              payment.paidAt.isBefore(tomorrowStart),
        )
        .fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );

    final monthCollected = allPayments
        .where(
          (payment) =>
              !payment.paidAt.isBefore(monthStart) &&
              payment.paidAt.isBefore(nextMonthStart),
        )
        .fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );

    final outstandingAmount = repairs.fold<double>(
      0,
      (sum, repair) => sum + repair.remainingAmount,
    );

    final paymentWaitingCount = repairs.where((repair) {
      return repair.estimatedPrice > 0 &&
          repair.paymentStatus != PaymentStatus.paid;
    }).length;

    final activeCount = repairs.where((repair) {
      return repair.status != RepairStatus.ready &&
          repair.status != RepairStatus.delivered;
    }).length;

    final repairingCount = repairs.where((repair) {
      return repair.status == RepairStatus.repairing;
    }).length;

    final waitingPartCount = repairs.where((repair) {
      return repair.status == RepairStatus.waitingPart;
    }).length;

    final readyCount = repairs.where((repair) {
      return repair.status == RepairStatus.ready;
    }).length;

    final deliveredCount = repairs.where((repair) {
      return repair.status == RepairStatus.delivered;
    }).length;

    final stats = <_StatData>[
      _StatData(
        title: 'Bugün Gelen',
        value: '${todayRepairs.length}',
        icon: Icons.today_rounded,
        color: AppColors.info,
      ),
      _StatData(
        title: 'Aktif Servis',
        value: '$activeCount',
        icon: Icons.build_circle_outlined,
        color: AppColors.primary,
      ),
      _StatData(
        title: 'Tamirde',
        value: '$repairingCount',
        icon: Icons.home_repair_service_rounded,
        color: AppColors.primary,
        onTap: () {
          onStatusSelected(RepairStatus.repairing);
        },
      ),
      _StatData(
        title: 'Parça Bekliyor',
        value: '$waitingPartCount',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFB779FF),
        onTap: () {
          onStatusSelected(RepairStatus.waitingPart);
        },
      ),
      _StatData(
        title: 'Teslime Hazır',
        value: '$readyCount',
        icon: Icons.verified_rounded,
        color: AppColors.warning,
        onTap: () {
          onStatusSelected(RepairStatus.ready);
        },
      ),
      _StatData(
        title: 'Teslim Edildi',
        value: '$deliveredCount',
        icon: Icons.done_all_rounded,
        color: AppColors.primaryDark,
        onTap: () {
          onStatusSelected(RepairStatus.delivered);
        },
      ),
      _StatData(
        title: 'Bugün Tahsilat',
        value: _formatPrice(todayCollected),
        icon: Icons.point_of_sale_rounded,
        color: AppColors.info,
      ),
      _StatData(
        title: 'Bu Ay Tahsilat',
        value: _formatPrice(monthCollected),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      _StatData(
        title: 'Bekleyen Alacak',
        value: _formatPrice(outstandingAmount),
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
      ),
      _StatData(
        title: 'Ödeme Bekleyen',
        value: '$paymentWaitingCount',
        icon: Icons.money_off_csred_outlined,
        color: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1100
            ? 4
            : width >= 720
                ? 3
                : width >= 480
                    ? 2
                    : 1;

        final aspectRatio = columns == 1
            ? 2.8
            : columns == 2
                ? 1.65
                : 1.55;

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _StatCard(data: stats[index]);
          },
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.data,
  });

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        data.value,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final RepairStatus? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<RepairStatus?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final filtersActive =
        selectedStatus != null || searchController.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 700;

            final searchField = TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Kayıt ara',
                hintText: 'Müşteri, telefon, cihaz veya takip kodu',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            );

            final statusField = DropdownButtonFormField<RepairStatus?>(
              key: ValueKey<RepairStatus?>(selectedStatus),
              initialValue: selectedStatus,
              isExpanded: true,
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
                  (status) => DropdownMenuItem<RepairStatus?>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          status.icon,
                          size: 18,
                          color: status.color,
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            status.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: onStatusChanged,
            );

            final clearButton = OutlinedButton.icon(
              onPressed: filtersActive ? onClear : null,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Temizle'),
            );

            if (wide) {
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: searchField,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: statusField,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: clearButton,
                  ),
                ],
              );
            }

            return Column(
              children: [
                searchField,
                const SizedBox(height: 12),
                statusField,
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: clearButton,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RepairCard extends StatefulWidget {
  const _RepairCard({
    required this.repair,
    super.key,
  });

  final Repair repair;

  @override
  State<_RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<_RepairCard> {
  bool updatingStatus = false;
  bool recordingPayment = false;

  double get progressValue {
    final statuses = RepairStatus.values;

    if (statuses.length <= 1) {
      return 1;
    }

    final index = statuses.indexOf(widget.repair.status);

    if (index < 0) {
      return 0;
    }

    return (index + 1) / statuses.length;
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openTrackingDetails(repair);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;

              if (compact) {
                return _buildCompactLayout(repair);
              }

              return _buildWideLayout(repair);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(Repair repair) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusAvatar(status: repair.status),
            const SizedBox(width: 12),
            Expanded(
              child: _DeviceTitle(repair: repair),
            ),
            _statusMenu(),
          ],
        ),
        const SizedBox(height: 16),
        _RepairInformation(repair: repair),
        if (repair.problem.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProblemBox(problem: repair.problem),
        ],
        const SizedBox(height: 15),
        _ProgressArea(
          status: repair.status,
          value: progressValue,
          percent: progressPercent,
        ),
        const SizedBox(height: 15),
        _PaymentSummary(repair: repair),
        const SizedBox(height: 16),
        _QuickActions(
          busy: updatingStatus || recordingPayment,
          paymentCompleted: repair.paymentStatus == PaymentStatus.paid,
          paymentReceiptAvailable: repair.payments.isNotEmpty,
          onCall: _callCustomer,
          onWhatsApp: () {
            _openWhatsAppPreview();
          },
          onPayment: _openPaymentDialog,
          onPaymentHistory: _showPaymentHistory,
          onServiceReceipt: () {
            _openPdfPreview(
              RepairDocumentType.serviceReceipt,
            );
          },
          onPaymentReceipt: () {
            _openPdfPreview(
              RepairDocumentType.paymentReceipt,
            );
          },
          onPhotos: () {
            _openPhotoManager(repair);
          },
          onTracking: () {
            _openTrackingDetails(repair);
          },
        ),
      ],
    );
  }

  Widget _buildWideLayout(Repair repair) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusAvatar(status: repair.status),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceTitle(repair: repair),
              const SizedBox(height: 11),
              _RepairInformation(repair: repair),
              if (repair.problem.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _ProblemBox(problem: repair.problem),
              ],
              const SizedBox(height: 15),
              _ProgressArea(
                status: repair.status,
                value: progressValue,
                percent: progressPercent,
              ),
              const SizedBox(height: 15),
              _PaymentSummary(repair: repair),
              const SizedBox(height: 16),
              _QuickActions(
                busy: updatingStatus || recordingPayment,
                paymentCompleted: repair.paymentStatus == PaymentStatus.paid,
                paymentReceiptAvailable: repair.payments.isNotEmpty,
                onCall: _callCustomer,
                onWhatsApp: () {
                  _openWhatsAppPreview();
                },
                onPayment: _openPaymentDialog,
                onPaymentHistory: _showPaymentHistory,
                onServiceReceipt: () {
                  _openPdfPreview(
                    RepairDocumentType.serviceReceipt,
                  );
                },
                onPaymentReceipt: () {
                  _openPdfPreview(
                    RepairDocumentType.paymentReceipt,
                  );
                },
                onPhotos: () {
                  _openPhotoManager(repair);
                },
                onTracking: () {
                  _openTrackingDetails(repair);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusMenu(),
      ],
    );
  }

  Widget _statusMenu() {
    return PopupMenuButton<RepairStatus>(
      enabled: !updatingStatus && !recordingPayment,
      tooltip: 'Durumu değiştir',
      onSelected: _updateStatus,
      itemBuilder: (_) {
        return RepairStatus.values.map((status) {
          final selected = status == widget.repair.status;

          return PopupMenuItem<RepairStatus>(
            value: status,
            child: Row(
              children: [
                Icon(
                  status.icon,
                  color: status.color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(status.label),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 19,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: updatingStatus || recordingPayment
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          : const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.more_vert_rounded),
            ),
    );
  }

  Future<void> _openPaymentDialog() async {
    final remaining = widget.repair.remainingAmount;

    if (remaining <= 0.01) {
      _showMessage('Bu servis kaydının ödemesi tamamlanmış.');
      return;
    }

    final result = await showDialog<_PaymentDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _PaymentDialog(repair: widget.repair);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      recordingPayment = true;
    });

    try {
      await RepairRepository.instance.recordPayment(
        trackingCode: widget.repair.trackingCode,
        amount: result.amount,
        method: result.method,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${_formatPrice(result.amount)} ödeme kaydedildi.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Ödeme kaydedilemedi: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          recordingPayment = false;
        });
      }
    }
  }

  Future<void> _showPaymentHistory() async {
    final payments = [...widget.repair.payments]..sort(
        (first, second) => second.paidAt.compareTo(first.paidAt),
      );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text('Ödeme Geçmişi'),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: payments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.money_off_csred_outlined,
                          size: 42,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Henüz ödeme kaydı bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 430,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final payment = payments[index];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5,
                          ),
                          leading: CircleAvatar(
                            child: Icon(
                              payment.method.icon,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _formatPrice(payment.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            '${payment.method.label} • '
                            '${_formatDateTime(payment.paidAt)}',
                          ),
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _openPdfPreview(
    RepairDocumentType documentType,
  ) {
    if (documentType == RepairDocumentType.paymentReceipt &&
        widget.repair.payments.isEmpty) {
      _showMessage(
        'Ödeme makbuzu için önce bir ödeme kaydı oluşturun.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepairPdfPreviewScreen(
          repair: widget.repair,
          documentType: documentType,
        ),
      ),
    );
  }

  Future<void> _callCustomer() async {
    final phone = widget.repair.phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (phone.isEmpty) {
      _showMessage(
        'Müşterinin telefon numarası bulunamadı.',
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Telefon uygulaması açılamadı.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Arama başlatılamadı: $error');
      }
    }
  }

  Future<void> _openWhatsAppPreview({
    RepairStatus? status,
  }) async {
    final controller = TextEditingController(
      text: WhatsAppService.messageFor(
        widget.repair,
        status: status,
      ),
    );

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.chat_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text('WhatsApp mesajı'),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 11,
              decoration: const InputDecoration(
                labelText: 'Müşteriye gönderilecek mesaj',
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text("WhatsApp'ta Aç"),
            ),
          ],
        );
      },
    );

    final message = controller.text.trim();
    controller.dispose();

    if (shouldOpen != true || message.isEmpty || !mounted) {
      return;
    }

    final opened = await WhatsAppService.open(
      phone: widget.repair.phone,
      message: message,
    );

    if (!mounted) {
      return;
    }

    if (!opened) {
      _showMessage(
        'WhatsApp açılamadı. Telefon numarasını ve '
        'WhatsApp kurulumunu kontrol edin.',
      );
    }
  }

  Future<void> _offerReadyNotification() async {
    final sendNotification = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Müşteriyi bilgilendir'),
          content: Text(
            '${widget.repair.customerName} isimli müşteriye '
            'cihazın teslime hazır olduğunu WhatsApp üzerinden '
            'bildirmek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Şimdi değil'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Mesajı hazırla'),
            ),
          ],
        );
      },
    );

    if (sendNotification == true && mounted) {
      await _openWhatsAppPreview(
        status: RepairStatus.ready,
      );
    }
  }

  Future<void> _updateStatus(RepairStatus status) async {
    if (status == widget.repair.status || updatingStatus || recordingPayment) {
      return;
    }

    setState(() {
      updatingStatus = true;
    });

    try {
      await RepairRepository.instance.updateStatus(
        widget.repair.trackingCode,
        status,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${widget.repair.trackingCode} numaralı kaydın '
        'durumu “${status.label}” olarak güncellendi.',
      );

      if (status == RepairStatus.ready && mounted) {
        await _offerReadyNotification();
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Durum güncellenemedi: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          updatingStatus = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _openPhotoManager(Repair repair) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepairPhotosScreen(
          trackingCode: repair.trackingCode,
          readOnly: false,
        ),
      ),
    );
  }

  void _openTrackingDetails(Repair repair) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingDetailScreen(
          repair: repair,
        ),
      ),
    );
  }
}

class _PaymentDialogResult {
  const _PaymentDialogResult({
    required this.amount,
    required this.method,
  });

  final double amount;
  final PaymentMethod method;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.repair,
  });

  final Repair repair;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amountController;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String? _amountError;

  double get _remaining => widget.repair.remainingAmount;

  @override
  void initState() {
    super.initState();

    final remaining = _remaining;
    _amountController = TextEditingController(
      text: remaining.toStringAsFixed(
        remaining.truncateToDouble() == remaining ? 0 : 2,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.point_of_sale_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text('Ödeme Al'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogAmountRow(
                label: 'Toplam ücret',
                value: _formatPrice(
                  widget.repair.estimatedPrice,
                ),
              ),
              const SizedBox(height: 7),
              _DialogAmountRow(
                label: 'Daha önce ödenen',
                value: _formatPrice(
                  widget.repair.paidAmount,
                ),
              ),
              const SizedBox(height: 7),
              _DialogAmountRow(
                label: 'Kalan borç',
                value: _formatPrice(_remaining),
                emphasized: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9.,]'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Alınan ödeme',
                  prefixIcon: const Icon(Icons.currency_lira_rounded),
                  hintText: 'Örnek: 1500',
                  errorText: _amountError,
                ),
                onChanged: (_) {
                  if (_amountError != null) {
                    setState(() {
                      _amountError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Ödeme yöntemi',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem<PaymentMethod>(
                    value: method,
                    child: Row(
                      children: [
                        Icon(method.icon, size: 19),
                        const SizedBox(width: 9),
                        Text(method.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedMethod = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Ödemeyi Kaydet'),
        ),
      ],
    );
  }

  void _save() {
    final amount = _parseAmount(_amountController.text);

    String? error;

    if (amount == null || amount <= 0) {
      error = 'Geçerli bir ödeme tutarı girin.';
    } else if (amount > _remaining + 0.01) {
      error = 'Tutar kalan borçtan fazla olamaz.';
    }

    if (error != null) {
      setState(() {
        _amountError = error;
      });
      return;
    }

    Navigator.of(context).pop(
      _PaymentDialogResult(
        amount: amount!,
        method: _selectedMethod,
      ),
    );
  }
}

class _DialogAmountRow extends StatelessWidget {
  const _DialogAmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? null : AppColors.textMuted,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: emphasized ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class _DeviceTitle extends StatelessWidget {
  const _DeviceTitle({
    required this.repair,
  });

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${repair.brand} ${repair.model}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(status: repair.status),
            _PaymentStatusChip(
              status: repair.paymentStatus,
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({
    required this.status,
  });

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: status.color.withValues(alpha: .28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 15,
            color: status.color,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairInformation extends StatelessWidget {
  const _RepairInformation({
    required this.repair,
  });

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        _InformationItem(
          icon: Icons.home_repair_service_outlined,
          text: repair.repairType,
        ),
        _InformationItem(
          icon: Icons.person_outline_rounded,
          text: repair.customerName,
        ),
        _InformationItem(
          icon: Icons.phone_outlined,
          text: repair.phone,
        ),
        _InformationItem(
          icon: Icons.qr_code_rounded,
          text: repair.trackingCode,
          selectable: true,
        ),
        _InformationItem(
          icon: Icons.calendar_today_outlined,
          text: 'Giriş: ${_formatDateTime(repair.createdAt)}',
        ),
        _InformationItem(
          icon: Icons.update_rounded,
          text: 'Güncelleme: ${_formatDateTime(repair.updatedAt)}',
        ),
      ],
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.icon,
    required this.text,
    this.selectable = false,
  });

  final IconData icon;
  final String text;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: selectable
              ? SelectableText(
                  text,
                  style: textStyle,
                )
              : Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
        ),
      ],
    );
  }
}

class _ProblemBox extends StatelessWidget {
  const _ProblemBox({
    required this.problem,
  });

  final String problem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.report_problem_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              problem,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArea extends StatelessWidget {
  const _ProgressArea({
    required this.status,
    required this.value,
    required this.percent,
  });

  final RepairStatus status;
  final double value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Servis ilerlemesi',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '%$percent',
              style: TextStyle(
                color: status.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: safeValue,
            minHeight: 8,
            color: status.color,
            backgroundColor: status.color.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.repair,
  });

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final status = repair.paymentStatus;
    final latestPayment = repair.latestPayment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.color.withValues(alpha: .18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                status.icon,
                color: status.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ödeme durumu',
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _PaymentAmount(
                label: 'Toplam ücret',
                value: _formatPrice(repair.estimatedPrice),
              ),
              _PaymentAmount(
                label: 'Tahsil edilen',
                value: _formatPrice(repair.paidAmount),
              ),
              _PaymentAmount(
                label: 'Kalan',
                value: _formatPrice(repair.remainingAmount),
                emphasized: repair.remainingAmount > 0.01,
              ),
            ],
          ),
          if (latestPayment != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  latestPayment.method.icon,
                  size: 17,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Son ödeme: '
                    '${_formatPrice(latestPayment.amount)} • '
                    '${latestPayment.method.label} • '
                    '${_formatDateTime(latestPayment.paidAt)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentAmount extends StatelessWidget {
  const _PaymentAmount({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: emphasized ? AppColors.warning : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.busy,
    required this.paymentCompleted,
    required this.paymentReceiptAvailable,
    required this.onCall,
    required this.onWhatsApp,
    required this.onPayment,
    required this.onPaymentHistory,
    required this.onServiceReceipt,
    required this.onPaymentReceipt,
    required this.onPhotos,
    required this.onTracking,
  });

  final bool busy;
  final bool paymentCompleted;
  final bool paymentReceiptAvailable;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onPayment;
  final VoidCallback onPaymentHistory;
  final VoidCallback onServiceReceipt;
  final VoidCallback onPaymentReceipt;
  final VoidCallback onPhotos;
  final VoidCallback onTracking;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: busy ? null : onCall,
          icon: const Icon(
            Icons.phone_outlined,
            size: 18,
          ),
          label: const Text('Ara'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onWhatsApp,
          icon: const Icon(
            Icons.chat_rounded,
            size: 18,
          ),
          label: const Text('WhatsApp'),
        ),
        FilledButton.icon(
          onPressed: busy || paymentCompleted ? null : onPayment,
          icon: Icon(
            paymentCompleted
                ? Icons.check_circle_rounded
                : Icons.point_of_sale_rounded,
            size: 18,
          ),
          label: Text(
            paymentCompleted ? 'Ödendi' : 'Ödeme Al',
          ),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onPaymentHistory,
          icon: const Icon(
            Icons.receipt_long_outlined,
            size: 18,
          ),
          label: const Text('Ödemeler'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onServiceReceipt,
          icon: const Icon(
            Icons.description_outlined,
            size: 18,
          ),
          label: const Text('Servis Fişi'),
        ),
        OutlinedButton.icon(
          onPressed: busy || !paymentReceiptAvailable ? null : onPaymentReceipt,
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 18,
          ),
          label: const Text('Makbuz'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onPhotos,
          icon: const Icon(
            Icons.photo_library_outlined,
            size: 18,
          ),
          label: const Text('Fotoğraflar'),
        ),
        FilledButton.tonalIcon(
          onPressed: busy ? null : onTracking,
          icon: const Icon(
            Icons.open_in_new_rounded,
            size: 18,
          ),
          label: const Text('Takip Detayı'),
        ),
      ],
    );
  }
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({
    required this.status,
  });

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        status.icon,
        color: status.color,
        size: 27,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filtersActive,
    required this.onClearFilters,
  });

  final bool filtersActive;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 44,
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 38,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtersActive
                  ? 'Filtreyle eşleşen kayıt bulunamadı'
                  : 'Henüz servis kaydı bulunmuyor',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              filtersActive
                  ? 'Arama metnini veya durum filtresini değiştirin.'
                  : 'Yeni servis kaydı oluşturulduğunda burada görünecek.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            if (filtersActive) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(
                  Icons.filter_alt_off_rounded,
                ),
                label: const Text('Filtreleri temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 54,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Servis kayıtları alınamadı',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double? _parseAmount(String value) {
  var normalized = value.trim().replaceAll('₺', '').replaceAll(' ', '');

  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

String _formatPrice(double value) {
  final hasDecimals = value.truncateToDouble() != value;

  final raw = value.toStringAsFixed(hasDecimals ? 2 : 0);
  final parts = raw.split('.');

  final formattedWhole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  if (parts.length == 1) {
    return '$formattedWhole ₺';
  }

  return '$formattedWhole,${parts[1]} ₺';
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.${date.year} $hour:$minute';
}

String _formatLongDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  const weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];

  return '${date.day} $month ${date.year}, $weekday';
}

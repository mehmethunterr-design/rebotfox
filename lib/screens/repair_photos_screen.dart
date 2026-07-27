import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../data/repair_repository.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class RepairPhotosScreen extends StatefulWidget {
  const RepairPhotosScreen({
    super.key,
    required this.trackingCode,
    required this.readOnly,
  });

  final String trackingCode;
  final bool readOnly;

  @override
  State<RepairPhotosScreen> createState() => _RepairPhotosScreenState();
}

class _RepairPhotosScreenState extends State<RepairPhotosScreen> {
  bool uploading = false;
  double uploadProgress = 0;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _repairStream;

  @override
  void initState() {
    super.initState();
    _repairStream = RepairRepository.instance
        .watchRepairDocument(widget.trackingCode)
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraflar'),
      ),
      body: PageFrame(
        maxWidth: 820,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _repairStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Fotoğraf verisi alınamadı: ${snapshot.error}'),
              );
            }

            final data = snapshot.data?.data() ?? {};
            final beforeUrls = (data['beforePhotoUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                const [];
            final afterUrls = (data['afterPhotoUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                const [];

            return ListView(
              padding: const EdgeInsets.only(top: 18, bottom: 32),
              children: [
                const RebotfoxLogo(compact: true),
                const SizedBox(height: 24),
                const Text(
                  'Tamir Öncesi / Sonrası Fotoğrafları',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buradan servis kaydına ait görselleri yükleyebilirsiniz.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                if (!widget.readOnly) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickPhoto(RepairPhotoType.before),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Öncesi Fotoğraf Ekle'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickPhoto(RepairPhotoType.after),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Sonrası Fotoğraf Ekle'),
                        ),
                      ),
                    ],
                  ),
                  if (uploading) ...[
                    const SizedBox(height: 18),
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 6),
                    Text('${(uploadProgress * 100).toStringAsFixed(0)}% yüklendi'),
                  ],
                  const SizedBox(height: 24),
                ],
                _PhotoSection(
                  title: 'Tamir Öncesi',
                  photoUrls: beforeUrls,
                  onDelete: widget.readOnly ? null : (url) => _deletePhoto(url, RepairPhotoType.before),
                  readOnly: widget.readOnly,
                ),
                const SizedBox(height: 20),
                _PhotoSection(
                  title: 'Tamir Sonrası',
                  photoUrls: afterUrls,
                  onDelete: widget.readOnly ? null : (url) => _deletePhoto(url, RepairPhotoType.after),
                  readOnly: widget.readOnly,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickPhoto(RepairPhotoType type) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_supportsCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  defaultTargetPlatform == TargetPlatform.windows
                      ? 'Bilgisayardan seç'
                      : 'Galeriden seç',
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) {
      return;
    }

    setState(() {
      uploading = true;
      uploadProgress = 0;
    });

    try {
      final url = await StorageService.instance.uploadRepairPhoto(
        trackingCode: widget.trackingCode,
        type: type,
        file: picked,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => uploadProgress = progress);
        },
      );

      await RepairRepository.instance.addRepairPhoto(
        widget.trackingCode,
        type,
        url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${type.label} fotoğrafı yüklendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenemedi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
          uploadProgress = 0;
        });
      }
    }
  }

  bool get _supportsCamera {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _deletePhoto(String url, RepairPhotoType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fotoğraf Silinsin mi?'),
          content: const Text('Bu fotoğraf kalıcı olarak silinecektir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await StorageService.instance.deleteRepairPhoto(url);
      await RepairRepository.instance.removeRepairPhoto(
        widget.trackingCode,
        type,
        url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf silindi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf silinemedi: $error')),
      );
    }
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.title,
    required this.photoUrls,
    required this.readOnly,
    this.onDelete,
  });

  final String title;
  final List<String> photoUrls;
  final bool readOnly;
  final void Function(String url)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (photoUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Henüz fotoğraf yüklenmedi.',
              style: const TextStyle(color: AppColors.textMuted),
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PhotoPreviewScreen(photoUrl: photoUrl),
                      ),
                    ),
                    child: Hero(
                      tag: photoUrl,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surface,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textMuted),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!readOnly)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => onDelete?.call(photoUrl),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _PhotoPreviewScreen extends StatelessWidget {
  const _PhotoPreviewScreen({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
      body: Center(
        child: Hero(
          tag: photoUrl,
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/admin_cloudinary_service.dart';

class AdminCloudinaryScreen extends StatefulWidget {
  const AdminCloudinaryScreen({super.key});

  @override
  State<AdminCloudinaryScreen> createState() => _AdminCloudinaryScreenState();
}

class _AdminCloudinaryScreenState extends State<AdminCloudinaryScreen> {
  final AdminCloudinaryService cloudinaryService = AdminCloudinaryService();

  Map<String, dynamic> summary = {};

  List<Map<String, dynamic>> images = [];

  String? nextCursor;

  bool loadingSummary = true;
  bool loadingImages = true;
  bool loadingMore = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadEverything();
  }

  // ==========================================================
  // CARREGAR TUDO
  // ==========================================================

  Future<void> loadEverything() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loadingSummary = true;
      loadingImages = true;
      loadingMore = false;
      errorMessage = null;
      images = [];
      nextCursor = null;
    });

    try {
      final results = await Future.wait([
        cloudinaryService.getSummary(),
        cloudinaryService.getImages(),
      ]);

      if (!mounted) {
        return;
      }

      final summaryResult = Map<String, dynamic>.from(results[0] as Map);

      final imagesResult = Map<String, dynamic>.from(results[1] as Map);

      final returnedImages = imagesResult['images'];

      setState(() {
        summary = summaryResult;

        images = returnedImages is List
            ? List<Map<String, dynamic>>.from(
                returnedImages.map((item) => Map<String, dynamic>.from(item)),
              )
            : [];

        nextCursor = imagesResult['nextCursor']?.toString();

        loadingSummary = false;
        loadingImages = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingSummary = false;
        loadingImages = false;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // CARREGAR MAIS
  // ==========================================================

  Future<void> loadMoreImages() async {
    if (loadingMore ||
        loadingImages ||
        nextCursor == null ||
        nextCursor!.isEmpty) {
      return;
    }

    setState(() {
      loadingMore = true;
    });

    try {
      final result = await cloudinaryService.getImages(nextCursor: nextCursor);

      if (!mounted) {
        return;
      }

      final returnedImages = result['images'];

      final newImages = returnedImages is List
          ? List<Map<String, dynamic>>.from(
              returnedImages.map((item) => Map<String, dynamic>.from(item)),
            )
          : <Map<String, dynamic>>[];

      setState(() {
        images.addAll(newImages);

        nextCursor = result['nextCursor']?.toString();

        loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ==========================================================
  // EXCLUIR
  // ==========================================================

  Future<void> confirmDelete(Map<String, dynamic> image) async {
    final used = image['used'] == true;

    if (used) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final products = image['products'] is List
              ? image['products'] as List
              : [];

          return AlertDialog(
            title: const Text('Imagem em uso'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta imagem está vinculada a um produto e não pode ser excluída.',
                  ),
                  const SizedBox(height: 16),
                  if (products.isNotEmpty) ...[
                    const Text(
                      'Produto(s) vinculado(s):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${product['name'] ?? 'Produto'}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      return;
    }

    final publicId = image['publicId']?.toString() ?? '';

    if (publicId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir imagem?'),
          content: const Text(
            'Esta ação excluirá permanentemente a imagem do Cloudinary. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await cloudinaryService.deleteImage(publicId: publicId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem excluída com sucesso.')),
      );

      await loadEverything();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ==========================================================
  // FORMATAR TAMANHO
  // ==========================================================

  String formatBytes(dynamic value) {
    final bytes = _toDouble(value);

    if (bytes <= 0) {
      return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];

    var unitIndex = 0;
    var size = bytes;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '${size.toStringAsFixed(0)} ${units[unitIndex]}';
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String formatDate(dynamic value) {
    final text = value?.toString();

    if (text == null || text.isEmpty) {
      return 'Data não informada';
    }

    final date = DateTime.tryParse(text);

    if (date == null) {
      return text;
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // ==========================================================
  // DOUBLE SEGURO
  // ==========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ==========================================================
  // CARD DE RESUMO
  // ==========================================================

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DA IMAGEM
  // ==========================================================

  Widget buildImageCard(Map<String, dynamic> image) {
    final secureUrl = image['secureUrl']?.toString() ?? '';

    final publicId = image['publicId']?.toString() ?? '';

    final format = image['format']?.toString() ?? '-';

    final bytes = image['bytes'];

    final width = image['width']?.toString() ?? '-';

    final height = image['height']?.toString() ?? '-';

    final used = image['used'] == true;

    final products = image['products'] is List ? image['products'] as List : [];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 220,
            child: secureUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 60),
                  )
                : Image.network(
                    secureUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 60,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        publicId,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: used
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        used ? 'Em uso' : 'Não vinculada',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: used
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text('Formato: ${format.toUpperCase()}'),

                const SizedBox(height: 4),

                Text('Dimensões: ${width} × ${height}px'),

                const SizedBox(height: 4),

                Text('Tamanho: ${formatBytes(bytes)}'),

                const SizedBox(height: 4),

                Text('Enviada em: ${formatDate(image['createdAt'])}'),

                if (products.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Produto vinculado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...products.map(
                    (product) => Text('• ${product['name'] ?? 'Produto'}'),
                  ),
                ],

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: used ? null : () => confirmDelete(image),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(used ? 'Imagem em uso' : 'Excluir imagem'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final storage = summary['storage'] is Map
        ? Map<String, dynamic>.from(summary['storage'])
        : <String, dynamic>{};

    final usedStorage = storage['used'];

    final storageLimit = storage['limit'];

    final availableStorage = storage['available'];

    final hasMore = nextCursor != null && nextCursor!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento do Cloudinary'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loadingSummary || loadingImages ? null : loadEverything,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadEverything,
        child: errorMessage != null && !loadingSummary && !loadingImages
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Não foi possível carregar o Cloudinary.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(errorMessage!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: loadEverything,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Resumo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  if (loadingSummary)
                    const Center(child: CircularProgressIndicator())
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        final cardWidth = isWide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: buildInfoCard(
                                icon: Icons.photo_library_outlined,
                                title: 'Imagens',
                                value:
                                    '${summary['images']?['count'] ?? images.length}',
                                subtitle: 'Recursos no Cloudinary',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: buildInfoCard(
                                icon: Icons.storage_outlined,
                                title: 'Armazenamento usado',
                                value: formatBytes(usedStorage),
                                subtitle: 'Uso atual',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: buildInfoCard(
                                icon: Icons.cloud_outlined,
                                title: 'Limite de armazenamento',
                                value:
                                    storageLimit == null ||
                                        _toDouble(storageLimit) <= 0
                                    ? 'Não informado'
                                    : formatBytes(storageLimit),
                                subtitle: 'Limite da conta',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: buildInfoCard(
                                icon: Icons.cloud_queue_outlined,
                                title: 'Espaço disponível',
                                value: availableStorage == null
                                    ? 'Não informado'
                                    : formatBytes(availableStorage),
                                subtitle: 'Espaço restante',
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Imagens dos produtos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${images.length}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Imagens da pasta ebd-v2/products',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 16),

                  if (loadingImages)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (images.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            Icon(Icons.image_not_supported_outlined, size: 50),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma imagem encontrada.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int columns = 1;

                        if (constraints.maxWidth >= 1100) {
                          columns = 3;
                        } else if (constraints.maxWidth >= 700) {
                          columns = 2;
                        }

                        if (columns == 1) {
                          return Column(
                            children: images.map(buildImageCard).toList(),
                          );
                        }

                        final rows = <Widget>[];

                        for (var i = 0; i < images.length; i += columns) {
                          final rowChildren = <Widget>[];

                          for (var j = 0; j < columns; j++) {
                            final index = i + j;

                            rowChildren.add(
                              Expanded(
                                child: index < images.length
                                    ? buildImageCard(images[index])
                                    : const SizedBox(),
                              ),
                            );

                            if (j < columns - 1) {
                              rowChildren.add(const SizedBox(width: 12));
                            }
                          }

                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: rowChildren,
                              ),
                            ),
                          );
                        }

                        return Column(children: rows);
                      },
                    ),

                  if (hasMore) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: loadingMore ? null : loadMoreImages,
                        icon: loadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          loadingMore
                              ? 'Carregando...'
                              : 'Carregar mais imagens',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Imagens marcadas como "Em uso" não podem ser excluídas pelo painel. Isso protege os produtos que ainda utilizam essas imagens.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

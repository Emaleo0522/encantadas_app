import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/pocketbase_sync_service.dart';

/// Picker de imagen para producto. Solo Web (usa input file del DOM).
///
/// Estados:
/// - Sin imagen + sin sync auth: muestra mensaje "Conecta sincronizacion"
/// - Sin imagen + sync auth: boton "Agregar foto"
/// - Subiendo: spinner
/// - Con imagen: preview + boton X para borrar
///
/// El callback `onImageChanged` recibe el nuevo `imageId` (o null si se
/// borro). El padre debe persistir ese ID en el modelo Product.
///
/// El widget se encarga de:
/// - Pickeo de archivo via input HTML
/// - Lectura como bytes
/// - Upload al backend
/// - Borrado de imagen anterior si la habia (cleanup)
class ProductImagePicker extends StatefulWidget {
  final String? initialImageId;
  final String productCode;  // Usado como ref_id para trazabilidad
  final ValueChanged<String?> onImageChanged;
  final double size;

  const ProductImagePicker({
    super.key,
    required this.initialImageId,
    required this.productCode,
    required this.onImageChanged,
    this.size = 120,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  String? _imageId;
  String? _imageUrl;
  bool _loading = false;
  bool _resolvingUrl = false;

  @override
  void initState() {
    super.initState();
    _imageId = widget.initialImageId;
    if (_imageId != null) _resolveUrl();
  }

  Future<void> _resolveUrl() async {
    setState(() => _resolvingUrl = true);
    final url = await PocketBaseSyncService.instance.getFileUrlAsync(_imageId);
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _resolvingUrl = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final sync = PocketBaseSyncService.instance;
    if (!sync.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectá la sincronización en Configuraciones para subir fotos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Crear input HTML invisible y disparar click
    final input = html.FileUploadInputElement();
    input.accept = 'image/jpeg,image/png,image/webp,image/gif';
    input.click();

    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return;
    final file = files.first;

    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen demasiado grande (máx 5 MB).'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = (reader.result as Uint8List).toList();

    setState(() => _loading = true);

    // Upload nueva
    final newId = await sync.uploadFile(
      kind: 'product_image',
      refId: widget.productCode,
      bytes: bytes,
      filename: file.name,
    );

    if (newId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la imagen.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
      return;
    }

    // Borrar la anterior (si habia)
    final oldId = _imageId;
    if (oldId != null && oldId != newId) {
      await sync.deleteFile(oldId);
    }

    if (mounted) {
      setState(() {
        _imageId = newId;
        _loading = false;
      });
    }
    widget.onImageChanged(newId);
    await _resolveUrl();
  }

  Future<void> _removeImage() async {
    final id = _imageId;
    if (id == null) return;
    setState(() => _loading = true);
    await PocketBaseSyncService.instance.deleteFile(id);
    if (mounted) {
      setState(() {
        _imageId = null;
        _imageUrl = null;
        _loading = false;
      });
    }
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto del producto (opcional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_imageId != null) {
      if (_resolvingUrl) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (_imageUrl == null) {
        return Stack(
          children: [
            const Center(
              child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
            ),
            _removeButton(),
          ],
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 32, color: Colors.grey),
          ),
          _removeButton(),
        ],
      );
    }
    return InkWell(
      onTap: _pickAndUpload,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 32, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text('Agregar', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _removeButton() {
    return Positioned(
      top: 2,
      right: 2,
      child: InkWell(
        onTap: _removeImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

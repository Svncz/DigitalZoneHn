import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerDialog extends StatefulWidget {
  const BannerDialog({super.key});

  @override
  State<BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<BannerDialog> {
  final _textController = TextEditingController();
  bool _isActive = false;
  String _selectedColor = '#6366f1'; // Default Indigo

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('banner')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _textController.text = data['text'] ?? '';
        _isActive = data['isActive'] ?? false;
        _selectedColor = data['color'] ?? '#6366f1';
      });
    }
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('config').doc('banner').set({
      'text': _textController.text,
      'isActive': _isActive,
      'color': _selectedColor,
    });
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Banner actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Anuncio Web'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Mostrar Banner'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'Texto del Anuncio'),
          ),
          const SizedBox(height: 20),
          const Text('Color de Fondo'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorBtn('#6366f1'), // Indigo
              _colorBtn('#ef4444'), // Red
              _colorBtn('#22c55e'), // Green
              _colorBtn('#eab308'), // Yellow
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  Widget _colorBtn(String color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
          shape: BoxShape.circle,
          border: _selectedColor == color
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
      ),
    );
  }
}

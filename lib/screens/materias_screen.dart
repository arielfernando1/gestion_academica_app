import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/materia.dart';
import '../services/materia_service.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  List<Materia> _materias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final list = await MateriaService.instance.getMaterias();
    if (!mounted) return;
    setState(() {
      _materias = list;
      _cargando = false;
    });
  }

  Future<void> _agregar() async {
    final nombre = await _mostrarDialogoNombre();
    if (nombre == null || nombre.trim().isEmpty) return;

    final existe = await MateriaService.instance.existeNombre(nombre);
    if (!mounted) return;

    if (existe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa materia ya existe')),
      );
      return;
    }

    await MateriaService.instance.insertMateria(nombre);
    await _cargar();
  }

  Future<void> _eliminar(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text('¿Eliminar "${materia.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && materia.id != null) {
      await MateriaService.instance.deleteMateria(materia.id!);
      await _cargar();
    }
  }

  Future<String?> _mostrarDialogoNombre({String inicial = ''}) async {
    final controller = TextEditingController(text: inicial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva materia'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la materia',
            hintText: 'Ej. Cálculo Diferencial',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis materias'),
        actions: [
          IconButton(
            tooltip: 'Agregar materia',
            onPressed: _agregar,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: kVerde))
          : _materias.isEmpty
              ? _buildEmpty()
              : _buildLista(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add),
        label: const Text('Nueva materia', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: kVerdeClaro, shape: BoxShape.circle),
              child: Icon(Icons.menu_book_outlined, size: 40, color: kVerde.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin materias registradas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tus materias para poder\nasignarlas a tus eventos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _materias.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final materia = _materias[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kVerdeClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_outlined, color: kVerde, size: 22),
            ),
            title: Text(
              materia.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _eliminar(materia),
            ),
          ),
        );
      },
    );
  }
}

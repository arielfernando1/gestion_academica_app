import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/database_service.dart';
import '../widgets/evento_card.dart';
import 'evento_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Evento> _eventos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() {
      _cargando = true;
    });

    final eventos = await DatabaseService.instance.getEventos();

    if (!mounted) return;

    setState(() {
      _eventos = eventos;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EventoFormScreen(),
      ),
    );

    if (resultado == true) {
      await _cargarEventos();
    }
  }

  Future<void> _eliminarEvento(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento'),
          content: Text('¿Desea eliminar "${evento.titulo}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true && evento.id != null) {
      await DatabaseService.instance.deleteEvento(evento.id!);
      await _cargarEventos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento eliminado'),
        ),
      );
    }
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_eventos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay eventos registrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Presione el botón + para registrar una tarea, examen, clase o entrega.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEventos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eventos.length,
        itemBuilder: (context, index) {
          final evento = _eventos[index];

          return EventoCard(
            evento: evento,
            onDelete: () => _eliminarEvento(evento),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalEventos = _eventos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Académica'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$totalEventos evento(s)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _buildContenido(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}
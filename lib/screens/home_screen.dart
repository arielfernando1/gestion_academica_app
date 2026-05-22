import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../widgets/evento_card.dart';
import 'connection_log_screen.dart';
import 'evento_form_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Evento> _eventos = [];
  bool _cargando = true;
  bool _syncing = false;
  bool _syncFailed = false;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
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

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncFailed = false;
    });

    final success = await SyncService.instance.sync();

    if (!mounted) return;

    setState(() {
      _syncing = false;
      _syncFailed = !success;
    });

    if (success) {
      await _cargarEventos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización completada')),
        );
      }
    }
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

  void _abrirAyuda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpScreen(),
      ),
    );
  }

  void _abrirConexion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConnectionLogScreen(),
      ),
    );
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
      await SyncService.instance.deleteEvento(evento.id!, evento.remoteId);
      await _cargarEventos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento eliminado'),
        ),
      );
    }
  }

  Widget _buildLeyendaPrioridad() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text(
                  'Prioridad por fecha',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChipLeyenda(
                  color: Colors.green.shade100,
                  texto: 'Verde: 2 días o más',
                ),
                _buildChipLeyenda(
                  color: Colors.amber.shade100,
                  texto: 'Amarillo: mañana',
                ),
                _buildChipLeyenda(
                  color: Colors.red.shade100,
                  texto: 'Rojo: hoy o vencido',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipLeyenda({
    required Color color,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12),
      ),
    );
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
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay eventos registrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Presione el botón "Nuevo" para registrar una tarea, examen, clase o entrega.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _abrirAyuda,
                icon: const Icon(Icons.help_outline),
                label: const Text('Ver ayuda'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEventos,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _eventos.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildLeyendaPrioridad();
          }

          final evento = _eventos[index - 1];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EventoCard(
              evento: evento,
              onDelete: () => _eliminarEvento(evento),
            ),
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
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: _syncFailed
                  ? 'Sin conexión con MySQL. Reintentar'
                  : 'Sincronizar con MySQL',
              icon: Icon(
                _syncFailed ? Icons.sync_problem : Icons.sync,
                color: _syncFailed ? Colors.orange : null,
              ),
              onPressed: _sync,
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$totalEventos evento(s)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Estado de conexión',
            onPressed: _abrirConexion,
            icon: Icon(
              Icons.monitor_heart_outlined,
              color: _syncFailed ? Colors.orange : null,
            ),
          ),
          IconButton(
            tooltip: 'Ayuda',
            onPressed: _abrirAyuda,
            icon: const Icon(Icons.help_outline),
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

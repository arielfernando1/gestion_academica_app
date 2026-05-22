import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/evento.dart';
import '../services/database_service.dart';
import '../services/materia_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import '../widgets/evento_card.dart';
import 'connection_log_screen.dart';
import 'evento_form_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'materias_screen.dart';

enum FiltroTiempo { todos, hoy, semana }

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
  FiltroTiempo _filtro = FiltroTiempo.todos;

  @override
  void initState() {
    super.initState();
    MateriaService.instance.init();
    _cargarEventos();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  List<Evento> get _eventosFiltrados {
    if (_filtro == FiltroTiempo.todos) return _eventos;

    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);

    return _eventos.where((e) {
      final fecha = DateTime.tryParse(e.fecha);
      if (fecha == null) return false;
      final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);

      if (_filtro == FiltroTiempo.hoy) return fechaSolo == hoy;

      final finSemana = hoy.add(const Duration(days: 7));
      return !fechaSolo.isBefore(hoy) && fechaSolo.isBefore(finSemana);
    }).toList();
  }

  Future<void> _cargarEventos() async {
    setState(() => _cargando = true);
    final eventos = await DatabaseService.instance.getEventos();
    if (!mounted) return;
    setState(() {
      _eventos = eventos;
      _cargando = false;
    });
    NotificationService.instance.notificarProximos(eventos);
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

  Future<void> _abrirFormulario({Evento? evento}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventoFormScreen(evento: evento)),
    );
    if (resultado == true) await _cargarEventos();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          '¿Desea salir de la cuenta ${SessionService.instance.userEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      SessionService.instance.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _abrirAyuda() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));

  void _abrirConexion() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionLogScreen()));

  Future<void> _eliminarEvento(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Desea eliminar "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && evento.id != null) {
      await SyncService.instance.deleteEvento(evento.id!, evento.remoteId);
      await _cargarEventos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado')),
      );
    }
  }

  Future<void> _toggleCompletado(Evento evento) async {
    if (evento.id == null) return;
    final nuevo = evento.estado == 'completado' ? 'pendiente' : 'completado';
    await DatabaseService.instance.updateEstado(evento.id!, nuevo);
    await _cargarEventos();
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _buildFiltros() {
    return Container(
      color: kVerde,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: FiltroTiempo.values.map((filtro) {
          final selected = _filtro == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _labelFiltro(filtro),
                style: TextStyle(
                  color: selected ? kVerde : Colors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filtro = filtro),
              selectedColor: kAmarillo,
              backgroundColor: kVerde,
              side: BorderSide(
                color: selected ? kAmarillo : Colors.white.withValues(alpha: 0.5),
                width: selected ? 1.5 : 1,
              ),
              checkmarkColor: kVerde,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelFiltro(FiltroTiempo filtro) {
    switch (filtro) {
      case FiltroTiempo.todos:
        return 'Todos';
      case FiltroTiempo.hoy:
        return 'Hoy';
      case FiltroTiempo.semana:
        return 'Esta semana';
    }
  }

  Widget _buildResumen() {
    final total = _eventosFiltrados.length;
    final pendientes = _eventosFiltrados.where((e) => e.estado != 'completado').length;
    final completados = total - pendientes;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kVerde.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _buildStat('Total', total, Colors.grey.shade700),
          _buildDivider(),
          _buildStat('Pendientes', pendientes, const Color(0xFFF57C00)),
          _buildDivider(),
          _buildStat('Completados', completados, kVerde),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildLeyenda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildChipLeyenda(color: kVerde, texto: '2+ días'),
          _buildChipLeyenda(color: const Color(0xFFF57C00), texto: 'Mañana'),
          _buildChipLeyenda(color: const Color(0xFFD32F2F), texto: 'Hoy / Vencido'),
          _buildChipLeyenda(color: Colors.grey, texto: 'Completado'),
        ],
      ),
    );
  }

  Widget _buildChipLeyenda({required Color color, required String texto}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kVerdeClaro,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy, size: 44, color: kVerde.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin eventos registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón Nuevo para agregar\ntareas, exámenes y entregas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
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

  Widget _buildEmptyFiltro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin eventos para ${_labelFiltro(_filtro).toLowerCase()}',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: kVerde),
      );
    }

    if (_eventos.isEmpty) return _buildEmpty();

    final filtrados = _eventosFiltrados;

    return Column(
      children: [
        _buildFiltros(),
        Expanded(
          child: RefreshIndicator(
            color: kVerde,
            onRefresh: _cargarEventos,
            child: filtrados.isEmpty
                ? _buildEmptyFiltro()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filtrados.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildResumen();
                      if (index == 1) return _buildLeyenda();

                      final evento = filtrados[index - 2];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: EventoCard(
                          evento: evento,
                          onDelete: () => _eliminarEvento(evento),
                          onEdit: () => _abrirFormulario(evento: evento),
                          onToggleComplete: () => _toggleCompletado(evento),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: _syncFailed ? 'Sin conexión. Reintentar' : 'Sincronizar',
              icon: Icon(
                _syncFailed ? Icons.sync_problem : Icons.sync,
                color: _syncFailed ? kAmarillo : Colors.white,
              ),
              onPressed: _sync,
            ),
          IconButton(
            tooltip: 'Conexión',
            onPressed: _abrirConexion,
            icon: Icon(
              Icons.monitor_heart_outlined,
              color: _syncFailed ? kAmarillo : Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Ayuda',
            onPressed: _abrirAyuda,
            icon: const Icon(Icons.help_outline, color: Colors.white),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onSelected: (v) {
              if (v == 'logout') _cerrarSesion();
              if (v == 'materias') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MateriasScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sesión activa',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SessionService.instance.userEmail ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'materias',
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 18, color: kVerde),
                    SizedBox(width: 10),
                    Text('Mis materias'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildContenido(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: kAmarillo,
        foregroundColor: kVerdeOscuro,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

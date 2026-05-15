import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:async';

import '../models/evento.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class EventoFormScreen extends StatefulWidget {
  const EventoFormScreen({super.key});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _materiaController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipoSeleccionado = 'Tarea';
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  final List<String> _tipos = [
    'Tarea',
    'Examen',
    'Clase',
    'Entrega',
    'Reunión',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _materiaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fechaActual = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? fechaActual,
      firstDate: DateTime(fechaActual.year - 1),
      lastDate: DateTime(fechaActual.year + 5),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  String _mostrarFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _guardarEvento() async {
    final formularioValido = _formKey.currentState!.validate();

    if (!formularioValido) {
      return;
    }

    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Seleccione una fecha');
      return;
    }

    if (_horaSeleccionada == null) {
      _mostrarMensaje('Seleccione una hora');
      return;
    }

    final evento = Evento(
      titulo: _tituloController.text.trim(),
      materia: _materiaController.text.trim(),
      tipo: _tipoSeleccionado,
      fecha: _formatearFecha(_fechaSeleccionada!),
      hora: _formatearHora(_horaSeleccionada!),
      descripcion: _descripcionController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService.instance.insertEvento(evento);
    unawaited(SyncService.instance.sync());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evento guardado correctamente'),
      ),
    );

    Navigator.pop(context, true);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  InputDecoration _decoracionCampo(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto = _fechaSeleccionada == null
        ? 'Seleccionar fecha'
        : _mostrarFecha(_fechaSeleccionada!);

    final horaTexto = _horaSeleccionada == null
        ? 'Seleccionar hora'
        : _formatearHora(_horaSeleccionada!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: _decoracionCampo(
                      'Título del evento',
                      Icons.title,
                      hintText: 'Ej. Entrega práctica Semana 2',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese el título del evento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _materiaController,
                    decoration: _decoracionCampo(
                      'Materia',
                      Icons.menu_book,
                      hintText: 'Ej. Metodología de Desarrollo de Software',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese la materia';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _tipoSeleccionado,
                    decoration: _decoracionCampo(
                      'Tipo de evento',
                      Icons.category,
                    ),
                    items: _tipos.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tipoSeleccionado = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarFecha,
                          icon: const Icon(Icons.calendar_month),
                          label: Text(fechaTexto),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarHora,
                          icon: const Icon(Icons.access_time),
                          label: Text(horaTexto),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: _decoracionCampo(
                      'Descripción opcional',
                      Icons.description,
                      hintText: 'Ej. Incluir capturas, pruebas funcionales y demo.',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _guardarEvento,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
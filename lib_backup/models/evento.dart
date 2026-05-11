class Evento {
  final int? id;
  final String titulo;
  final String materia;
  final String tipo;
  final String fecha;
  final String hora;
  final String descripcion;
  final String estado;
  final String createdAt;

  Evento({
    this.id,
    required this.titulo,
    required this.materia,
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.descripcion,
    this.estado = 'pendiente',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'materia': materia,
      'tipo': tipo,
      'fecha': fecha,
      'hora': hora,
      'descripcion': descripcion,
      'estado': estado,
      'created_at': createdAt,
    };
  }

  factory Evento.fromMap(Map<String, dynamic> map) {
    return Evento(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      materia: map['materia'] as String,
      tipo: map['tipo'] as String,
      fecha: map['fecha'] as String,
      hora: map['hora'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      estado: map['estado'] as String? ?? 'pendiente',
      createdAt: map['created_at'] as String,
    );
  }
}
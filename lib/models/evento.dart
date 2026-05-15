class Evento {
  final int? id;
  final int? remoteId;
  final String titulo;
  final String materia;
  final String tipo;
  final String fecha;
  final String hora;
  final String descripcion;
  final String estado;
  final String createdAt;
  final String updatedAt;
  final bool synced;

  Evento({
    this.id,
    this.remoteId,
    required this.titulo,
    required this.materia,
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.descripcion,
    this.estado = 'pendiente',
    required this.createdAt,
    String? updatedAt,
    this.synced = false,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remote_id': remoteId,
      'titulo': titulo,
      'materia': materia,
      'tipo': tipo,
      'fecha': fecha,
      'hora': hora,
      'descripcion': descripcion,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  factory Evento.fromMap(Map<String, dynamic> map) {
    return Evento(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      titulo: map['titulo'] as String,
      materia: map['materia'] as String,
      tipo: map['tipo'] as String,
      fecha: map['fecha'] as String,
      hora: map['hora'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      estado: map['estado'] as String? ?? 'pendiente',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Evento copyWith({
    int? id,
    int? remoteId,
    String? titulo,
    String? materia,
    String? tipo,
    String? fecha,
    String? hora,
    String? descripcion,
    String? estado,
    String? createdAt,
    String? updatedAt,
    bool? synced,
  }) {
    return Evento(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      titulo: titulo ?? this.titulo,
      materia: materia ?? this.materia,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

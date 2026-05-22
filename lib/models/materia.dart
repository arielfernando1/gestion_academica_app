class Materia {
  final int? id;
  final String nombre;
  final String userEmail;

  const Materia({this.id, required this.nombre, this.userEmail = ''});

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'user_email': userEmail,
      };

  factory Materia.fromMap(Map<String, dynamic> map) => Materia(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        userEmail: map['user_email'] as String? ?? '',
      );
}

class Scene {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String description;
  final List<String> devices;
  final Map<String, dynamic> actions;
  final Map<String, dynamic>? trigger;

  Scene({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.devices,
    required this.actions,
    this.trigger,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Scene',
      icon: json['icon'] ?? '57746', // Default to lightbulb icon code point
      color: json['color'] ?? '4280391411', // Default to blue
      description: json['description'] ?? '',
      devices: json['devices'] != null ? List<String>.from(json['devices']) : [],
      actions: json['actions'] != null ? Map<String, dynamic>.from(json['actions']) : {},
      trigger: json['trigger'] != null ? Map<String, dynamic>.from(json['trigger']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'description': description,
      'devices': devices,
      'actions': actions,
      'trigger': trigger,
    };
  }
}

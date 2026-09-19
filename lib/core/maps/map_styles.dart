/// Google Maps JSON styles — MatlobGo light/dark.
abstract final class MapStyles {
  static const String light = '''
[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f7fa"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e2e8f0"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#fde8d8"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#dbeafe"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]}
]
''';

  static const String dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0B1220"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8b9cb3"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0B1220"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2838"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#243447"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#071018"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#111827"}]}
]
''';
}

import 'dart:io';
import '../lib/services/tcg_api_service.dart';

void main() async {
  final api = TcgApiService();
  final results = await api.getJapaneseSets();
  List<Map<String, dynamic>> sets = [];
  
  if (results['data'] != null && (results['data'] as List).isNotEmpty) {
    sets = (results['data'] as List).cast<Map<String, dynamic>>();
  } else {
    // Fallback to hardcoded recent Japanese sets if API fails
    sets = [
      {
        'id': 'sv8c-jp',
        'name': 'Wild Force (Japan)',
        'series': 'Scarlet & Violet',
        'printedTotal': 67,
        'total': 67,
        'legalities': {'unlimited': 'Legal'},
        'releaseDate': '2024/02/23',
        'images': {
          'symbol': 'https://images.pokemontcg.io/sv8c-jp/symbol.png',
          'logo': 'https://images.pokemontcg.io/sv8c-jp/logo.png'
        }
      },
      {
        'id': 'sv8b-jp',
        'name': 'Battle Legion (Japan)',
        'series': 'Scarlet & Violet',
        'printedTotal': 69,
        'total': 69,
        'legalities': {'unlimited': 'Legal'},
        'releaseDate': '2024/02/09',
        'images': {
          'symbol': 'https://images.pokemontcg.io/sv8b-jp/symbol.png',
          'logo': 'https://images.pokemontcg.io/sv8b-jp/logo.png'
        }
      },
      // Add more fallback sets here
    ];
  }

  // Group sets by series
  final seriesMap = <String, List<Map<String, dynamic>>>{};
  
  for (final set in sets) {
    final series = set['series'] as String;
    seriesMap[series] = seriesMap[series] ?? [];
    seriesMap[series]!.add(set as Map<String, dynamic>);
  }

  // Generate Dart code
  final buffer = StringBuffer();
  buffer.writeln('class JapaneseSets {');

  // Generate constants for each series
  for (final entry in seriesMap.entries) {
    final seriesName = entry.key.toLowerCase().replaceAll(' & ', '');
    buffer.writeln('\n  static const $seriesName = <String, Map<String, dynamic>>{');

    for (final set in entry.value) {
      buffer.writeln('''
    '${set['name']}': {
      'id': '${set['id']}',
      'name': '${set['name']}',
      'series': '${set['series']}',
      'printedTotal': ${set['printedTotal']},
      'total': ${set['total']},
      'legalities': ${_formatLegalities(set['legalities'])},
      'releaseDate': '${set['releaseDate']}',
      'code': '${set['id'].split('-').first}',
      'icon': '${_getSetIcon(set['name'])}',
      'query': 'set.id:${set['id']} language:japanese',
      'images': {
        'logo': '${set['images']?['logo'] ?? ''}',
        'symbol': '${set['images']?['symbol'] ?? ''}'
      }
    },''');
    }

    buffer.writeln('  };');
  }

  // Add helper methods
  buffer.writeln('''
  // Helper methods
  static List<Map<String, dynamic>> getAllSets() {
    final allSets = <Map<String, dynamic>>[];
    
    void addSetsFromEra(Map<String, Map<String, dynamic>> era) {
      era.forEach((name, data) {
        allSets.add({
          ...data,
          'name': name,
          'language': 'Japanese',
        });
      });
    }

    ${seriesMap.keys.map((series) => 
      "addSetsFromEra(${series.toLowerCase().replaceAll(' & ', '')});"
    ).join('\n    ')}

    return allSets;
  }

  static List<Map<String, dynamic>> searchSets(String query) {
    query = query.toLowerCase();
    return getAllSets().where((set) {
      return set['name'].toLowerCase().contains(query) ||
             set['series'].toLowerCase().contains(query) ||
             (set['releaseDate'] as String).contains(query);
    }).toList();
  }

  static Map<String, dynamic>? getSetById(String id) {
    return getAllSets().firstWhere(
      (set) => set['id'] == id,
      orElse: () => {},
    );
  }
''');

  buffer.writeln('}');

  // Write to file
  final file = File('../lib/constants/japanese_sets.dart');
  await file.writeAsString(buffer.toString());
  
  print('Generated Japanese sets constants file');
  exit(0);
}

String _formatLegalities(Map<String, dynamic> legalities) {
  final entries = legalities.entries.map((e) => "'${e.key}': '${e.value}'").join(', ');
  return '{$entries}';
}

String _getSetIcon(String name) {
  // Add logic to assign appropriate emoji icons based on set names
  if (name.toLowerCase().contains('star')) return '⭐';
  if (name.toLowerCase().contains('brilliant')) return '✨';
  if (name.toLowerCase().contains('fusion')) return '🔄';
  if (name.toLowerCase().contains('battle')) return '⚔️';
  if (name.toLowerCase().contains('silver')) return '🥈';
  if (name.toLowerCase().contains('gold')) return '🥇';
  if (name.toLowerCase().contains('crown')) return '👑';
  // Add more mappings as needed
  return '📦'; // Default icon
}

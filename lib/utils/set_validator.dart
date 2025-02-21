import '../services/tcg_api_service.dart';
import '../constants/sets.dart';

class SetValidator {
  static Future<void> validateAndUpdateSets() async {
    final api = TcgApiService();
    
    try {
      final response = await api.getSets();
      final List<dynamic> apiSets = response['data'] as List;
      
      final Map<String, Map<String, dynamic>> knownSets = {};
      final Map<String, Map<String, dynamic>> missingSets = {};
      
      // Convert our sets to a comparable format
      final localSets = {
        ...PokemonSets.scarletViolet,
        ...PokemonSets.swordShield,
        ...PokemonSets.sunMoon,
        ...PokemonSets.xy,
        ...PokemonSets.blackWhite,
        ...PokemonSets.classic,
        ...PokemonSets.ex,
      };

      // Check API sets against our local sets
      for (final apiSet in apiSets) {
        final setId = apiSet['id'] as String;
        final setName = apiSet['name'] as String;
        final releaseDate = apiSet['releaseDate'] as String?;
        final year = releaseDate?.split('-')[0];

        if (localSets.values.any((set) => set['code'] == setId)) {
          knownSets[setId] = {
            'name': setName,
            'year': year,
            'inLocal': true,
          };
        } else {
          missingSets[setId] = {
            'name': setName,
            'year': year,
            'series': apiSet['series'],
          };
        }
      }

      // Log results
      print('\n🔍 Set Validation Results:');
      print('Found ${knownSets.length} known sets');
      print('Missing ${missingSets.length} sets\n');

      if (missingSets.isNotEmpty) {
        print('Missing Sets:');
        missingSets.forEach((id, data) {
          print('''
{
  '${data['name']}': {
    'code': '$id',
    'year': '${data['year']}',
    'icon': '✨',  // TODO: Add appropriate icon
    'series': '${data['series']}'
  },
},''');
        });
      }

    } catch (e) {
      print('Error validating sets: $e');
    }
  }

  static String suggestIcon(String setName) {
    final name = setName.toLowerCase();
    
    if (name.contains('fire')) return '🔥';
    if (name.contains('water') || name.contains('aqua')) return '🌊';
    if (name.contains('leaf') || name.contains('grass')) return '🌿';
    if (name.contains('thunder') || name.contains('lightning')) return '⚡';
    if (name.contains('dragon')) return '🐉';
    if (name.contains('cosmic') || name.contains('star')) return '✨';
    if (name.contains('dark')) return '🌑';
    if (name.contains('ghost') || name.contains('phantom')) return '👻';
    if (name.contains('ancient')) return '🗿';
    if (name.contains('rainbow')) return '🌈';
    if (name.contains('crystal')) return '💎';
    if (name.contains('legend')) return '👑';
    if (name.contains('promo')) return '🎁';
    if (name.contains('fusion')) return '🔄';
    if (name.contains('team')) return '👥';
    if (name.contains('battle')) return '⚔️';
    
    return '✨'; // Default icon
  }
}

class SetValidatorRunner {
  static Future<void> run() async {
    print('🔍 Starting set validation...');
    
    final api = TcgApiService();
    
    try {
      final response = await api.getSets();
      final List<dynamic> apiSets = response['data'] as List;
      
      final Map<String, Map<String, dynamic>> knownSets = {};
      final Map<String, Map<String, dynamic>> missingSets = {};
      
      // Convert our sets to a comparable format
      final localSets = {
        ...PokemonSets.scarletViolet,
        ...PokemonSets.swordShield,
        ...PokemonSets.sunMoon,
        ...PokemonSets.xy,
        ...PokemonSets.blackWhite,
        ...PokemonSets.classic,
        ...PokemonSets.ex,
      };

      print('\nChecking ${apiSets.length} sets from API against ${localSets.length} local sets...\n');

      // Check API sets against our local sets
      for (final apiSet in apiSets) {
        final setId = apiSet['id'] as String;
        final setName = apiSet['name'] as String;
        final releaseDate = apiSet['releaseDate'] as String?;
        final series = apiSet['series'] as String?;
        final year = releaseDate?.split('-')[0];

        if (localSets.values.any((set) => set['code'] == setId)) {
          knownSets[setId] = {
            'name': setName,
            'year': year,
            'inLocal': true,
          };
        } else {
          missingSets[setId] = {
            'name': setName,
            'year': year,
            'series': series,
          };
        }
      }

      // Log results
      print('📊 Set Validation Results:');
      print('✅ Found ${knownSets.length} known sets');
      print('❌ Missing ${missingSets.length} sets\n');

      if (missingSets.isNotEmpty) {
        print('Missing Sets (Copy and add to appropriate era in sets.dart):');
        print('----------------------------------------\n');
        
        // Group by series
        final seriesGroups = <String, List<MapEntry<String, Map<String, dynamic>>>>{};
        missingSets.entries.forEach((entry) {
          final series = entry.value['series'] as String? ?? 'Unknown';
          seriesGroups.putIfAbsent(series, () => []).add(entry);
        });

        // Print by series
        seriesGroups.forEach((series, sets) {
          print('// $series Series');
          sets.forEach((entry) {
            final setId = entry.key;
            final data = entry.value;
            print('''
'${data['name']}': {
  'code': '$setId',
  'year': '${data['year']}',
  'icon': '✨',  // TODO: Choose appropriate icon
},''');
          });
          print('');
        });
      }

    } catch (e) {
      print('❌ Error validating sets: $e');
    }
  }
}

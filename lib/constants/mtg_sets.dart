import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// Collection of Magic: The Gathering set information organized by format
class MtgSets {
  // Standard format sets (most recent)
  static final Map<String, Map<String, dynamic>> standard = {
    'mom': _buildSetData('mom', 'March of the Machine', '2023-04-21'),
    'one': _buildSetData('one', 'Phyrexia: All Will Be One', '2023-02-10'),
    'bro': _buildSetData('bro', 'The Brothers\' War', '2022-11-18'),
    'dmu': _buildSetData('dmu', 'Dominaria United', '2022-09-09'),
    'snc': _buildSetData('snc', 'Streets of New Capenna', '2022-04-29'),
    'neo': _buildSetData('neo', 'Kamigawa: Neon Dynasty', '2022-02-18'),
    'vow': _buildSetData('vow', 'Innistrad: Crimson Vow', '2021-11-19'),
    'mid': _buildSetData('mid', 'Innistrad: Midnight Hunt', '2021-09-24'),
  };

  // Modern format sets
  static final Map<String, Map<String, dynamic>> modern = {
    'mh3': _buildSetData('mh3', 'Modern Horizons 3', '2023-06-14'),
    'mh2': _buildSetData('mh2', 'Modern Horizons 2', '2021-06-18'),
    'mh1': _buildSetData('mh1', 'Modern Horizons', '2019-06-14'),
    'war': _buildSetData('war', 'War of the Spark', '2019-05-03'),
    'rna': _buildSetData('rna', 'Ravnica Allegiance', '2019-01-25'),
  };

  // Legacy format sets
  static final Map<String, Map<String, dynamic>> legacy = {
    'usg': _buildSetData('usg', 'Urza\'s Saga', '1998-10-12'),
    'mmq': _buildSetData('mmq', 'Mercadian Masques', '1999-10-04'),
    'inv': _buildSetData('inv', 'Invasion', '2000-10-02'),
    'ody': _buildSetData('ody', 'Odyssey', '2001-10-01'),
    'ice': _buildSetData('ice', 'Ice Age', '1995-06-01'),
  };

  // Helper method to build a set data entry with consistent structure
  static Map<String, dynamic> _buildSetData(String code, String name, String releaseDate) {
    // Build URLs for both potential sources
    final String setIconUrl = 'https://svgs.scryfall.io/sets/$code.svg';
    
    return {
      'code': code,
      'name': name,
      'releaseDate': releaseDate,
      'year': releaseDate.substring(0, 4), // Extract year from the date
      'logo': setIconUrl,
      'query': 'set.id:$code',  // Make sure this is correctly formatted
    };
  }

  // Get sets for a specific category
  static List<Map<String, dynamic>> getSetsForCategory(String category) {
    Map<String, Map<String, dynamic>> sets;
    
    switch (category.toLowerCase()) {
      case 'standard':
        sets = standard;
        break;
      case 'modern':
        sets = modern;
        break;
      case 'legacy':
        sets = legacy;
        break;
      default:
        return [];
    }
    
    return sets.entries
        .map((entry) => {
              ...entry.value,
              'id': entry.key,
              'code': entry.key,
              'name': entry.value['name'],
              'query': 'set.id:${entry.key}', // Ensure this format is preserved
            })
        .toList();
  }
}

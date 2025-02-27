import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// Collection of Magic: The Gathering set information organized by format and chronology
class MtgSets {
  // Standard format sets (most recent)
  static final Map<String, Map<String, dynamic>> standard = {
    'otj': _buildSetData('otj', 'Outlaws of Thunder Junction', '2024-04-19'),
    'mkm': _buildSetData('mkm', 'Murders at Karlov Manor', '2024-02-09'),
    'lci': _buildSetData('lci', 'Lost Caverns of Ixalan', '2023-11-17'),
    'woe': _buildSetData('woe', 'Wilds of Eldraine', '2023-09-08'),
    'ltr': _buildSetData('ltr', 'Lord of the Rings: Tales of Middle-Earth', '2023-06-23'),
    'mom': _buildSetData('mom', 'March of the Machine', '2023-04-21'),
    'one': _buildSetData('one', 'Phyrexia: All Will Be One', '2023-02-10'),
    'bro': _buildSetData('bro', 'The Brothers\' War', '2022-11-18'),
    'dmu': _buildSetData('dmu', 'Dominaria United', '2022-09-09'),
    'snc': _buildSetData('snc', 'Streets of New Capenna', '2022-04-29'),
    'neo': _buildSetData('neo', 'Kamigawa: Neon Dynasty', '2022-02-18'),
    'vow': _buildSetData('vow', 'Innistrad: Crimson Vow', '2021-11-19'),
    'mid': _buildSetData('mid', 'Innistrad: Midnight Hunt', '2021-09-24'),
  };

  // Modern format sets (chronological order, newest first)
  static final Map<String, Map<String, dynamic>> modern = {
    'mh3': _buildSetData('mh3', 'Modern Horizons 3', '2023-06-14'),
    'mh2': _buildSetData('mh2', 'Modern Horizons 2', '2021-06-18'),
    'stx': _buildSetData('stx', 'Strixhaven: School of Mages', '2021-04-23'),
    'khm': _buildSetData('khm', 'Kaldheim', '2021-02-05'),
    'znr': _buildSetData('znr', 'Zendikar Rising', '2020-09-25'),
    'iko': _buildSetData('iko', 'Ikoria: Lair of Behemoths', '2020-04-24'),
    'thb': _buildSetData('thb', 'Theros Beyond Death', '2020-01-24'),
    'eld': _buildSetData('eld', 'Throne of Eldraine', '2019-10-04'),
    'mh1': _buildSetData('mh1', 'Modern Horizons', '2019-06-14'),
    'war': _buildSetData('war', 'War of the Spark', '2019-05-03'),
    'rna': _buildSetData('rna', 'Ravnica Allegiance', '2019-01-25'),
    'grn': _buildSetData('grn', 'Guilds of Ravnica', '2018-10-05'),
    'dom': _buildSetData('dom', 'Dominaria', '2018-04-27'),
    'rix': _buildSetData('rix', 'Rivals of Ixalan', '2018-01-19'),
    'xln': _buildSetData('xln', 'Ixalan', '2017-09-29'),
  };

  // Pioneer format sets (more relatively recent sets)
  static final Map<String, Map<String, dynamic>> pioneer = {
    'hou': _buildSetData('hou', 'Hour of Devastation', '2017-07-14'),
    'akh': _buildSetData('akh', 'Amonkhet', '2017-04-28'),
    'aer': _buildSetData('aer', 'Aether Revolt', '2017-01-20'),
    'kld': _buildSetData('kld', 'Kaladesh', '2016-09-30'),
    'emn': _buildSetData('emn', 'Eldritch Moon', '2016-07-22'),
    'soi': _buildSetData('soi', 'Shadows over Innistrad', '2016-04-08'),
    'ogw': _buildSetData('ogw', 'Oath of the Gatewatch', '2016-01-22'),
    'bfz': _buildSetData('bfz', 'Battle for Zendikar', '2015-10-02'),
    'ori': _buildSetData('ori', 'Magic Origins', '2015-07-17'),
    'dtk': _buildSetData('dtk', 'Dragons of Tarkir', '2015-03-27'),
    'frf': _buildSetData('frf', 'Fate Reforged', '2015-01-23'),
    'ktk': _buildSetData('ktk', 'Khans of Tarkir', '2014-09-26'),
    'jou': _buildSetData('jou', 'Journey into Nyx', '2014-05-02'),
    'bng': _buildSetData('bng', 'Born of the Gods', '2014-02-07'),
    'ths': _buildSetData('ths', 'Theros', '2013-09-27'),
    'dgm': _buildSetData('dgm', 'Dragon\'s Maze', '2013-05-03'),
    'gtc': _buildSetData('gtc', 'Gatecrash', '2013-02-01'),
    'rtr': _buildSetData('rtr', 'Return to Ravnica', '2012-10-05'),
  };

  // Legacy format sets (older sets)
  static final Map<String, Map<String, dynamic>> legacy = {
    'avr': _buildSetData('avr', 'Avacyn Restored', '2012-05-04'),
    'dka': _buildSetData('dka', 'Dark Ascension', '2012-02-03'),
    'isd': _buildSetData('isd', 'Innistrad', '2011-09-30'),
    'nph': _buildSetData('nph', 'New Phyrexia', '2011-05-13'),
    'mbs': _buildSetData('mbs', 'Mirrodin Besieged', '2011-02-04'),
    'som': _buildSetData('som', 'Scars of Mirrodin', '2010-10-01'),
    'roe': _buildSetData('roe', 'Rise of the Eldrazi', '2010-04-23'),
    'wwk': _buildSetData('wwk', 'Worldwake', '2010-02-05'),
    'zen': _buildSetData('zen', 'Zendikar', '2009-10-02'),
    'arb': _buildSetData('arb', 'Alara Reborn', '2009-04-30'),
    'con': _buildSetData('con', 'Conflux', '2009-02-06'),
    'ala': _buildSetData('ala', 'Shards of Alara', '2008-10-03'),
    'eve': _buildSetData('eve', 'Eventide', '2008-07-25'),
    'shm': _buildSetData('shm', 'Shadowmoor', '2008-05-02'),
    'mor': _buildSetData('mor', 'Morningtide', '2008-02-01'),
    'lrw': _buildSetData('lrw', 'Lorwyn', '2007-10-12'),
    'fut': _buildSetData('fut', 'Future Sight', '2007-05-04'),
    'plc': _buildSetData('plc', 'Planar Chaos', '2007-02-02'),
    'tsp': _buildSetData('tsp', 'Time Spiral', '2006-10-06'),
    'dis': _buildSetData('dis', 'Dissension', '2006-05-05'),
    'gpt': _buildSetData('gpt', 'Guildpact', '2006-02-03'),
    'rav': _buildSetData('rav', 'Ravnica: City of Guilds', '2005-10-07'),
  };

  // Classic format sets (iconic older sets)
  static final Map<String, Map<String, dynamic>> classic = {
    'usg': _buildSetData('usg', 'Urza\'s Saga', '1998-10-12'),
    'ulg': _buildSetData('ulg', 'Urza\'s Legacy', '1999-02-15'),
    'uds': _buildSetData('uds', 'Urza\'s Destiny', '1999-06-07'),
    'mmq': _buildSetData('mmq', 'Mercadian Masques', '1999-10-04'),
    'nms': _buildSetData('nms', 'Nemesis', '2000-02-14'),
    'pcy': _buildSetData('pcy', 'Prophecy', '2000-06-05'),
    'inv': _buildSetData('inv', 'Invasion', '2000-10-02'),
    'pls': _buildSetData('pls', 'Planeshift', '2001-02-05'),
    'apc': _buildSetData('apc', 'Apocalypse', '2001-06-04'),
    'ody': _buildSetData('ody', 'Odyssey', '2001-10-01'),
    'mrd': _buildSetData('mrd', 'Mirrodin', '2003-10-02'),
    'dst': _buildSetData('dst', 'Darksteel', '2004-02-06'),
    'fifth': _buildSetData('5ed', '5th Edition', '1997-03-24'),
    'ice': _buildSetData('ice', 'Ice Age', '1995-06-01'),
    'all': _buildSetData('all', 'Alliances', '1996-06-10'),
    'mir': _buildSetData('mir', 'Mirage', '1996-10-08'),
    'vis': _buildSetData('vis', 'Visions', '1997-02-03'),
    'wth': _buildSetData('wth', 'Weatherlight', '1997-06-09'),
    'tmp': _buildSetData('tmp', 'Tempest', '1997-10-14'),
    'lea': _buildSetData('lea', 'Alpha', '1993-08-05'),
    'leb': _buildSetData('leb', 'Beta', '1993-10-01'),
    'arn': _buildSetData('arn', 'Arabian Nights', '1993-12-01'),
    'atq': _buildSetData('atq', 'Antiquities', '1994-03-01'),
    'leg': _buildSetData('leg', 'Legends', '1994-06-01'),
    'drk': _buildSetData('drk', 'The Dark', '1994-08-01'),
    'fem': _buildSetData('fem', 'Fallen Empires', '1994-11-01'),
  };

  // Add Commander and Special sets
  static final Map<String, Map<String, dynamic>> commander = {
    'cmm': _buildSetData('cmm', 'Commander Masters', '2023-08-04'),
    'clb': _buildSetData('clb', 'Commander Legends: Battle for Baldur\'s Gate', '2022-06-10'),
    'cmr': _buildSetData('cmr', 'Commander Legends', '2020-11-20'),
    'cma': _buildSetData('cma', 'Commander Anthology', '2017-06-09'),
    'c20': _buildSetData('c20', 'Commander 2020', '2020-05-15'),
    'c19': _buildSetData('c19', 'Commander 2019', '2019-08-23'),
    'c18': _buildSetData('c18', 'Commander 2018', '2018-08-10'),
    'c17': _buildSetData('c17', 'Commander 2017', '2017-08-25'),
    'c16': _buildSetData('c16', 'Commander 2016', '2016-11-11'),
    'c15': _buildSetData('c15', 'Commander 2015', '2015-11-13'),
    'c14': _buildSetData('c14', 'Commander 2014', '2014-11-07'),
    'c13': _buildSetData('c13', 'Commander 2013', '2013-11-01'),
    'cmd': _buildSetData('cmd', 'Commander', '2011-06-17'),
  };

  // Masters and special sets
  static final Map<String, Map<String, dynamic>> special = {
    'plst': _buildSetData('plst', 'Pauper Last Chance Qualifier', '2024-03-12'),
    'mat': _buildSetData('mat', 'March of the Machine: The Aftermath', '2023-05-12'),
    '40k': _buildSetData('40k', 'Warhammer 40,000', '2022-10-07'),
    'unf': _buildSetData('unf', 'Unfinity', '2022-10-07'),
    'slx': _buildSetData('slx', 'Universes Beyond: Stranger Things', '2021-11-01'),
    'sld': _buildSetData('sld', 'Secret Lair Drop', '2019-12-02'),
    'mb1': _buildSetData('mb1', 'Mystery Booster', '2019-11-07'),
    'gn2': _buildSetData('gn2', 'Game Night 2019', '2019-11-15'),
    'itp': _buildSetData('itp', 'Introductory Two-Player Set', '1996-12-31'),
    'vma': _buildSetData('vma', 'Vintage Masters', '2014-06-16'),
    'uma': _buildSetData('uma', 'Ultimate Masters', '2018-12-07'),
    'mm3': _buildSetData('mm3', 'Modern Masters 2017', '2017-03-17'),
    'ema': _buildSetData('ema', 'Eternal Masters', '2016-06-10'),
    'mm2': _buildSetData('mm2', 'Modern Masters 2015', '2015-05-22'),
    'mma': _buildSetData('mma', 'Modern Masters', '2013-06-07'),
    'chr': _buildSetData('chr', 'Chronicles', '1995-07-01'),
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
      case 'pioneer':
        sets = pioneer;
        break;
      case 'legacy':
        sets = legacy;
        break;
      case 'classic':
        sets = classic;
        break;
      case 'commander':
        sets = commander;
        break;
      case 'special':
        sets = special;
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

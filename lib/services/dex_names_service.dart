import 'dart:convert';
import 'package:flutter/services.dart';
import 'poke_api_service.dart';

class CollectionIndexService {
  final _pokeApiService = PokeApiService();
  Map<int, String> _dexMap = {};  // Change to map for O(1) lookup
  bool _isLoaded = false;

  // Add cached generation ranges
  final Map<int, List<String>> _generationCache = {};

  // Add mapping for special cases
  final Map<String, String> _specialNameMappings = {
    'nidoran-f': 'Nidoran♀',
    'nidoran-m': 'Nidoran♂',
    'farfetchd': 'Farfetch\'d',
    'mr-mime': 'Mr. Mime',
    'ho-oh': 'Ho-Oh',
    'mime-jr': 'Mime Jr.',
    // Add more mappings as needed
  };

  // Add generation boundaries for efficient loading
  static const Map<int, (int, int)> _generationBoundaries = {
    1: (1, 151),
    2: (152, 251),
    3: (252, 386),
    4: (387, 493),
    5: (494, 649),
    6: (650, 721),
    7: (722, 809),
    8: (810, 905),
    9: (906, 1008),
  };

  static const Map<String, int> _gen2Mappings = {
    'Chikorita': 152,
    'Bayleef': 153,
    'Meganium': 154,
    'Cyndaquil': 155,
    'Quilava': 156,
    'Typhlosion': 157,
    'Totodile': 158,
    'Croconaw': 159,
    'Feraligatr': 160,
    'Sentret': 161,
    'Furret': 162,
    'Hoothoot': 163,
    'Noctowl': 164,
    'Ledyba': 165,
    'Ledian': 166,
    'Spinarak': 167,
    'Ariados': 168,
    'Crobat': 169,
    'Chinchou': 170,
    'Lanturn': 171,
    'Pichu': 172,
    'Cleffa': 173,
    'Igglybuff': 174,
    'Togepi': 175,
    'Togetic': 176,
    'Natu': 177,
    'Xatu': 178,
    'Mareep': 179,
    'Flaaffy': 180,
    'Ampharos': 181,
    'Bellossom': 182,
    'Marill': 183,
    'Azumarill': 184,
    'Sudowoodo': 185,
    'Politoed': 186,
    'Hoppip': 187,
    'Skiploom': 188,
    'Jumpluff': 189,
    'Aipom': 190,
    'Sunkern': 191,
    'Sunflora': 192,
    'Yanma': 193,
    'Wooper': 194,
    'Quagsire': 195,
    'Espeon': 196,
    'Umbreon': 197,
    'Murkrow': 198,
    'Slowking': 199,
    'Misdreavus': 200,
    'Unown': 201,
    'Wobbuffet': 202,
    'Girafarig': 203,
    'Pineco': 204,
    'Forretress': 205,
    'Dunsparce': 206,
    'Gligar': 207,
    'Steelix': 208,
    'Snubbull': 209,
    'Granbull': 210,
    'Qwilfish': 211,
    'Scizor': 212,
    'Shuckle': 213,
    'Heracross': 214,
    'Sneasel': 215,
    'Teddiursa': 216,
    'Ursaring': 217,
    'Slugma': 218,
    'Magcargo': 219,
    'Swinub': 220,
    'Piloswine': 221,
    'Corsola': 222,
    'Remoraid': 223,
    'Octillery': 224,
    'Delibird': 225,
    'Mantine': 226,
    'Skarmory': 227,
    'Houndour': 228,
    'Houndoom': 229,
    'Kingdra': 230,
    'Phanpy': 231,
    'Donphan': 232,
    'Porygon2': 233,
    'Stantler': 234,
    'Smeargle': 235,
    'Tyrogue': 236,
    'Hitmontop': 237,
    'Smoochum': 238,
    'Elekid': 239,
    'Magby': 240,
    'Miltank': 241,
    'Blissey': 242,
    'Raikou': 243,
    'Entei': 244,
    'Suicune': 245,
    'Larvitar': 246,
    'Pupitar': 247,
    'Tyranitar': 248,
    'Lugia': 249,
    'Ho-Oh': 250,
    'Celebi': 251,
  };

  // Add Gen 3 mappings
  static const Map<String, int> _gen3Mappings = {
    'Electrode': 101,  // Adding missing Gen 1 Pokémon
    'Mew': 151,
    'Lunatone': 337,
    'Solrock': 338,
    'Barboach': 339,
    'Whiscash': 340,
    'Corphish': 341,
    'Crawdaunt': 342,
    'Baltoy': 343,
    'Claydol': 344,
    'Lileep': 345,
    'Cradily': 346,
    'Anorith': 347,
    'Armaldo': 348,
    'Feebas': 349,
    'Milotic': 350,
    'Castform': 351,
  };

  // Add Gen 4 mappings
  static const Map<String, int> _gen4Mappings = {
    'Gabite': 444,
    'Garchomp': 445,
    'Munchlax': 446,
    'Riolu': 447,
    'Lucario': 448,
    'Hippopotas': 449,
    'Hippowdon': 450,
    'Skorupi': 451,
    'Drapion': 452,
    'Croagunk': 453,
    'Toxicroak': 454,
    'Carnivine': 455,
    'Finneon': 456,
    'Lumineon': 457,
    'Mantyke': 458,
    'Snover': 459,
    'Abomasnow': 460,
    'Weavile': 461,
    'Magnezone': 462,
    'Lickilicky': 463,
    'Rhyperior': 464,
    'Tangrowth': 465,
    'Electivire': 466,
    'Magmortar': 467,
    'Togekiss': 468,
    'Yanmega': 469,
    'Leafeon': 470,
    'Glaceon': 471,
    'Gliscor': 472,
    'Mamoswine': 473,
    'Porygon-Z': 474,
    'Gallade': 475,
    'Probopass': 476,
    'Dusknoir': 477,
    'Froslass': 478,
    'Rotom': 479,
    'Uxie': 480,
    'Mesprit': 481,
    'Azelf': 482,
    'Dialga': 483,
    'Palkia': 484,
    'Heatran': 485,
    'Regigigas': 486,
  };

  // Update Gen 9 mappings with correct dex numbers (removed duplicates)
  static const Map<String, int> _gen9Mappings = {
    'Sprigatito': 906,
    'Floragato': 907,
    'Meowscarada': 908,
    'Fuecoco': 909,
    'Crocalor': 910,
    'Skeledirge': 911,
    'Quaxly': 912,
    'Quaxwell': 913,
    'Quaquaval': 914,
    'Lechonk': 915,
    'Oinkologne': 916,
    'Dudunsparce': 917,
    'Tarountula': 918,
    'Spidops': 919,
    'Nymble': 920,
    'Lokix': 921,
    'Rellor': 922,
    'Rabsca': 923,
    'Greavard': 924,
    'Houndstone': 925,
    'Flittle': 926,
    'Espathra': 927,
    'Tinkatink': 928,
    'Tinkatuff': 929,
    'Tinkaton': 930,
    'Wiglett': 931,
    'Wugtrio': 932,
    'Bombirdier': 933,
    'Finizen': 934,
    'Palafin': 935,
    'Varoom': 936,
    'Revavroom': 937,
    'Cyclizar': 938,
    'Orthworm': 939,
    'Glimmet': 940,
    'Glimmora': 941,
    'Flamigo': 944,
    'Cetoddle': 945,
    'Cetitan': 946,
    'Veluza': 947,
    'Dondozo': 948,
    'Tatsugiri': 949,
    'Annihilape': 950,
    'Clodsire': 951,
    'Farigiraf': 952,
    'Kingambit': 954,
    'Great Tusk': 955,
    'Scream Tail': 956,
    'Brute Bonnet': 957,
    'Flutter Mane': 958,
    'Slither Wing': 959,
    'Sandy Shocks': 960,
    'Iron Treads': 961,
    'Iron Bundle': 962,
    'Iron Hands': 963,
    'Iron Jugulis': 964,
    'Iron Moth': 965,
    'Iron Thorns': 966,
    'Frigibax': 967,
    'Arctibax': 968,
    'Baxcalibur': 969,
    'Gimmighoul': 970,
    'Gholdengo': 971,
    'Wo-Chien': 972,
    'Chien-Pao': 973,
    'Ting-Lu': 974,
    'Chi-Yu': 975,
    'Roaring Moon': 976,
    'Iron Valiant': 977,
    'Koraidon': 1007,
    'Miraidon': 1008,
  };

  // Add variant form mappings
  static const Map<String, String> _variantMappings = {
    'minior-red-meteor': 'Minior',
    'mimikyu-disguised': 'Mimikyu',
    'zygarde-50': 'Zygarde',
    'tornadus-incarnate': 'Tornadus',
    'thundurus-incarnate': 'Thundurus',
    'pumpkaboo-average': 'Pumpkaboo',
    'gourgeist-average': 'Gourgeist',
    'eiscue-ice': 'Eiscue',
    'indeedee-male': 'Indeedee',
    'morpeko-full-belly': 'Morpeko',
    'urshifu-single-strike': 'Urshifu',
    'basculegion-male': 'Basculegion',
    'enamorus-incarnate': 'Enamorus',
  };

  // Add additional Pokémon mappings
  static const Map<String, int> _additionalMappings = {
    'Type-Null': 772,
    'Silvally': 773,
    'Minior': 774,
    'Komala': 775,
    'Turtonator': 776,
    'Togedemaru': 777,
    'Mimikyu': 778,
    'Bruxish': 779,
    'Drampa': 780,
    'Dhelmise': 781,
    'Jangmo-o': 782,
    'Hakamo-o': 783,
    'Kommo-o': 784,
    'Tapu Koko': 785,
    'Tapu Lele': 786,
    'Tapu Bulu': 787,
    'Tapu Fini': 788,
    'Cosmog': 789,
    'Cosmoem': 790,
    'Solgaleo': 791,
    'Lunala': 792,
    'Nihilego': 793,
    'Buzzwole': 794,
    'Pheromosa': 795,
    'Xurkitree': 796,
    'Celesteela': 797,
    'Kartana': 798,
    'Guzzlord': 799,
    'Necrozma': 800,
    'Magearna': 801,
    'Marshadow': 802,
    'Poipole': 803,
    'Naganadel': 804,
    'Stakataka': 805,
    'Blacephalon': 806,
    'Zeraora': 807,
    'Meltan': 808,
    'Melmetal': 809,
    // Add more as needed...
  };

  Map<String, int> _nameToNumber = {};
  Map<int, String> _numberToName = {};
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/names.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Fix: Access the "names" object from the JSON
      final namesData = data['names'] as Map<String, dynamic>;
      
      _nameToNumber.clear();
      _numberToName.clear();

      namesData.forEach((key, value) {
        final number = int.tryParse(key);
        if (number != null && value is String) {
          final name = value.toLowerCase();
          _nameToNumber[name] = number;
          _numberToName[number] = name;
        }
      });
      
      _isInitialized = true;
      print('Initialized CollectionIndexService with ${_nameToNumber.length} cards');
    } catch (e) {
      print('Error initializing CollectionIndexService: $e');
      rethrow;
    }
  }

  // Add this method near the start of the class
  String formatCardName(String name) {
    // Handle special cases first
    final specialCases = {
      'mr-mime': 'Mr. Mime',
      'ho-oh': 'Ho-Oh',
      'porygon-z': 'Porygon-Z',
      'mime-jr': 'Mime Jr.',
      'type-null': 'Type: Null',
      'jangmo-o': 'Jangmo-o',
      'hakamo-o': 'Hakamo-o',
      'kommo-o': 'Kommo-o',
      'tapu-koko': 'Tapu Koko',
      'tapu-lele': 'Tapu Lele',
      'tapu-bulu': 'Tapu Bulu',
      'tapu-fini': 'Tapu Fini',
      'nidoran-f': 'Nidoran♀',
      'nidoran-m': 'Nidoran♂',
    };

    // Check for special cases
    if (specialCases.containsKey(name.toLowerCase())) {
      return specialCases[name.toLowerCase()]!;
    }

    // Handle hyphenated names
    if (name.contains('-')) {
      return name.split('-')
          .map((part) => part.substring(0, 1).toUpperCase() + part.substring(1))
          .join('-');
    }

    // Standard capitalization
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  Future<List<String>> loadGenerationNames(int startNum, int endNum) async {
    await _initialize();
    
    List<String> names = [];
    for (int i = startNum; i <= endNum; i++) {
      final name = _numberToName[i];
      if (name != null) {
        names.add(formatCardName(name));  // Apply formatting here
      } else {
        print('Warning: No name found for card #$i');
      }
    }
    
    return names;
  }

  int getIndexNumber(String name) {
    return _nameToNumber[name.toLowerCase()] ?? 0;
  }

  // Add method to get generation info
  static (int, int)? getGenerationBoundaries(int genNumber) {
    return _generationBoundaries[genNumber];
  }
}
